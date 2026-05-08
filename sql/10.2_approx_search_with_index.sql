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
-- Customer Semantic Search - Example 2: Approximate Search with Vector Index
-- ============================================================================
-- This script demonstrates approximate similarity search using the vector index
-- Using APPROX keyword leverages the index for faster search on large datasets
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Example 2: Approximate Similarity Search with Index
-- ============================================================================
-- Use APPROX keyword to leverage the vector index for faster search
-- This is more efficient for large datasets

-- QUERY: "Customer who purchases electronics and technology products"
-- EXPECTED RESULTS: Customers with high electronics/tech spending in their purchase history
-- set current explain mode explain;
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
-- set current explain mode no;

-- Made with Bob
