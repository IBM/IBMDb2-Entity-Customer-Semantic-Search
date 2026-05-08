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
-- Customer Semantic Search - Example 5: Multi-Aspect Customer Search
-- ============================================================================
-- This script demonstrates searching across different aspects of customer profiles
-- Aggregates results from different chunk types to find comprehensive matches
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Example 5: Multi-Aspect Customer Search
-- ============================================================================
-- Search across different aspects of customer profiles
-- Aggregate results from different chunk types

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
    SUBSTR(C.CHUNK_TEXT, 1, 150) AS CHUNK_PREVIEW,
    CAST(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DECIMAL(8,2)) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) ASC
FETCH FIRST 10 ROWS ONLY;

-- QUERY: "Customer 
-- EXPECTED RESULTS: Customers matching on multiple aspects (returns + store diversity)
-- Shows customers with matches across 2+ chunk types (items, stores)
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

-- QUERY: "rns items frequently and shops at multiple stores"
-- EXPECTED RESULTS: Customers matching on multiple aspects (returns + store diversity)
-- Shows customers with matches across 2+ chunk types (items, stores, spending)
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
