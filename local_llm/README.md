# Local LLM Setup

## Overview

This directory contains the setup and configuration for running local Large Language Models (LLMs) that are **required as a prerequisite** for the entity-customer semantic search sample application.

The application uses two local LLMs:
- **Embedding Model**: Converts text into vector embeddings for semantic search
- **Text Generation Model**: Generates natural language responses and summaries

These models run entirely on your local machine using CPU-only inference via llama.cpp, eliminating the need for external API calls or GPU hardware.

> **Important**: You must complete the setup in this directory before running the main sample application. The application depends on these local LLM services to function properly.

---


## Prerequisites

- ~4GB disk space for models
- 8GB+ RAM (32+ cores recommended for best performance)
- CPU-only (no GPU required)

## Download the models we will use

Using terminal or command prompt, navigate to the folder where you want to download the models:

e.g.,
```bash
cd local_llm/models
```

### Embedding Model: Granite Embedding 30M English (30M parameters, ~32MB)

**IBM Granite Embedding 30M** is a lightweight, efficient embedding model specifically designed for English text. This model converts text into dense vector representations (embeddings) that capture semantic meaning, enabling similarity search and retrieval operations.

**Key Features:**
- **Compact Size**: Only 30 million parameters (~32MB), making it fast and resource-efficient
- **Quantization**: Q6_K quantization provides an excellent balance between model size and accuracy
- **Purpose**: Optimized for semantic search, text similarity, and retrieval-augmented generation (RAG) applications
- **Performance**: Suitable for CPU-only inference with minimal memory footprint

```bash
wget -O granite-embedding-30m-english-Q6_K.gguf \
  https://huggingface.co/lmstudio-community/granite-embedding-30m-english-GGUF/resolve/main/granite-embedding-30m-english-Q6_K.gguf
```

### LLM Model: Qwen2.5 3B Instruct (3B parameters, ~2GB)

**Qwen2.5 3B Instruct** is a state-of-the-art instruction-tuned language model from Alibaba Cloud's Qwen family. This model excels at following instructions, generating coherent text, and performing various natural language understanding tasks.

**Key Features:**
- **Instruction-Tuned**: Specifically trained to follow user instructions and generate helpful responses
- **Balanced Performance**: 3 billion parameters provide strong capabilities while remaining efficient for CPU inference
- **Quantization**: Q4_K_M (4-bit) quantization reduces model size to ~2GB while maintaining quality
- **Multilingual**: Supports multiple languages with strong English performance
- **Use Cases**: Text generation, summarization, question answering, and conversational AI

```bash
wget -O qwen2.5-3b-instruct-q4_k_m.gguf \
  https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf
```
## Quick start with a local LLM using llama.cpp

Getting started with llama.cpp is straightforward. Here are several ways to install it on your machine:

