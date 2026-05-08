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
-- Customer Semantic Search - Generate Embeddings for LLM Chunks
-- ============================================================================
-- This script generates vector embeddings for LLM-generated text chunks
-- Uses the GRANITE30 embedding model to create 384-dimensional vectors
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Prerequisites
-- ============================================================================
-- 1. GRANITE30 model must be created (see step 8)
-- 2. llama-server must be running on port 8080 with granite-embedding model
-- 3. CUSTOMER_LLM_CHUNKS table must be populated with text chunks

-- ============================================================================
-- Generate Embeddings for LLM Chunks
-- ============================================================================
-- This updates the EMBEDDING column in CUSTOMER_LLM_CHUNKS table
-- Uses TO_EMBEDDING function with GRANITE30 model

-- Show progress before generation
SELECT
    'Starting embedding generation for ' || COUNT(*) || ' LLM chunks' AS STATUS
FROM CUSTOMER_LLM_CHUNKS
WHERE CHUNK_TEXT IS NOT NULL AND EMBEDDING IS NULL;

-- Generate embeddings for all LLM chunks without embeddings
-- This may take a while depending on the number of chunks
-- Text is already cleaned to ASCII-only in step 13
UPDATE CUSTOMER_LLM_CHUNKS
SET EMBEDDING = TO_EMBEDDING(CHUNK_TEXT USING GRANITE30)
WHERE CHUNK_TEXT IS NOT NULL
AND EMBEDDING IS NULL
AND LENGTH(CHUNK_TEXT) > 10;

COMMIT;

-- ============================================================================
-- Verify Embeddings Created
-- ============================================================================
SELECT
    'LLM chunks with embeddings: ' || COUNT(*) AS STATUS
FROM CUSTOMER_LLM_CHUNKS
WHERE EMBEDDING IS NOT NULL;

-- Show sample of chunks with embeddings
SELECT
    CHUNK_ID,
    CUSTOMER_SK,
    CUSTOMER_ID,
    CHUNK_SEQUENCE,
    CHUNK_TYPE,
    SUBSTR(CHUNK_TEXT, 1, 100) || '...' AS TEXT_PREVIEW,
    CHUNK_SIZE,
    CASE WHEN EMBEDDING IS NOT NULL THEN 'Yes' ELSE 'No' END AS HAS_EMBEDDING
FROM CUSTOMER_LLM_CHUNKS
ORDER BY CHUNK_ID
FETCH FIRST 5 ROWS ONLY;

-- ============================================================================
-- Statistics
-- ============================================================================
SELECT
    'Total LLM chunks: ' || COUNT(*) AS STAT
FROM CUSTOMER_LLM_CHUNKS
UNION ALL
SELECT
    'LLM chunks with embeddings: ' || COUNT(*) AS STAT
FROM CUSTOMER_LLM_CHUNKS
WHERE EMBEDDING IS NOT NULL
UNION ALL
SELECT
    'LLM chunks without embeddings: ' || COUNT(*) AS STAT
FROM CUSTOMER_LLM_CHUNKS
WHERE EMBEDDING IS NULL
UNION ALL
SELECT
    'Average LLM chunk size: ' || CAST(AVG(CHUNK_SIZE) AS INTEGER) || ' characters' AS STAT
FROM CUSTOMER_LLM_CHUNKS
UNION ALL
SELECT
    'Unique customers: ' || COUNT(DISTINCT CUSTOMER_SK) AS STAT
FROM CUSTOMER_LLM_CHUNKS;

COMMIT;

-- Made with Bob