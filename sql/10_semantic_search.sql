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
-- This file combines all examples from 10.1 through 10.5
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Example 1: Basic Semantic Search
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
    SUBSTR(C.CHUNK_TYPE, 1, 15) AS CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 300) AS CHUNK_PREVIEW,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH FIRST 6 ROWS ONLY;

-- ============================================================================
-- Example 2: Approximate Search with Vector Index
-- ============================================================================
-- Use APPROX keyword to leverage the vector index for faster search
-- This is more efficient for large datasets

-- OUTPUT: ============================================================================
-- OUTPUT: Example 2: Approximate search with vector index (faster)
-- OUTPUT: QUERY: "Customer who purchases electronics and technology products"
-- OUTPUT: Uses FETCH APPROX for faster search on large datasets
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
    SUBSTR(C.CHUNK_TYPE, 1, 15) AS CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 100) AS CHUNK_PREVIEW,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH APPROX FIRST 10 ROWS ONLY
/* <OPTGUIDELINES> <IXSCAN TABLE='C' INDEX='IDX_CUSTOMER_EMBEDDINGS'/> </OPTGUIDELINES> */;

-- ============================================================================
-- Example 3: Find Similar Customers
-- ============================================================================
-- Find customers similar to a specific customer by comparing their embeddings
-- across all profile aspects

-- OUTPUT: ============================================================================
-- OUTPUT: Example 3: Find customers similar to a specific customer
-- OUTPUT: QUERY: Find customers with similar profiles to customer SK=1
-- OUTPUT: ============================================================================

-- First, show the reference customer's profile
SELECT
    C1.CUSTOMER_SK,
    SUBSTR(C1.CHUNK_TEXT, 1, 600) AS CHUNK_PREVIEW
FROM CUSTOMER_TEXT_CHUNKS C1
WHERE C1.CUSTOMER_SK = 1
AND C1.CHUNK_TYPE = 'top_items';

-- QUERY: Find customers with similar profiles to customer SK=1
-- EXPECTED RESULTS: Customers with similar shopping patterns
WITH QUERY_EMBEDDING AS (
    SELECT
        C1.EMBEDDING AS QUERY_VECTOR
    FROM CUSTOMER_TEXT_CHUNKS C1
    WHERE C1.CUSTOMER_SK = 1
    AND C1.CHUNK_TYPE = 'top_items'
)
SELECT
    C.CUSTOMER_SK,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE,
    SUBSTR(C.CHUNK_TEXT, 1, 600) AS CHUNK_PREVIEW
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
AND C.CUSTOMER_SK <> 1
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH APPROX FIRST 3 ROWS ONLY;

-- ============================================================================
-- Example 4: Semantic Search with Filters
-- ============================================================================
-- Combine semantic search with traditional filters
-- Example: Find customers who buy fitness products AND live in specific states

-- OUTPUT: ============================================================================
-- OUTPUT: Example 4: Semantic search with geographic filters
-- OUTPUT: QUERY: "Customer interested in fitness, health, and wellness products"
-- OUTPUT: FILTER: Only customers in IL, WI, IN (Midwest states)
-- OUTPUT: ============================================================================

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
-- Search across different aspects of customer profiles
-- Aggregate results from different chunk types

-- OUTPUT: ============================================================================
-- OUTPUT: Example 5: Multi-aspect customer search
-- OUTPUT: Multiple queries demonstrating different search patterns
-- OUTPUT: ============================================================================

-- Query 5.1: Electronics and technology products
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
    SUBSTR(C.CHUNK_TEXT, 1, 150) AS CHUNK_PREVIEW,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH FIRST 10 ROWS ONLY;

-- Query 5.2: Electronics in Canadian stores
WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Purchase for electronics and technology products in canadian stores'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT
    C.CUSTOMER_SK,
    SUBSTR(C.CHUNK_TYPE, 1, 15) AS CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 150) AS CHUNK_PREVIEW,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH FIRST 10 ROWS ONLY;

-- Query 5.3: Technology products in Canada
WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'technology products Canada'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT
    C.CUSTOMER_SK,
    SUBSTR(C.CHUNK_TYPE, 1, 15) AS CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 150) AS CHUNK_PREVIEW,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH FIRST 10 ROWS ONLY;

-- Made with Bob
