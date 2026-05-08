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
-- Customer Semantic Search - Semantic Search Queries
-- ============================================================================
-- This script demonstrates semantic search using approximate similarity search
-- on the vector embeddings with the vector index
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Example 1: Find Similar Customers by Natural Language Query
-- ============================================================================
-- Search for customers matching a natural language description
-- The query text is converted to an embedding and compared with stored embeddings

-- OUTPUT: ============================================================================
-- OUTPUT: Example 1: Find customers who buy electronics
-- OUTPUT: QUERY: "Customer who purchases electronics and technology products"
-- OUTPUT: ============================================================================

-- QUERY: "Customer who purchases electronics and technology products"
-- EXPECTED RESULTS: Customers with high electronics/tech spending in their purchase history
WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who purchases electronics and technology products'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    C.CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 60) AS CHUNK_PREVIEW,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- Example 2: Approximate Similarity Search with Index
-- ============================================================================
-- 
-- OUTPUT: ============================================================================
-- OUTPUT: Example 2: Approximate search with vector index (faster)
-- OUTPUT: QUERY: "Customers who purchases electronics and technology products"
-- OUTPUT: ============================================================================

-- Use APPROX keyword to leverage the vector index for faster search
-- This is more efficient for large datasets

-- QUERY: "who purchases electronics and technology products"
-- EXPECTED RESULTS: Customers with high electronics/tech spending in their purchase history
WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who purchases electronics and technology products'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    C.CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 60) AS CHUNK_PREVIEW,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH APPROX FIRST 10 ROWS ONLY;

-- ============================================================================
-- Example 3: Find Similar Customers to a Given Customer
-- ============================================================================
-- 
-- OUTPUT: ============================================================================
-- OUTPUT: Example 3: Find customers similar to a specific customer
-- OUTPUT: QUERY: Find customers with similar profiles to customer SK=1
-- OUTPUT: ============================================================================

-- Find customers similar to a specific customer (e.g., customer ID 1)

-- QUERY: Find customers with similar profiles to customer SK=1
-- EXPECTED RESULTS: Customers with similar demographics, shopping patterns, and preferences
WITH SIMILARITY_SCORES AS (
    SELECT
        C2.CUSTOMER_SK,
        C2.CUSTOMER_ID,
        C2.CHUNK_ID,
        AVG(VECTOR_DISTANCE(C1.EMBEDDING, C2.EMBEDDING, EUCLIDEAN)) AS AVG_DISTANCE
    FROM CUSTOMER_TEXT_CHUNKS C1
    INNER JOIN CUSTOMER_TEXT_CHUNKS C2
        ON C1.CUSTOMER_SK != C2.CUSTOMER_SK
    WHERE C1.CUSTOMER_SK = 1
    AND C1.EMBEDDING IS NOT NULL
    AND C2.EMBEDDING IS NOT NULL
    GROUP BY C2.CUSTOMER_SK, C2.CUSTOMER_ID, C2.CHUNK_ID
)
SELECT
    S.CUSTOMER_SK,
    S.CUSTOMER_ID,
    C.CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 50) AS CHUNK_PREVIEW,
    CAST(S.AVG_DISTANCE AS DECIMAL(8,2)) AS AVG_DIST
FROM SIMILARITY_SCORES S
INNER JOIN CUSTOMER_TEXT_CHUNKS C ON S.CHUNK_ID = C.CHUNK_ID
ORDER BY S.AVG_DISTANCE ASC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- Example 4: Semantic Search with Filters
-- ============================================================================
-- 
-- OUTPUT: ============================================================================
-- OUTPUT: Example 4: Semantic search with geographic filters
-- OUTPUT: QUERY: "Customer interested in fitness, health, and wellness products"
-- OUTPUT: FILTER: Only customers in IL, WI, IN (Midwest states)
-- OUTPUT: ============================================================================

-- Combine semantic search with traditional filters
-- Example: Find customers who buy fitness products AND live in specific states

-- QUERY: "Customer interested in fitness, health, and wellness products"
-- FILTER: Only customers in IL, WI, IN (Midwest states)
-- EXPECTED RESULTS: Fitness-oriented customers located in the Midwest
WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer interested in fitness, health, and wellness products'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    SUBSTR(C.CHUNK_TEXT, 1, 40) AS CHUNK_PREVIEW,
    CA.CA_STATE,
    SUBSTR(CA.CA_CITY, 1, 15) AS CITY,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
INNER JOIN CUSTOMER CUST ON C.CUSTOMER_SK = CUST.C_CUSTOMER_SK
INNER JOIN CUSTOMER_ADDRESS CA ON CUST.C_CURRENT_ADDR_SK = CA.CA_ADDRESS_SK
WHERE C.EMBEDDING IS NOT NULL
AND CA.CA_STATE IN ('IL', 'WI', 'IN')  -- Midwest states
AND C.CHUNK_TYPE = 'top_items'
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH APPROX FIRST 10 ROWS ONLY;

-- ============================================================================
-- Example 5: Multi-Aspect Customer Search
-- ============================================================================
-- 
-- OUTPUT: ============================================================================
-- OUTPUT: Example 5: Multi-aspect customer search
-- OUTPUT: QUERY: "Customer who returns items frequently and shops at multiple stores"
-- OUTPUT: Shows customers matching on 2+ aspects (items, stores, spending)
-- OUTPUT: ============================================================================

-- Search across different aspects of customer profiles
-- Aggregate results from different chunk types

-- QUERY: "Customer who returns items frequently and shops at multiple stores"
-- EXPECTED RESULTS: Customers matching on multiple aspects (returns + store diversity)
-- Shows customers with matches across 2+ chunk types (items, stores, spending)
WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who returns items frequently and shops at multiple stores'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    COUNT(DISTINCT C.CHUNK_TYPE) AS ASPECTS,
    CAST(MIN(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN)) AS DECIMAL(8,2)) AS BEST_DIST,
    CAST(AVG(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN)) AS DECIMAL(8,2)) AS AVG_DIST,
    SUBSTR(LISTAGG(C.CHUNK_TYPE, ',') WITHIN GROUP (ORDER BY C.CHUNK_TYPE), 1, 30) AS TYPES
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
AND VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) < 100
GROUP BY C.CUSTOMER_SK, C.CUSTOMER_ID
HAVING COUNT(DISTINCT C.CHUNK_TYPE) >= 2
ORDER BY BEST_DIST ASC
FETCH FIRST 10 ROWS ONLY;

-- Made with Bob
