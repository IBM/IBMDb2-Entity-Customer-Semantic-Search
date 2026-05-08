#!/bin/bash
# Copyright 2026 Entity Customer Semantic Search in Db2 LUW Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

# ============================================================================
# Customer Semantic Search - Master Setup Script
# ============================================================================
# This script runs all SQL scripts in the correct order to set up the
# complete customer semantic search system
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="${DB_NAME:-SAMPLE}"
DB_USER="${DB_USER:-db2inst1}"

# Default mode
MODE="all"
START_STEP=1
END_STEP=10
CREATE_DB=false
INTERACTIVE=false
LOCAL_CONNECTION=true
STOP_LLM_SERVERS=true
LLM_SERVERS_STARTED=false
LLM_PROFILES_WORKFLOW=false

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -c, --create-db         Create database before running setup"
    echo "  -i, --interactive       Run in interactive mode (pause after each step)"
    echo "  -R, --remote            Use remote connection (requires user)"
    echo "  -k, --keep-servers      Keep LLM servers running after script exits"
    echo "  -s, --step STEP         Run a specific step (1-15)"
    echo "  -r, --range START-END   Run a range of steps (e.g., 1-5)"
    echo "  -d, --database NAME     Database name (default: SAMPLE)"
    echo "  -u, --user USER         Database user (default: db2inst1, required with -R)"
    echo "  --llm-profiles          Run LLM profiles workflow (steps 11-15) after main workflow"
    echo ""
    echo "Main Workflow Steps (1-10):"
    echo "  1  - Create database schema"
    echo "  2  - Load sample data"
    echo "  3  - Create JSON document table"
    echo "  4  - Generate JSON documents"
    echo "  5  - Create text chunks table"
    echo "  6  - Create text processing UDFs"
    echo "  7  - Generate text chunks"
    echo "  8  - Generate embeddings"
    echo "  9  - Create vector index"
    echo "  10 - Test semantic search (includes optional query plan analysis)"
    echo ""
    echo "LLM Profiles Workflow Steps (11-15):"
    echo "  11 - Create LLM profile table"
    echo "  12 - Generate comprehensive LLM profiles"
    echo "  13 - Chunk LLM profiles"
    echo "  14 - Generate embeddings for LLM chunks"
    echo "  15 - Test LLM semantic search"
    echo ""
    echo "Examples:"
    echo "  $0                          # Run main workflow (steps 1-10)"
    echo "  $0 --llm-profiles           # Run main workflow + LLM profiles workflow"
    echo "  $0 -c                       # Create database and run main workflow"
    echo "  $0 -R -u db2inst1           # Run with remote connection"
    echo "  $0 -i --llm-profiles        # Run both workflows interactively"
    echo "  $0 -s 3                     # Run only step 3"
    echo "  $0 -r 11-15                 # Run only LLM profiles workflow"
    echo "  $0 -r 1-15                  # Run all steps"
    echo "  $0 -k                       # Keep LLM servers running after exit"
    exit 0
}

# Check locale for UTF-8 support (required for special characters)
if [[ "$LC_ALL" != "en_US.UTF-8" && "$LC_ALL" != "en_US.utf8" ]]; then
    echo -e "${YELLOW}WARNING: LC_ALL is not set to en_US.UTF-8${NC}"
    echo -e "${YELLOW}   Current LC_ALL: ${LC_ALL:-<not set>}${NC}"
    echo ""
    echo -e "${YELLOW}   This script uses Unicode characters that may not display correctly.${NC}"
    echo -e "${YELLOW}   To fix this, run:${NC}"
    echo -e "${YELLOW}   export LC_ALL=en_US.UTF-8${NC}"
    echo ""
    read -p "Press Enter to continue anyway, or Ctrl+C to exit and set locale..."
    echo ""
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -c|--create-db)
            CREATE_DB=true
            shift
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -R|--remote)
            LOCAL_CONNECTION=false
            shift
            ;;
        -k|--keep-servers)
            STOP_LLM_SERVERS=false
            shift
            ;;
        --llm-profiles)
            LLM_PROFILES_WORKFLOW=true
            END_STEP=15
            shift
            ;;
        -s|--step)
            MODE="single"
            START_STEP="$2"
            END_STEP="$2"
            shift 2
            ;;
        -r|--range)
            MODE="range"
            IFS='-' read -r START_STEP END_STEP <<< "$2"
            shift 2
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -u|--user)
            DB_USER="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Validate step numbers
