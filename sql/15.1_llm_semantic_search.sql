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
-- Customer Semantic Search - LLM Chunks Basic Semantic Search
-- ============================================================================
-- This script demonstrates basic semantic search on LLM-generated chunks
-- Compares results with the same query on regular chunks (step 10.1)
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Example: Find Similar Customers by Natural Language Query (LLM Chunks)
-- ============================================================================
-- Search for customers matching a natural language description
-- The query text is converted to an embedding and compared with LLM chunk embeddings

-- QUERY: "Customer who purchases electronics and technology products"
-- EXPECTED RESULTS: Customers with high electronics/tech spending in their LLM-generated profiles
WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who purchases electronics and technology products'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT
    C.CUSTOMER_SK,
    SUBSTR(C.CHUNK_TYPE, 1, 15) AS CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 200) AS CHUNK_PREVIEW,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_LLM_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- Comparison: Same Query on Regular Chunks (for reference)
-- ============================================================================
-- Run the same query on CUSTOMER_TEXT_CHUNKS to compare results

WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who purchases electronics and technology products'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT
    C.CUSTOMER_SK,
    SUBSTR(C.CHUNK_TYPE, 1, 15) AS CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 200) AS CHUNK_PREVIEW,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- Statistics Comparison
-- ============================================================================
-- Compare the two approaches

SELECT 'LLM Chunks Statistics' AS CATEGORY, 
       COUNT(*) AS TOTAL_CHUNKS,
       COUNT(DISTINCT CUSTOMER_SK) AS UNIQUE_CUSTOMERS,
       CAST(AVG(CHUNK_SIZE) AS INTEGER) AS AVG_CHUNK_SIZE,
       CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT CUSTOMER_SK), 0) AS DECIMAL(5,1)) AS CHUNKS_PER_CUSTOMER
FROM CUSTOMER_LLM_CHUNKS
WHERE EMBEDDING IS NOT NULL
UNION ALL
SELECT 'Regular Chunks Statistics' AS CATEGORY,
       COUNT(*) AS TOTAL_CHUNKS,
       COUNT(DISTINCT CUSTOMER_SK) AS UNIQUE_CUSTOMERS,
       CAST(AVG(CHUNK_SIZE) AS INTEGER) AS AVG_CHUNK_SIZE,
       CAST(COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT CUSTOMER_SK), 0) AS DECIMAL(5,1)) AS CHUNKS_PER_CUSTOMER
FROM CUSTOMER_TEXT_CHUNKS
WHERE EMBEDDING IS NOT NULL;

-- ============================================================================
-- Side-by-Side Comparison for Top Customer
-- ============================================================================
-- Show the top matching customer from both approaches

WITH LLM_TOP AS (
    SELECT C.CUSTOMER_SK, C.CUSTOMER_ID,
           VECTOR_DISTANCE(C.EMBEDDING, 
               (SELECT TO_EMBEDDING('Customer who purchases electronics and technology products' USING GRANITE30) 
                FROM SYSIBM.SYSDUMMY1), EUCLIDEAN) AS DISTANCE
    FROM CUSTOMER_LLM_CHUNKS C
    WHERE C.EMBEDDING IS NOT NULL
    ORDER BY DISTANCE ASC
    FETCH FIRST 1 ROW ONLY
),
REGULAR_TOP AS (
    SELECT C.CUSTOMER_SK, C.CUSTOMER_ID,
           VECTOR_DISTANCE(C.EMBEDDING, 
               (SELECT TO_EMBEDDING('Customer who purchases electronics and technology products' USING GRANITE30) 
                FROM SYSIBM.SYSDUMMY1), EUCLIDEAN) AS DISTANCE
    FROM CUSTOMER_TEXT_CHUNKS C
    WHERE C.EMBEDDING IS NOT NULL
    ORDER BY DISTANCE ASC
    FETCH FIRST 1 ROW ONLY
)
SELECT 'LLM Chunks Top Match' AS SOURCE,
       L.CUSTOMER_SK, L.CUSTOMER_ID,
       CAST(L.DISTANCE AS DECIMAL(8,2)) AS DISTANCE
FROM LLM_TOP L
UNION ALL
SELECT 'Regular Chunks Top Match' AS SOURCE,
       R.CUSTOMER_SK, R.CUSTOMER_ID,
       CAST(R.DISTANCE AS DECIMAL(8,2)) AS DISTANCE
FROM REGULAR_TOP R;

-- Made with Bob
