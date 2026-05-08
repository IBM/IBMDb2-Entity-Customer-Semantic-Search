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
-- Customer Semantic Search - Example 3: Find Similar Customers
-- ============================================================================
-- This script demonstrates finding customers similar to a specific customer
-- by comparing their embeddings across all profile aspects
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Example 3: Find Similar Customers to a Given Customer Purchase Patterns
-- ============================================================================
-- Find customers similar to a specific customer (e.g., customer SK=1)

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

-- Made with Bob