if [[ $START_STEP -lt 1 || $START_STEP -gt 15 || $END_STEP -lt 1 || $END_STEP -gt 15 || $START_STEP -gt $END_STEP ]]; then
    echo -e "${RED}Error: Invalid step range. Steps must be between 1-15 and START <= END${NC}"
    exit 1
fi

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Customer Semantic Search - Setup${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo -e "${YELLOW}Database: ${DB_NAME}${NC}"
if [[ "$LOCAL_CONNECTION" == true ]]; then
    echo -e "${YELLOW}Connection: Local${NC}"
else
    echo -e "${YELLOW}Connection: Remote (User: ${DB_USER})${NC}"
fi
echo -e "${YELLOW}Mode: ${MODE}${NC}"
if [[ "$MODE" != "all" ]]; then
    echo -e "${YELLOW}Steps: ${START_STEP}-${END_STEP}${NC}"
fi
if [[ "$CREATE_DB" == true ]]; then
    echo -e "${YELLOW}Create DB: Yes${NC}"
fi
if [[ "$INTERACTIVE" == true ]]; then
    echo -e "${YELLOW}Interactive: Yes${NC}"
fi
echo ""

# Function to create database
create_database() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} Creating database ${DB_NAME}..."

    # Check if database already exists
    if db2 list db directory | grep -q "Database name.*=.*${DB_NAME}"; then
        echo -e "${YELLOW}⚠ Database ${DB_NAME} already exists${NC}"
        read -p "Do you want to drop and recreate it? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            echo -e "${YELLOW}Dropping database ${DB_NAME}...${NC}"
            db2 force applications all
            db2 drop database "$DB_NAME" || true
        else
            echo -e "${YELLOW}Using existing database${NC}"
            echo ""
            return
        fi
    fi

    # Create database
    if db2 create database "$DB_NAME" using codeset UTF-8 territory US; then
        echo -e "${GREEN}✓ Database created successfully${NC}"
        echo ""
    else
        echo -e "${RED}✗ Failed to create database${NC}"
        exit 1
    fi
}

# Function to run SQL script
run_sql() {
    local script=$1
    local description=$2

    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} ${description}..."

    # Run the script and capture output
    db2 -tvf "$script" 2>&1 | tee /tmp/db2_output.log
    local exit_code=${PIPESTATUS[0]}
    
    # Check for license errors in output
    if grep -q "SQL8029N" /tmp/db2_output.log; then
        echo -e "${RED}✗ Failed - License Error${NC}"
        echo ""
        echo -e "${YELLOW}ERROR: SQL8029N - A valid license key cannot be found${NC}"
        echo ""
        echo "This feature requires:"
        echo "  • IBM Db2 with Early Access Program (EAP) features or Db2 12.1.5+"
        echo "  • Valid license for AI functions (CREATE EXTERNAL MODEL, TO_EMBEDDING)"
        echo ""
        echo "To resolve this issue:"
        echo "  1. Check license with: db2licm -l"
        echo "  2. Contact IBM Support for AI license"
        echo ""
        exit 1
    fi
    
    # Check exit code
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ Success${NC}"
        echo ""
    else
        # Check if the script uses UPDATE COMMAND OPTIONS (error handling)
        if grep -q "UPDATE COMMAND OPTIONS USING s OFF" "$script"; then
            # Script has error handling, treat as success if it completed
            echo -e "${GREEN}✓ Success (with handled errors)${NC}"
            echo ""
        else
            echo -e "${RED}✗ Failed${NC}"
            echo -e "${RED}Error running: $script${NC}"
            exit 1
        fi
    fi
}

# Function to run SQL script with custom terminator
run_sql_with_terminator() {
    local script=$1
    local description=$2
    local terminator=$3

    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} ${description}..."

    # Run the script with custom terminator and capture output
    db2 -td"$terminator" -vf "$script" 2>&1 | tee /tmp/db2_output.log
    local exit_code=${PIPESTATUS[0]}
    
    # Check for license errors in output
    if grep -q "SQL8029N" /tmp/db2_output.log; then
        echo -e "${RED}✗ Failed - License Error${NC}"
        echo ""
        echo -e "${YELLOW}ERROR: SQL8029N - A valid license key cannot be found${NC}"
        echo ""
        echo "This feature requires:"
        echo "  • IBM Db2 with Early Access Program (EAP) features or Db2 12.1.5+"
        echo "  • Valid license for AI functions (CREATE EXTERNAL MODEL, TO_EMBEDDING)"
        echo ""
        echo "To resolve this issue:"
        echo "  1. Check license with: db2licm -l"
        echo "  2. Contact IBM Support for AI license"
        echo ""
        exit 1
    fi
    
    # Check exit code
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ Success${NC}"
        echo ""
    else
        # Check if the script uses UPDATE COMMAND OPTIONS (error handling)
        if grep -q "UPDATE COMMAND OPTIONS USING s OFF" "$script"; then
            # Script has error handling, treat as success if it completed
            echo -e "${GREEN}✓ Success (with handled errors)${NC}"
            echo ""
        else
            echo -e "${RED}✗ Failed${NC}"
            echo -e "${RED}Error running: $script${NC}"
            exit 1
        fi
    fi
}

