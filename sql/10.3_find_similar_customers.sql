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
-- Example 3: Find Similar Customers to a Given Customer
-- ============================================================================
-- Find customers similar to a specific customer (e.g., customer SK=1)

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

-- Made with Bob