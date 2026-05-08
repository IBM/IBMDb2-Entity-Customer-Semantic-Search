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
-- Customer Semantic Search - Example 1: Basic Semantic Search
-- ============================================================================
-- This script demonstrates basic semantic search using natural language queries
-- The query text is converted to an embedding and compared with stored embeddings
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Example 1: Find Similar Customers by Natural Language Query
-- ============================================================================
-- Search for customers matching a natural language description
-- The query text is converted to an embedding and compared with stored embeddings

-- QUERY: "Customer who purchases electronics and technology products"
-- EXPECTED RESULTS: Customers with high electronics/tech spending in their purchase history
WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who purchases electronics and technology products'
        -- 'Customer who buys electronics and technology products'
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

-- Made with Bob