# Function to check if TO_EMBEDDING is available
check_to_embedding_license() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} Checking TO_EMBEDDING license..."
    
    # Try to use TO_EMBEDDING with a simple test
    # Suppress output and check for license error
    if db2 "SELECT TO_EMBEDDING('test' USING GRANITE30) FROM SYSIBM.SYSDUMMY1" 2>&1 | grep -q "SQL8029N"; then
        echo -e "${RED}✗ TO_EMBEDDING function is not available${NC}"
        echo ""
        echo -e "${YELLOW}ERROR: SQL8029N - A valid license key cannot be found${NC}"
        echo ""
        echo "This feature requires:"
        echo "  • IBM Db2 with Early Access Program (EAP) features or Db2 12.1.5+"
        echo "  • Valid license for AI functions (CREATE EXTERNAL MODEL, TO_EMBEDDING)"
        echo ""
        echo "To resolve this issue:"
        echo "  1. Check license with: db2licm -l"
        echo "  2. Contact IBM Support for AI license"
        echo ""
        return 1
    elif db2 "SELECT TO_EMBEDDING('test' USING GRANITE30) FROM SYSIBM.SYSDUMMY1" 2>&1 | grep -q "SQL0204N"; then
        echo -e "${YELLOW}⚠ GRANITE30 model not found${NC}"
        echo ""
        echo "The external model 'GRANITE30' has not been created yet."
        echo ""
        return 0
    else
        echo -e "${GREEN}✓ TO_EMBEDDING function is available${NC}"
        echo ""
        return 0
    fi
}

# Function to pause in interactive mode
pause_if_interactive() {
    if [[ "$INTERACTIVE" == true ]]; then
        echo -e "${YELLOW}Press Enter to continue to next step, or Ctrl+C to exit...${NC}"
        read
        echo ""
    fi
}

# Function to check if LLM models and binary exist
check_llm_prerequisites() {
    local all_good=true
    
    # Check if llama-server binary exists
    if [ ! -f "local_llm/bin/llama-server" ]; then
        echo -e "${RED}✗ Error: llama-server not found at local_llm/bin/llama-server${NC}"
        echo -e "${YELLOW}Please follow the setup instructions in local_llm/README.md to:${NC}"
        echo -e "${YELLOW}  1. Download the required models${NC}"
        echo -e "${YELLOW}  2. Build or download llama-server binary${NC}"
        echo -e "${YELLOW}  3. Place the binary in local_llm/bin/${NC}"
        echo ""
        all_good=false
    fi
    
    # Check if models exist
    if [ ! -f "local_llm/models/granite-embedding-30m-english-Q6_K.gguf" ]; then
        echo -e "${RED}✗ Error: Embedding model not found${NC}"
        echo -e "${YELLOW}Please download: local_llm/models/granite-embedding-30m-english-Q6_K.gguf${NC}"
        echo -e "${YELLOW}See local_llm/README.md for download instructions${NC}"
        echo ""
        all_good=false
    fi
    
    if [ ! -f "local_llm/models/qwen2.5-3b-instruct-q4_k_m.gguf" ]; then
        echo -e "${RED}✗ Error: Text generation model not found${NC}"
        echo -e "${YELLOW}Please download: local_llm/models/qwen2.5-3b-instruct-q4_k_m.gguf${NC}"
        echo -e "${YELLOW}See local_llm/README.md for download instructions${NC}"
        echo ""
        all_good=false
    fi
    
    if [ "$all_good" = false ]; then
        return 1
    fi
    return 0
}