- Install `llama.cpp` using [brew, nix or winget using the llama.cpp instructions](https://github.com/ggml-org/llama.cpp/blob/master/docs/install.md)
- Run with Docker - see our [Docker documentation from llama.cpp](https://github.com/ggml-org/llama.cpp/blob/master/docs/docker.md)
- Download pre-built binaries from the [releases page in llama.cpp](https://github.com/ggml-org/llama.cpp/releases)
- Build from source by cloning this repository - check out [llama.cpp build guide](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md) or use the quick instructions below for RHEL 9+


### Setup Instructions for compiling the binary for llama-server in RHEL

#### 0. Start in the project root directory

```bash
cd entity-customer-semantic-search
```


#### 1. Install Development Tools

```bash
sudo dnf groupinstall "Development Tools"
```


#### 2. Enable CodeReady Builder Repository (RHEL 9)

```bash
sudo subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms
```


#### 3. Refresh DNF Cache

```bash
sudo dnf clean all
sudo dnf makecache
```

#### 4. Install Required Packages

```bash
sudo dnf install cmake git openblas-devel
```

#### 5. Clone `llama-cpp`

```bash
git clone https://github.com/ggml-org/llama.cpp llama-cpp
cd llama-cpp
```

#### 6. Build the Project

```bash
cmake -B build
cmake --build build --config Release
```

**Note:**
The binaries will be under `build/bin`. We are going to just use the `llama-server` and the .so libraries.

#### 7. Copy the llama-server binaries to the bin directory

```bash
cd ..
cp llama-cpp/build/bin/llama-server local_llm/bin
cp llama-cpp/build/bin/lib* local_llm/bin
```

#### 8. Add llama-server binaries to the LD_LIBARY_PATH

```bash
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/local_llm/bin
```

## Running the Local LLM Servers

Once you have downloaded the models and set up llama.cpp, you need to start two separate LLM servers - one for embeddings and one for text generation. Both servers must be running for the sample application to work properly.

### 1. Start the Embedding Model Server

The embedding server converts text into vector representations for semantic search.

```bash
bin/llama-server \
  -m models/granite-embedding-30m-english-Q6_K.gguf \
  --embedding \
  --pooling cls \
  -ub 8192 \
  --port 8080 \
  --host 0.0.0.0 \
  >llama-server_granite-embedding-30m.out 2>&1 &
```

**Command Parameters Explained:**
- `-m`: Path to the model file
- `--embedding`: Enable embedding mode (outputs vectors instead of text)
- `--pooling cls`: Use CLS (Classification) pooling to generate a single vector representation from the [CLS] token
- `-ub 8192`: Set physical maximum batch size to 8192 (expands compute buffer for better throughput)
- `--port 8080`: Server listens on port 8080
- `--host 0.0.0.0`: Accept connections from any network interface
- `>llama-server_granite-embedding-30m.out 2>&1 &`: Run in background and redirect output to log file

**Verify the server is running:**
```bash
curl http://localhost:8080/health
```

### 2. Start the Text Generation Model Server

The text generation server produces natural language responses and summaries.

```bash
bin/llama-server \
  -m models/qwen2.5-3b-instruct-q4_k_m.gguf \
  -c 4096 \
  --port 8081 \
  --host 0.0.0.0 \
  >llama-server_qwen2.5-3b.out 2>&1 &
```

**Command Parameters Explained:**
- `-m`: Path to the model file
- `-c 4096`: Set context size to 4096 tokens (maximum tokens the model can process at once, including prompt and response)
- `--port 8081`: Server listens on port 8081 (different from embedding server)
- `--host 0.0.0.0`: Accept connections from any network interface
- `>llama-server_qwen2.5-3b.out 2>&1 &`: Run in background and redirect output to log file

**Verify the server is running:**
```bash
curl http://localhost:8081/health
```

### Managing the Servers

**Check running servers:**
```bash
ps aux | grep llama-server
```

**View server logs:**
```bash
# Embedding server logs
tail -f llama-server_granite-embedding-30m.out

# Text generation server logs
tail -f llama-server_qwen2.5-3b.out
```

**Stop the servers:**
```bash
# Find and kill the processes
pkill -f llama-server

# Or kill specific servers by PID
kill <PID>
```

### Testing the Servers

**Test embedding generation:**
```bash
curl -X POST http://localhost:8080/embedding \
  -H "Content-Type: application/json" \
  -d '{"content": "Hello, world!"}'
```

**Test text generation:**
```bash
curl -X POST http://localhost:8081/completion \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is semantic search?",
    "n_predict": 100
  }'
```

### Troubleshooting

**Port already in use:**
If you see "Address already in use" errors, either stop the existing process or change the port numbers in the commands above.

**Out of memory:**
If the server crashes due to memory issues, try reducing the batch size (`-ub`) for the embedding server or context size (`-c`) for the text generation server.

**Server not responding:**
Check the log files for errors and ensure the model files are in the correct location.

---

**Next Steps:** Once both servers are running successfully, you can proceed with running the main sample application.

