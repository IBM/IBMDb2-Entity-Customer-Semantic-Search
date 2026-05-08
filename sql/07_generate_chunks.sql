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
-- Customer Semantic Search - Generate Text Chunks
-- ============================================================================
-- This script generates text chunks from JSON documents using the UDFs
-- Each customer's JSON is converted to multiple text chunks
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Generate Text Chunks from JSON Documents
-- ============================================================================
-- We create separate chunks for different aspects of the customer profile:
-- 1. Customer basic info and demographics
-- 2. Top purchased items
-- 3. Top stores
-- 4. Spending patterns and summary

-- Chunk 1: Customer Basic Information
INSERT INTO CUSTOMER_TEXT_CHUNKS (
    CUSTOMER_SK,
    CUSTOMER_ID,
    CHUNK_SEQUENCE,
    CHUNK_TYPE,
    CHUNK_TEXT,
    CHUNK_SIZE
)
SELECT
    CUSTOMER_SK,
    CUSTOMER_ID,
    1 AS CHUNK_SEQUENCE,
    'customer_info' AS CHUNK_TYPE,
    CUSTOMER_SEARCH.JSON_TO_TEXT(JSON_DOCUMENT) AS CHUNK_TEXT,
    LENGTH(CUSTOMER_SEARCH.JSON_TO_TEXT(JSON_DOCUMENT)) AS CHUNK_SIZE
FROM CUSTOMER_JSON_DOCS
WHERE JSON_DOCUMENT IS NOT NULL;

-- Chunk 2: Top Purchased Items
INSERT INTO CUSTOMER_TEXT_CHUNKS (
    CUSTOMER_SK,
    CUSTOMER_ID,
    CHUNK_SEQUENCE,
    CHUNK_TYPE,
    CHUNK_TEXT,
    CHUNK_SIZE
)
SELECT
    CUSTOMER_SK,
    CUSTOMER_ID,
    2 AS CHUNK_SEQUENCE,
    'top_items' AS CHUNK_TYPE,
    CUSTOMER_SEARCH.EXTRACT_ITEMS_TEXT(JSON_DOCUMENT) AS CHUNK_TEXT,
    LENGTH(CUSTOMER_SEARCH.EXTRACT_ITEMS_TEXT(JSON_DOCUMENT)) AS CHUNK_SIZE
FROM CUSTOMER_JSON_DOCS
WHERE JSON_DOCUMENT IS NOT NULL
AND JSON_EXISTS(JSON_DOCUMENT, '$.top_purchased_items[0]');

-- Chunk 3: Top Stores
INSERT INTO CUSTOMER_TEXT_CHUNKS (
    CUSTOMER_SK,
    CUSTOMER_ID,
    CHUNK_SEQUENCE,
    CHUNK_TYPE,
    CHUNK_TEXT,
    CHUNK_SIZE
)
SELECT
    CUSTOMER_SK,
    CUSTOMER_ID,
    3 AS CHUNK_SEQUENCE,
    'top_stores' AS CHUNK_TYPE,
    CUSTOMER_SEARCH.EXTRACT_STORES_TEXT(JSON_DOCUMENT) AS CHUNK_TEXT,
    LENGTH(CUSTOMER_SEARCH.EXTRACT_STORES_TEXT(JSON_DOCUMENT)) AS CHUNK_SIZE
FROM CUSTOMER_JSON_DOCS
WHERE JSON_DOCUMENT IS NOT NULL
AND JSON_EXISTS(JSON_DOCUMENT, '$.top_stores[0]');

-- Chunk 4: Spending Patterns and Summary
INSERT INTO CUSTOMER_TEXT_CHUNKS (
    CUSTOMER_SK,
    CUSTOMER_ID,
    CHUNK_SEQUENCE,
    CHUNK_TYPE,
    CHUNK_TEXT,
    CHUNK_SIZE
)
SELECT
    CUSTOMER_SK,
    CUSTOMER_ID,
    4 AS CHUNK_SEQUENCE,
    'spending_summary' AS CHUNK_TYPE,
    CUSTOMER_SEARCH.EXTRACT_SPENDING_TEXT(JSON_DOCUMENT) AS CHUNK_TEXT,
    LENGTH(CUSTOMER_SEARCH.EXTRACT_SPENDING_TEXT(JSON_DOCUMENT)) AS CHUNK_SIZE
FROM CUSTOMER_JSON_DOCS
WHERE JSON_DOCUMENT IS NOT NULL
AND JSON_EXISTS(JSON_DOCUMENT, '$.summary');

COMMIT;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT 'Text chunks generated successfully' AS STATUS FROM SYSIBM.SYSDUMMY1;

-- Show chunk statistics
SELECT 
    'Total chunks: ' || COUNT(*) AS STAT
FROM CUSTOMER_TEXT_CHUNKS
UNION ALL
SELECT 
    'Chunks per customer: ' || CAST(AVG(chunk_count) AS VARCHAR(10))
FROM (
    SELECT CUSTOMER_SK, COUNT(*) AS chunk_count
    FROM CUSTOMER_TEXT_CHUNKS
    GROUP BY CUSTOMER_SK
)
UNION ALL
SELECT 
    'Average chunk size: ' || CAST(AVG(CHUNK_SIZE) AS VARCHAR(10)) || ' characters'
FROM CUSTOMER_TEXT_CHUNKS;

-- Show chunk type distribution
SELECT 
    CHUNK_TYPE,
    COUNT(*) AS CHUNK_COUNT,
    AVG(CHUNK_SIZE) AS AVG_SIZE,
    MIN(CHUNK_SIZE) AS MIN_SIZE,
    MAX(CHUNK_SIZE) AS MAX_SIZE
FROM CUSTOMER_TEXT_CHUNKS
GROUP BY CHUNK_TYPE
ORDER BY CHUNK_TYPE;

-- Display sample chunks for first customer
SELECT 
    CHUNK_ID,
    CUSTOMER_SK,
    CUSTOMER_ID,
    CHUNK_SEQUENCE,
    CHUNK_TYPE,
    SUBSTR(CHUNK_TEXT, 1, 200) AS CHUNK_SAMPLE,
    CHUNK_SIZE
FROM CUSTOMER_TEXT_CHUNKS
WHERE CUSTOMER_SK = 1
ORDER BY CHUNK_SEQUENCE;

-- Made with Bob