# Function to start LLM servers
start_llm_servers() {
    echo -e "${YELLOW}============================================================================${NC}"
    echo -e "${YELLOW}Starting LLM Servers${NC}"
    echo -e "${YELLOW}============================================================================${NC}"
    echo ""
    
    # Check prerequisites first
    if ! check_llm_prerequisites; then
        return 1
    fi
    
    # Check if embedding server is running on port 8080
    EMBEDDING_RUNNING=false
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        EMBEDDING_RUNNING=true
        echo -e "${GREEN}✓ Embedding server is already running on port 8080${NC}"
    else
        echo -e "${YELLOW}⚠ Embedding server not running on port 8080${NC}"
        echo -e "${BLUE}Starting embedding server...${NC}"
        
        # Start embedding server in background and detach from parent process
        nohup local_llm/bin/llama-server \
            -m local_llm/models/granite-embedding-30m-english-Q6_K.gguf \
            --embedding \
            --pooling cls \
            -ub 8192 \
            --port 8080 \
            --host 0.0.0.0 \
            >llama-server_granite-embedding-30m.out 2>&1 &
        
        EMBEDDING_PID=$!
        disown $EMBEDDING_PID
        LLM_SERVERS_STARTED=true
        echo -e "${BLUE}Embedding server started (PID: $EMBEDDING_PID)${NC}"
        echo -e "${BLUE}Waiting for server to be ready...${NC}"
        
        # Wait for server to be ready (max 30 seconds)
        for i in {1..30}; do
            if curl -s http://localhost:8080/health > /dev/null 2>&1; then
                echo -e "${GREEN}✓ Embedding server is ready${NC}"
                EMBEDDING_RUNNING=true
                break
            fi
            sleep 1
            echo -n "."
        done
        echo ""
        
        if [ "$EMBEDDING_RUNNING" = false ]; then
            echo -e "${RED}✗ Failed to start embedding server${NC}"
            echo -e "${YELLOW}Check logs: llama-server_granite-embedding-30m.out${NC}"
            return 1
        fi
    fi
    
    # Check if text generation server is running on port 8081
    TEXT_GEN_RUNNING=false
    if curl -s http://localhost:8081/health > /dev/null 2>&1; then
        TEXT_GEN_RUNNING=true
        echo -e "${GREEN}✓ Text generation server is already running on port 8081${NC}"
    else
        echo -e "${YELLOW}⚠ Text generation server not running on port 8081${NC}"
        echo -e "${BLUE}Starting text generation server...${NC}"
        
        # Start text generation server in background and detach from parent process
        nohup local_llm/bin/llama-server \
            -m local_llm/models/qwen2.5-3b-instruct-q4_k_m.gguf \
            -c 4096 \
            --port 8081 \
            --host 0.0.0.0 \
            >llama-server_qwen2.5-3b.out 2>&1 &
        
        TEXT_GEN_PID=$!
        disown $TEXT_GEN_PID
        LLM_SERVERS_STARTED=true
        echo -e "${BLUE}Text generation server started (PID: $TEXT_GEN_PID)${NC}"
        echo -e "${BLUE}Waiting for server to be ready...${NC}"
        
        # Wait for server to be ready (max 30 seconds)
        for i in {1..30}; do
            if curl -s http://localhost:8081/health > /dev/null 2>&1; then
                echo -e "${GREEN}✓ Text generation server is ready${NC}"
                TEXT_GEN_RUNNING=true
                break
            fi
            sleep 1
            echo -n "."
        done
        echo ""
        
        if [ "$TEXT_GEN_RUNNING" = false ]; then
            echo -e "${RED}✗ Failed to start text generation server${NC}"
            echo -e "${YELLOW}Check logs: llama-server_qwen2.5-3b.out${NC}"
            return 1
        fi
    fi
    
    echo ""
    echo -e "${GREEN}✓ Both LLM servers are running and ready${NC}"
    echo -e "${YELLOW}  - Embedding server: http://localhost:8080${NC}"
    echo -e "${YELLOW}  - Text generation server: http://localhost:8081${NC}"
    echo ""
    
    return 0
}

# Function to stop LLM servers
stop_llm_servers() {
    echo -e "${YELLOW}============================================================================${NC}"
    echo -e "${YELLOW}Stopping LLM Servers${NC}"
    echo -e "${YELLOW}============================================================================${NC}"
    echo ""
    
    # Find and stop llama-server processes
    LLAMA_PIDS=$(pgrep -f "llama-server.*granite-embedding\|llama-server.*qwen2.5")
    
    if [ -n "$LLAMA_PIDS" ]; then
        echo -e "${BLUE}Stopping LLM servers...${NC}"
        for pid in $LLAMA_PIDS; do
            if kill $pid 2>/dev/null; then
                echo -e "${GREEN}✓ Stopped server (PID: $pid)${NC}"
            fi
        done
        
        # Wait a moment for graceful shutdown
        sleep 2
        
        # Force kill if still running
        REMAINING_PIDS=$(pgrep -f "llama-server.*granite-embedding\|llama-server.*qwen2.5")
        if [ -n "$REMAINING_PIDS" ]; then
            echo -e "${YELLOW}Force stopping remaining servers...${NC}"
            for pid in $REMAINING_PIDS; do
                kill -9 $pid 2>/dev/null && echo -e "${GREEN}✓ Force stopped server (PID: $pid)${NC}"
            done
        fi
        
        echo -e "${GREEN}✓ All LLM servers stopped${NC}"
    else
        echo -e "${YELLOW}⚠ No LLM servers found to stop${NC}"
    fi
    echo ""
}

