# Testing Guide for Entity Customer Semantic Search

## Quick Start Testing

The `run_all.sh` script now supports progressive testing with multiple options.

## Usage

```bash
./run_all.sh [OPTIONS]
```

## Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-c, --create-db` | Create database before running setup |
| `-i, --interactive` | Run in interactive mode (pause after each step) |
| `-l, --local` | Use local connection (no user required) |
| `-s, --step STEP` | Run a specific step (1-10) |
| `-r, --range START-END` | Run a range of steps (e.g., 1-5) |
| `-d, --database NAME` | Database name (default: SAMPLE) |
| `-u, --user USER` | Database user (default: db2inst1, ignored with -l) |

## Steps Overview

1. Create database schema
2. Load sample data
3. Create JSON document table
4. Generate JSON documents
5. Create text chunks table
6. Create text processing UDFs
7. Generate text chunks
8. Generate embeddings (requires external model)
9. Create vector index
10. Test semantic search

## Testing Scenarios

### 1. Full Setup (All Steps)
```bash
./run_all.sh
```

### 2. Local Connection (No User Required)
```bash
./run_all.sh -l
```
Perfect for local development where you're already authenticated.

### 3. Create Database and Run All Steps
```bash
./run_all.sh -c
```

### 4. Create Database with Local Connection
```bash
./run_all.sh -c -l
```

### 5. Interactive Mode (Pause After Each Step)
```bash
./run_all.sh -i
```
This is great for learning and debugging - you can inspect results after each step.

### 6. Run a Single Step
```bash
# Run only step 3 (Create JSON table)
./run_all.sh -s 3
```

### 7. Run a Range of Steps
```bash
# Run steps 1 through 5
./run_all.sh -r 1-5
```

### 8. Progressive Testing Workflow

**Phase 1: Setup Schema and Data (Local Connection)**
```bash
./run_all.sh -c -l -r 1-2
```

**Phase 2: JSON Processing**
```bash
./run_all.sh -l -r 3-4
```

**Phase 3: Text Chunking**
```bash
./run_all.sh -l -r 5-7
```

**Phase 4: Embeddings and Search (requires model setup)**
```bash
./run_all.sh -i -l -r 8-10
```

### 9. Test Specific Components

**Test only schema creation:**
```bash
./run_all.sh -l -s 1
```

**Test only embeddings (after previous steps completed):**
```bash
./run_all.sh -l -s 8
```

**Test only semantic search:**
```bash
./run_all.sh -l -s 10
```

### 10. Custom Database

**With user authentication:**
```bash
./run_all.sh -c -d TESTDB -u myuser
```

**With local connection:**
```bash
./run_all.sh -c -l -d TESTDB
```

## Recommended Testing Approach

### For First-Time Setup (Local Development):
1. **Create DB and test schema/data:**
   ```bash
   ./run_all.sh -c -l -i -r 1-2
   ```

2. **Test JSON generation:**
   ```bash
   ./run_all.sh -l -i -r 3-4
   ```

3. **Test text chunking:**
   ```bash
   ./run_all.sh -l -i -r 5-7
   ```

4. **Configure embedding model, then test:**
   ```bash
   ./run_all.sh -l -i -r 8-10
   ```

### For Remote/Production Setup:
1. **Create DB with user authentication:**
   ```bash
   ./run_all.sh -c -d PRODDB -u produser -i -r 1-2
   ```

2. **Continue with remaining steps:**
   ```bash
   ./run_all.sh -d PRODDB -u produser -r 3-10
   ```

### For Development/Debugging:
- Use `-l` for local connections (faster, no password prompts)
- Use `-i` (interactive) to pause and inspect after each step
- Use `-s` to re-run specific steps after fixes
- Use `-r` to test specific subsystems

### For CI/CD:
```bash
./run_all.sh -c -u ciuser  # Full automated setup with specific user
```

### For Local Development:
```bash
./run_all.sh -c -l  # Quick local setup, no user needed
```

## Troubleshooting

### If a step fails:
1. Check the error message
2. Fix the issue in the corresponding SQL file
3. Re-run just that step: `./run_all.sh -s <step_number>`

### To start fresh:
```bash
./run_all.sh -c  # Will prompt to drop existing database
```

### To skip embedding generation temporarily:
```bash
./run_all.sh -r 1-7  # Stop before embeddings
```

## Verification Commands

After running steps, verify with:

```bash
# Connect to database
db2 connect to SAMPLE

# Check tables
db2 "SELECT tabname FROM syscat.tables WHERE tabschema = CURRENT SCHEMA"

# Check row counts
db2 "SELECT COUNT(*) FROM customers"
db2 "SELECT COUNT(*) FROM customer_json_docs"
db2 "SELECT COUNT(*) FROM customer_text_chunks"

# View sample data
db2 "SELECT * FROM customers FETCH FIRST 5 ROWS ONLY"
```

## Environment Variables

You can also set environment variables instead of using flags:

```bash
export DB_NAME=TESTDB
export DB_USER=myuser
./run_all.sh
```

## Tips

- Always use `-i` when learning or debugging
- Use `-r` to test subsystems independently
- Use `-s` to re-run failed steps after fixes
- Use `-c` carefully - it will drop existing databases!
- Check `examples/sample_queries.sql` for verification queries

## Next Steps

After successful setup, see:
- `docs/query_examples.md` - Example queries
- `docs/architecture.md` - System architecture
- `examples/sample_queries.sql` - Sample verification queries