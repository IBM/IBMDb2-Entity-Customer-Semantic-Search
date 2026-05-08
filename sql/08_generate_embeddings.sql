-- Copyright 2026 Entity Customer Semantic Search in Db2 LUW Project
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- ============================================================================
-- Customer Semantic Search - Generate Embeddings
-- ============================================================================
-- This script creates external AI models and generates embeddings for text chunks
-- Uses local LLM servers (llama.cpp) for embedding generation
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Create External AI Models
-- ============================================================================

-- Drop existing models if they exist
-- Disable stop-on-error to ignore "object not found" errors
UPDATE COMMAND OPTIONS USING s OFF;
DROP EXTERNAL MODEL GRANITE30;
DROP EXTERNAL MODEL QWEN_TEXT_GEN;
UPDATE COMMAND OPTIONS USING s ON;

-- Create Embedding Model (Granite 30M)
-- This model converts text into 384-dimensional vector embeddings
CREATE EXTERNAL MODEL GRANITE30
PROVIDER OPENAI
ID 'granite-embedding-30m-english-Q6_K.gguf'
TYPE TEXT_EMBEDDING RETURNING VECTOR(384, FLOAT32)
URL 'http://127.0.0.1:8080/v1/embeddings';

-- Create Text Generation Model (Qwen 2.5 3B)
-- This model generates natural language text responses
CREATE EXTERNAL MODEL QWEN_TEXT_GEN
PROVIDER OPENAI
ID 'qwen2.5-3b-instruct-q4_k_m.gguf'
TYPE TEXT_GENERATION RETURNING CLOB(30000)
URL 'http://0.0.0.0:8081/v1/chat/completions';

COMMIT;

-- ============================================================================
-- Verify Models Created
-- ============================================================================
SELECT 'External models created successfully' AS STATUS FROM SYSIBM.SYSDUMMY1;
SELECT '  - GRANITE30 (embedding model)' AS MODEL_INFO FROM SYSIBM.SYSDUMMY1;
SELECT '  - QWEN_TEXT_GEN (text generation model)' AS MODEL_INFO FROM SYSIBM.SYSDUMMY1;

-- ============================================================================
-- Generate Embeddings for Text Chunks
-- ============================================================================
-- This updates the EMBEDDING column in CUSTOMER_TEXT_CHUNKS table
-- Using the TO_EMBEDDING function with the GRANITE30 model

-- Show progress before generation
SELECT
    'Starting embedding generation for ' || COUNT(*) || ' chunks' AS STATUS
FROM CUSTOMER_TEXT_CHUNKS
WHERE EMBEDDING IS NULL;

-- Generate embeddings for all chunks
-- This may take some time depending on the number of chunks
UPDATE CUSTOMER_TEXT_CHUNKS
SET EMBEDDING = TO_EMBEDDING(CHUNK_TEXT USING GRANITE30)
WHERE EMBEDDING IS NULL;

COMMIT;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT 'Embeddings generated successfully' AS STATUS FROM SYSIBM.SYSDUMMY1;

-- Show embedding statistics
SELECT
    'Total chunks with embeddings: ' || COUNT(*) AS STAT
FROM CUSTOMER_TEXT_CHUNKS
WHERE EMBEDDING IS NOT NULL
UNION ALL
SELECT
    'Chunks without embeddings: ' || COUNT(*)
FROM CUSTOMER_TEXT_CHUNKS
WHERE EMBEDDING IS NULL
UNION ALL
SELECT
    'Embedding dimension: 384' AS STAT
FROM SYSIBM.SYSDUMMY1;

-- Show embedding statistics by chunk type
SELECT
    CHUNK_TYPE,
    COUNT(*) AS CHUNKS_WITH_EMBEDDINGS,
    AVG(CHUNK_SIZE) AS AVG_CHUNK_SIZE
FROM CUSTOMER_TEXT_CHUNKS
WHERE EMBEDDING IS NOT NULL
GROUP BY CHUNK_TYPE
ORDER BY CHUNK_TYPE;

-- Display sample chunk with embedding info
SELECT
    CHUNK_ID,
    CUSTOMER_SK,
    CUSTOMER_ID,
    CHUNK_TYPE,
    CHUNK_SIZE,
    SUBSTR(CHUNK_TEXT, 1, 100) AS CHUNK_SAMPLE,
    CASE
        WHEN EMBEDDING IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS HAS_EMBEDDING,
    SUBSTR(VECTOR_SERIALIZE(EMBEDDING), 1, 100) AS EMBEDDING_STR
FROM CUSTOMER_TEXT_CHUNKS
WHERE CUSTOMER_SK = 1
ORDER BY CHUNK_SEQUENCE;

-- Test embedding distance (Euclidean distance between first two chunks)
-- This demonstrates that embeddings are working correctly
-- Lower distance = more similar vectors
SELECT
    'Testing embedding distance between chunks' AS TEST_NAME,
    VECTOR_DISTANCE(
        (SELECT EMBEDDING FROM CUSTOMER_TEXT_CHUNKS WHERE CHUNK_ID = 1),
        (SELECT EMBEDDING FROM CUSTOMER_TEXT_CHUNKS WHERE CHUNK_ID = 2),
        EUCLIDEAN
    ) AS DISTANCE_SCORE
FROM SYSIBM.SYSDUMMY1;

-- ============================================================================
-- Performance Notes
-- ============================================================================
-- Embedding generation time depends on:
-- - Number of chunks to process
-- - Text length of each chunk
-- - CPU performance of the machine running llama-server
-- - Batch size configuration of the embedding server
--
-- For 1000 chunks with average 500 characters each:
-- - Expected time: 2-5 minutes on modern CPU
-- - Memory usage: ~500MB for the embedding model
--
-- The embeddings are persisted in the database and only need to be
-- generated once unless the text chunks are updated.
-- ============================================================================

-- Made with Bob