# Function to create explain tables
create_explain_tables() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} Creating explain tables in instance schema..."
    
    # Create explain tables in the instance owner's schema (typically DB2INST1 or current user)
    db2 "CALL SYSPROC.SYSINSTALLOBJECTS('EXPLAIN', 'C', '', CURRENT USER)" 2>&1 | tee /tmp/db2_explain_setup.log
    
    if grep -q "SQL0601N" /tmp/db2_explain_setup.log; then
        echo -e "${YELLOW}⚠ Explain tables already exist in instance schema${NC}"
    elif grep -q "Return Status = 0" /tmp/db2_explain_setup.log; then
        echo -e "${GREEN}✓ Explain tables created in instance schema${NC}"
    else
        echo -e "${RED}✗ Failed to create explain tables${NC}"
        return 1
    fi
    echo ""
    return 0
}

# Function to run explain and show query plan
run_explain_query() {
    local script=$1
    local description=$2
    
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} ${description}..."
    
    # Ensure explain tables exist
    create_explain_tables
    
    # Run the explain query
    echo -e "${BLUE}Running query with explain mode...${NC}"
    db2 -tvf "$script" 2>&1 | tee /tmp/db2_explain_query.log
    local exit_code=${PIPESTATUS[0]}
    
    # SQL0217W is expected when running in explain mode (query explained but not executed)
    # Treat it as success
    if grep -q "SQL0217W" /tmp/db2_explain_query.log; then
        echo -e "${GREEN}✓ Explain query completed (SQL0217W is expected in explain mode)${NC}"
    elif [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ Explain query completed${NC}"
    else
        echo -e "${RED}✗ Failed to run explain query${NC}"
        return 1
    fi
    echo ""
    
    # Generate and display the query plan
    echo -e "${BLUE}Generating query plan with db2exfmt...${NC}"
    db2exfmt -d "$DB_NAME" -1 -o /tmp/plan.txt 2>&1 | tee /tmp/db2exfmt.log
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo -e "${RED}✗ Failed to generate query plan${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Query plan generated${NC}"
    echo ""
    
    # Display the access plan section
    echo -e "${YELLOW}============================================================================${NC}"
    echo -e "${YELLOW}Access Plan:${NC}"
    echo -e "${YELLOW}============================================================================${NC}"
    
    # Extract and display the Access Plan section
    if [ -f /tmp/plan.txt ]; then
        # Display from "Access Plan:" through the tree diagram (stops at operator details)
        sed -n '/^Access Plan:/,/^[[:space:]]*[0-9]*) /p' /tmp/plan.txt | head -n -1
        echo ""
        
        # Extract and display vector index information
        echo -e "${YELLOW}============================================================================${NC}"
        echo -e "${YELLOW}Vector Index Details:${NC}"
        echo -e "${YELLOW}============================================================================${NC}"
        
        # Find the vector index section
        if grep -q "VECIDX:" /tmp/plan.txt; then
            # Display the IXSCAN operator details and index metadata
            sed -n '/5) IXSCAN:/,/Null keys:/p' /tmp/plan.txt
        else
            echo -e "${YELLOW}No vector index information found in plan${NC}"
        fi
    else
        echo -e "${RED}✗ Plan file not found${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${GREEN}✓ Query plan displayed${NC}"
    echo ""
    
    return 0
}

