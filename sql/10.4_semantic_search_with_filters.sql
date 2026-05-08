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
-- Customer Semantic Search - Example 4: Semantic Search with Filters
-- ============================================================================
-- This script demonstrates combining semantic search with traditional filters
-- Example: Find customers matching a semantic query AND geographic criteria
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Example 4: Semantic Search with Filters
-- ============================================================================
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

-- Made with Bob