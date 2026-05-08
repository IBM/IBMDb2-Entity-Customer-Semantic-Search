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
-- Customer Semantic Search - Chunk LLM Profiles
-- ============================================================================
-- This script creates a chunking UDF and uses it to chunk LLM profiles
-- Each chunk is approximately 100 words (500 characters max) for optimal embedding
-- Stores results in CUSTOMER_LLM_CHUNKS table
-- ============================================================================
--
-- IMPORTANT: This script uses @ as the statement terminator (needed for UDF creation)
-- Run with: db2 -td@ -vf sql/13_chunk_llm_profiles.sql
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH@

-- ============================================================================
-- Part 1: Create CHUNK_TEXT Table UDF
-- ============================================================================
-- This UDF splits a long text into chunks of specified size
-- Returns a table with chunk_sequence and chunk_text
-- ============================================================================
CREATE OR REPLACE FUNCTION CHUNK_TEXT(
    input_text CLOB(50K),
    chunk_size INTEGER
)
RETURNS TABLE (
    chunk_sequence INTEGER,
    chunk_text VARCHAR(5000)
)
LANGUAGE SQL
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA
BEGIN ATOMIC
    -- Return chunks by splitting the input text
    -- Strips all non-ASCII characters to prevent UTF-8 encoding errors
    RETURN
        SELECT
            N AS chunk_sequence,
            -- Use REGEXP_REPLACE to strip all non-ASCII characters
            RTRIM(
                REGEXP_REPLACE(
                    CAST(SUBSTR(input_text, ((N - 1) * chunk_size) + 1, chunk_size) AS VARCHAR(5000)),
                    '[^\x00-\x7F]+',
                    ' ',
                    1,
                    0,
                    'c'
                )
            ) AS chunk_text
        FROM (
            SELECT 1 AS N FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 2 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 3 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 4 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 5 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 6 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 7 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 8 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 9 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 10 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 11 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 12 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 13 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 14 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 15 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 16 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 17 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 18 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 19 FROM SYSIBM.SYSDUMMY1
            UNION ALL SELECT 20 FROM SYSIBM.SYSDUMMY1
        ) AS NUMBERS
        WHERE ((N - 1) * chunk_size) + 1 <= LENGTH(input_text)
        AND LENGTH(RTRIM(SUBSTR(input_text, ((N - 1) * chunk_size) + 1, chunk_size))) > 0;
END@

SELECT 'CHUNK_TEXT UDF created successfully' AS STATUS FROM SYSIBM.SYSDUMMY1@

-- ============================================================================
-- Part 2: Chunk LLM Profiles
-- ============================================================================
-- Prerequisites:
-- 1. CUSTOMER_LLM_PROFILE table must be populated
-- 2. CUSTOMER_LLM_CHUNKS table must exist

-- Clean Up: Delete existing chunks
-- Ignore warning if table is empty
UPDATE COMMAND OPTIONS USING s OFF@
DELETE FROM CUSTOMER_LLM_CHUNKS@
UPDATE COMMAND OPTIONS USING s ON@

COMMIT@

-- Show progress before chunking
SELECT
    'Starting chunking of ' || COUNT(*) || ' LLM profiles' AS STATUS
FROM CUSTOMER_LLM_PROFILE@

-- ============================================================================
-- Chunk LLM Profiles using CHUNK_TEXT UDF
-- ============================================================================
-- This uses the CHUNK_TEXT table UDF to split profiles into ~500 character chunks
-- (approximately 100 words max per chunk)
-- The UDF returns a table with chunk_sequence and chunk_text columns

INSERT INTO CUSTOMER_LLM_CHUNKS (
    CUSTOMER_SK,
    CUSTOMER_ID,
    CHUNK_SEQUENCE,
    CHUNK_TYPE,
    CHUNK_TEXT,
    CHUNK_SIZE
)
SELECT
    P.CUSTOMER_SK,
    P.CUSTOMER_ID,
    C.chunk_sequence,
    'llm_chunk' || C.chunk_sequence AS CHUNK_TYPE,
    C.chunk_text AS CHUNK_TEXT,
    LENGTH(C.chunk_text) AS CHUNK_SIZE
FROM CUSTOMER_LLM_PROFILE P,
     TABLE(CUSTOMER_SEARCH.CHUNK_TEXT(P.PROFILE_TEXT, 500)) AS C
WHERE P.PROFILE_TEXT IS NOT NULL
ORDER BY P.CUSTOMER_SK, C.chunk_sequence@

COMMIT@

-- ============================================================================
-- Verify Chunks Created
-- ============================================================================
SELECT
    'Total LLM chunks created: ' || COUNT(*) AS STATUS
FROM CUSTOMER_LLM_CHUNKS@

-- Show chunk distribution
SELECT
    'Chunks per customer - Min: ' || MIN(chunk_count) || 
    ', Max: ' || MAX(chunk_count) || 
    ', Avg: ' || CAST(AVG(chunk_count) AS INTEGER) AS DISTRIBUTION
FROM (
    SELECT CUSTOMER_SK, COUNT(*) AS chunk_count
    FROM CUSTOMER_LLM_CHUNKS
    GROUP BY CUSTOMER_SK
) AS CHUNK_COUNTS@

-- Show sample chunks from first customer
SELECT
    CUSTOMER_SK,
    CUSTOMER_ID,
    CHUNK_SEQUENCE,
    CHUNK_TYPE,
    SUBSTR(CHUNK_TEXT, 1, 150) || '...' AS CHUNK_PREVIEW,
    CHUNK_SIZE
FROM CUSTOMER_LLM_CHUNKS
WHERE CUSTOMER_SK = (SELECT MIN(CUSTOMER_SK) FROM CUSTOMER_LLM_CHUNKS)
ORDER BY CHUNK_SEQUENCE@

-- ============================================================================
-- Statistics
-- ============================================================================
SELECT
    'Total chunks: ' || COUNT(*) AS STAT
FROM CUSTOMER_LLM_CHUNKS
UNION ALL
SELECT
    'Unique customers: ' || COUNT(DISTINCT CUSTOMER_SK) AS STAT
FROM CUSTOMER_LLM_CHUNKS
UNION ALL
SELECT
    'Average chunk size: ' || CAST(AVG(CHUNK_SIZE) AS INTEGER) || ' characters' AS STAT
FROM CUSTOMER_LLM_CHUNKS
UNION ALL
SELECT
    'Min chunk size: ' || MIN(CHUNK_SIZE) || ' characters' AS STAT
FROM CUSTOMER_LLM_CHUNKS
UNION ALL
SELECT
    'Max chunk size: ' || MAX(CHUNK_SIZE) || ' characters' AS STAT
FROM CUSTOMER_LLM_CHUNKS@

COMMIT@

-- Made with Bob