# Function to run a specific step
run_step() {
    local step=$1

    case $step in
        1)
            run_sql "sql/01_create_schema.sql" "Step 1/10: Creating database schema"
            pause_if_interactive
            ;;
        2)
            # Generate data files if they don't exist
            if [ ! -d "data" ] || [ -z "$(ls -A data 2>/dev/null)" ]; then
                echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} Generating sample data files..."
                if python3 scripts/generate_sample_data.py; then
                    echo -e "${GREEN}✓ Data files generated${NC}"
                    echo ""
                else
                    echo -e "${RED}✗ Failed to generate data files${NC}"
                    echo -e "${YELLOW}Make sure Python 3 is installed${NC}"
                    exit 1
                fi
            else
                echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} Using existing data files..."
            fi
            run_sql "sql/02_load_sample_data.sql" "Step 2/10: Loading sample data"
            pause_if_interactive
            ;;
        3)
            run_sql "sql/03_create_json_table.sql" "Step 3/10: Creating JSON document table"
            pause_if_interactive
            ;;
        4)
            run_sql "sql/04_generate_json.sql" "Step 4/10: Generating JSON documents"
            pause_if_interactive
            ;;
        5)
            run_sql "sql/05_create_chunk_table.sql" "Step 5/10: Creating text chunks table"
            pause_if_interactive
            ;;
        6)
            run_sql_with_terminator "sql/06_text_chunking_udfs.sql" "Step 6/10: Creating text processing UDFs" "@"
            pause_if_interactive
            ;;
        7)
            run_sql "sql/07_generate_chunks.sql" "Step 7/10: Generating text chunks"
            pause_if_interactive
            ;;
        8)
            echo -e "${YELLOW}============================================================================${NC}"
            echo -e "${YELLOW}IMPORTANT: Workshop requires TO_EMBEDDING license and LLM servers${NC}"
            echo -e "${YELLOW}============================================================================${NC}"
            echo ""
            
            # Check TO_EMBEDDING license (GRANITE30 model will be created in this step)
            if ! check_to_embedding_license; then
                echo -e "${RED}Cannot proceed with Step 8 without TO_EMBEDDING license${NC}"
                echo -e "${YELLOW}You can still run steps 1-7 to set up the data pipeline${NC}"
                exit 1
            fi
            
            # Start LLM servers if needed
            if ! start_llm_servers; then
                echo -e "${RED}Failed to start LLM servers${NC}"
                exit 1
            fi
            
            if [[ "$INTERACTIVE" == true ]]; then
                read -p "Press Enter to continue with embedding generation, or Ctrl+C to exit..."
                echo ""
            fi
            
            run_sql "sql/08_generate_embeddings.sql" "Step 8/10: Generating embeddings (this may take a while)"
            pause_if_interactive
            ;;
        9)
            run_sql "sql/09_create_vector_index.sql" "Step 9/10: Creating vector index"
            pause_if_interactive
            ;;
        10)
            echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} Step 10/10: Testing semantic search..."
            echo -e "${YELLOW}Note: Semantic search queries require the embedding model name${NC}"
            echo -e "${YELLOW}Running 5 different semantic search examples${NC}"
            echo ""
            read -p "Press Enter to run semantic search examples, or Ctrl+C to skip..."
            echo ""
            
            echo -e "${YELLOW}============================================================================${NC}"
            echo -e "${YELLOW}Example 10.1: Basic Semantic Search${NC}"
            echo -e "${YELLOW}QUERY: 'Customer who purchases electronics and technology products'${NC}"
            echo -e "${YELLOW}============================================================================${NC}"
            run_sql "sql/10.1_basic_semantic_search.sql" "Step 10.1: Basic semantic search"
            pause_if_interactive
            
            echo -e "${YELLOW}============================================================================${NC}"
            echo -e "${YELLOW}Example 10.2: Approximate Search with Vector Index${NC}"
            echo -e "${YELLOW}QUERY: 'Customer who purchases electronics and technology products'${NC}"
            echo -e "${YELLOW}Uses FETCH APPROX for faster search on large datasets${NC}"
            echo -e "${YELLOW}============================================================================${NC}"
            run_sql "sql/10.2_approx_search_with_index.sql" "Step 10.2: Approximate search with index"
            pause_if_interactive
            
            echo -e "${YELLOW}============================================================================${NC}"
            echo -e "${YELLOW}Example 10.2a: Query Plan Analysis (Optional)${NC}"
            echo -e "${YELLOW}Shows the execution plan for approximate vector search${NC}"
            echo -e "${YELLOW}============================================================================${NC}"
            echo ""
            read -p "Do you want to see the query plan analysis? (y/n): " show_plan
            if [[ "$show_plan" == "y" || "$show_plan" == "Y" ]]; then
                run_explain_query "sql/10.2_approx_search_with_index_explain.sql" "Step 10.2a: Query plan analysis"
            else
                echo -e "${YELLOW}Skipping query plan analysis${NC}"
                echo ""
            fi
            pause_if_interactive
            
            echo -e "${YELLOW}============================================================================${NC}"
            echo -e "${YELLOW}Example 10.3: Find Similar Customers${NC}"
            echo -e "${YELLOW}QUERY: Find customers with similar profiles to customer SK=1${NC}"
            echo -e "${YELLOW}============================================================================${NC}"
            run_sql "sql/10.3_find_similar_customers.sql" "Step 10.3: Find similar customers"
            pause_if_interactive
            
            echo -e "${YELLOW}============================================================================${NC}"
            echo -e "${YELLOW}Example 10.4: Semantic Search with Geographic Filters${NC}"
            echo -e "${YELLOW}QUERY: 'Customer interested in fitness, health, and wellness products'${NC}"
            echo -e "${YELLOW}FILTER: Only customers in IL, WI, IN (Midwest states)${NC}"
            echo -e "${YELLOW}============================================================================${NC}"
            run_sql "sql/10.4_semantic_search_with_filters.sql" "Step 10.4: Semantic search with filters"
            pause_if_interactive
            
            echo -e "${YELLOW}============================================================================${NC}"
            echo -e "${YELLOW}Example 10.5: Multi-Aspect Customer Search${NC}"
            echo -e "${YELLOW}QUERY: 'Customer who returns items frequently and shops at multiple stores'${NC}"
            echo -e "${YELLOW}Shows customers matching on 2+ aspects (items, stores, spending)${NC}"
            echo -e "${YELLOW}============================================================================${NC}"
            run_sql "sql/10.5_multi_aspect_search.sql" "Step 10.5: Multi-aspect search"
            pause_if_interactive
            ;;
        11)
            echo -e "${BLUE}============================================================================${NC}"
            echo -e "${BLUE}Step 11: Create LLM Profile Table${NC}"
            echo -e "${BLUE}============================================================================${NC}"
            run_sql "sql/11_create_llm_profile_table.sql" "Step 11: Create LLM profile table"
            pause_if_interactive
            ;;
        12)
            echo -e "${BLUE}============================================================================${NC}"
            echo -e "${BLUE}Step 12: Generate Comprehensive LLM Profiles${NC}"
            echo -e "${BLUE}============================================================================${NC}"
            echo -e "${YELLOW}This step uses TEXT_GENERATION to create detailed customer profiles${NC}"
            echo -e "${YELLOW}Each profile is up to 1000 words and will be chunked in the next step${NC}"
            run_sql "sql/12_generate_llm_profiles.sql" "Step 12: Generate LLM profiles"
            pause_if_interactive
            ;;
        13)
            echo -e "${BLUE}============================================================================${NC}"
            echo -e "${BLUE}Step 13: Chunk LLM Profiles${NC}"
            echo -e "${BLUE}============================================================================${NC}"
            echo -e "${YELLOW}This step chunks long profiles into ~500 character segments${NC}"
            echo -e "${YELLOW}Uses CHUNK_TEXT UDF with ASCII cleaning to prevent UTF-8 errors${NC}"
            run_sql_with_terminator "sql/13_chunk_llm_profiles.sql" "Step 13: Chunk LLM profiles" "@"
            pause_if_interactive
            ;;
        14)
            echo -e "${BLUE}============================================================================${NC}"
            echo -e "${BLUE}Step 14: Generate Embeddings for LLM Chunks${NC}"
            echo -e "${BLUE}============================================================================${NC}"
            echo -e "${YELLOW}This step generates vector embeddings for LLM chunks${NC}"
            echo -e "${YELLOW}Uses the same GRANITE30 model as the main workflow${NC}"
            run_sql "sql/14_generate_llm_embeddings.sql" "Step 14: Generate LLM embeddings"
            pause_if_interactive
            ;;
        15)
            echo -e "${BLUE}============================================================================${NC}"
            echo -e "${BLUE}Step 15: Test LLM Semantic Search${NC}"
            echo -e "${BLUE}============================================================================${NC}"
            echo -e "${YELLOW}This step demonstrates semantic search on LLM-generated profiles${NC}"
            echo -e "${YELLOW}Compares results with regular chunk-based search${NC}"
            run_sql "sql/15.1_llm_semantic_search.sql" "Step 15: LLM semantic search"
            pause_if_interactive
            ;;
        *)
            echo -e "${RED}Invalid step: $step${NC}"
            exit 1
            ;;
    esac
}

# Create database if requested
if [[ "$CREATE_DB" == true ]]; then
    create_database
fi

# Connect to database
echo -e "${BLUE}Connecting to database...${NC}"
if [[ "$LOCAL_CONNECTION" == true ]]; then
    db2 connect to "$DB_NAME"
else
    db2 "connect to $DB_NAME user $DB_USER"
fi
echo ""

# Check if steps 8-10 are in the range - validate LLM prerequisites early
if [[ $END_STEP -ge 8 ]]; then
    echo -e "${YELLOW}============================================================================${NC}"
    echo -e "${YELLOW}IMPORTANT: Steps after 8 require local LLM servers${NC}"
    echo -e "${YELLOW}============================================================================${NC}"
    echo ""
    
    # Only check if LLM prerequisites exist (models and binary)
    # Don't check TO_EMBEDDING license yet as GRANITE30 model is created in step 8
    if ! check_llm_prerequisites; then
        echo -e "${RED}Cannot proceed with steps 8-10 without LLM prerequisites${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ LLM prerequisites validated${NC}"
    echo -e "${YELLOW}Note: TO_EMBEDDING license and servers will be checked/started at step 8${NC}"
    echo ""
fi

# Run steps based on mode
for ((step=START_STEP; step<=END_STEP; step++)); do
    run_step $step
done

# Disconnect
echo -e "${BLUE}Disconnecting from database...${NC}"
db2 "DISCONNECT $DB_NAME"
echo ""

# Stop LLM servers if they were started by this script
if [[ "$LLM_SERVERS_STARTED" == true && "$STOP_LLM_SERVERS" == true ]]; then
    stop_llm_servers
elif [[ "$LLM_SERVERS_STARTED" == true && "$STOP_LLM_SERVERS" == false ]]; then
    echo -e "${YELLOW}============================================================================${NC}"
    echo -e "${YELLOW}LLM Servers Still Running${NC}"
    echo -e "${YELLOW}============================================================================${NC}"
    echo ""
    echo -e "${YELLOW}The following LLM servers are still running:${NC}"
    echo -e "${YELLOW}  - Embedding server: http://localhost:8080${NC}"
    echo -e "${YELLOW}  - Text generation server: http://localhost:8081${NC}"
    echo ""
    echo -e "${YELLOW}To stop them manually, run:${NC}"
    echo -e "${YELLOW}  pkill -f llama-server${NC}"
    echo ""
    echo -e "${YELLOW}Or check their PIDs:${NC}"
    echo -e "${YELLOW}  ps aux | grep llama-server${NC}"
    echo ""
fi

# Summary
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""

# Show completed steps
for ((step=START_STEP; step<=END_STEP; step++)); do
    case $step in
        1) echo -e "${GREEN}✓ Database schema created${NC}" ;;
        2) echo -e "${GREEN}✓ Sample data loaded${NC}" ;;
        3) echo -e "${GREEN}✓ JSON document table created${NC}" ;;
        4) echo -e "${GREEN}✓ JSON documents generated${NC}" ;;
        5) echo -e "${GREEN}✓ Text chunks table created${NC}" ;;
        6) echo -e "${GREEN}✓ Text processing UDFs created${NC}" ;;
        7) echo -e "${GREEN}✓ Text chunks generated${NC}" ;;
        8) echo -e "${GREEN}✓ Embeddings generated${NC}" ;;
        9) echo -e "${GREEN}✓ Vector index created${NC}" ;;
        10) echo -e "${GREEN}✓ Semantic search tested${NC}" ;;
        11) echo -e "${GREEN}✓ LLM profile table created${NC}" ;;
        12) echo -e "${GREEN}✓ LLM profiles generated${NC}" ;;
        13) echo -e "${GREEN}✓ LLM profiles chunked${NC}" ;;
        14) echo -e "${GREEN}✓ LLM embeddings generated${NC}" ;;
        15) echo -e "${GREEN}✓ LLM semantic search tested${NC}" ;;
    esac
done

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Review the generated data:"
echo "   db2 -tvf examples/sample_queries.sql"
echo ""
echo "2. Try custom semantic searches:"
echo "   Edit sql/10_semantic_search.sql with your queries"
echo ""
if [[ $END_STEP -ge 11 ]]; then
echo "3. Compare LLM vs regular chunk search:"
echo "   Review sql/15.1_llm_semantic_search.sql results"
echo ""
fi
echo "4. Read the documentation:"
echo "   - docs/architecture.md - System architecture"
echo "   - docs/setup_guide.md - Detailed setup guide"
echo "   - docs/query_examples.md - Query examples and use cases"
echo ""
echo "5. Run specific workflows:"
echo "   ./run_all.sh                     # Main workflow (steps 1-10)"
echo "   ./run_all.sh --llm-profiles      # Main + LLM profiles workflow"
echo "   ./run_all.sh -r 11-15            # Only LLM profiles workflow"
echo "   ./run_all.sh -s <step_number>    # Run a single step"
echo "   ./run_all.sh -i                  # Run interactively"
echo ""
echo -e "${GREEN}Happy searching! 🔍${NC}"

# Made with Bob
