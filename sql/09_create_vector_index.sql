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
-- Customer Semantic Search - Create Vector Index
-- ============================================================================
-- This script creates a vector index on the embedding column
-- for efficient approximate similarity search using Db2 EAP Vector Indexing
-- Re-entrant: Drops and recreates the index
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Prerequisites
-- ============================================================================
-- 1. Enable vector indexing in Db2:
--    db2set DB2_VECTOR_INDEXING=YES -immediate
--
-- 2. Ensure the EMBEDDING column is NOT NULL or use EXCLUDE NULL KEYS
--
-- 3. Verify page size is sufficient for vector dimensions:
--    - 1536 dimensions × 4 bytes (FLOAT32) = 6,144 bytes
--    - Requires at least 16KB page size (2/3 of page = ~10,922 bytes)

-- Drop existing vector index if it exists
UPDATE COMMAND OPTIONS USING s OFF;
DROP INDEX IDX_CUSTOMER_EMBEDDINGS;
UPDATE COMMAND OPTIONS USING s ON;

-- ============================================================================
-- Create Vector Index on Embeddings
-- ============================================================================
-- The vector index enables fast approximate nearest neighbor (ANN) search
-- This is crucial for semantic search performance on large datasets
--
-- Using EUCLIDEAN distance metric to match the VECTOR_DISTANCE function
-- used in queries and tests

CREATE VECTOR INDEX IDX_CUSTOMER_EMBEDDINGS
   ON CUSTOMER_TEXT_CHUNKS(EMBEDDING)
   WITH DISTANCE EUCLIDEAN;

COMMIT;

-- ============================================================================
-- Update Statistics
-- ============================================================================
-- Update statistics on the table and indexes for optimal query performance
RUNSTATS ON TABLE CUSTOMER_SEARCH.CUSTOMER_TEXT_CHUNKS AND INDEXES ALL;

-- ============================================================================
-- Alternative Index Configurations
-- ============================================================================
-- For different use cases, you might want different configurations:

-- High Recall Configuration (better accuracy, lower speed):
-- CREATE VECTOR INDEX IDX_CUSTOMER_EMBEDDINGS_HIGH_RECALL
-- ON CUSTOMER_TEXT_CHUNKS(EMBEDDING)
-- WITH DISTANCE EUCLIDEAN
-- BUILD_LIST_SIZE 100;

-- Low Recall Configuration (worse accuracy, highes speed):
-- CREATE VECTOR INDEX IDX_CUSTOMER_EMBEDDINGS_HIGH_SPEED
-- ON CUSTOMER_TEXT_CHUNKS(EMBEDDING)
-- WITH DISTANCE EUCLIDEAN
-- BUILD_LIST_SIZE 20;

COMMIT;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT 'Vector index created successfully' AS STATUS FROM SYSIBM.SYSDUMMY1;

-- Check index details
SELECT 
    INDNAME,
    TABNAME,
    COLNAMES,
    INDEXTYPE,
    UNIQUERULE,
    MADE_UNIQUE,
    REMARKS
FROM SYSCAT.INDEXES
WHERE TABSCHEMA = 'CUSTOMER_SEARCH'
AND TABNAME = 'CUSTOMER_TEXT_CHUNKS'
AND INDNAME LIKE '%EMBEDDING%'
ORDER BY INDNAME;

-- Check index statistics
SELECT 
    INDSCHEMA,
    INDNAME,
    TABNAME,
    COLNAMES,
    NLEAF,
    NLEVELS,
    FIRSTKEYCARD,
    FULLKEYCARD,
    CLUSTERRATIO,
    SEQUENTIAL_PAGES,
    DENSITY
FROM SYSCAT.INDEXES
WHERE TABSCHEMA = 'CUSTOMER_SEARCH'
AND INDNAME = 'IDX_CUSTOMER_EMBEDDINGS';

-- Made with Bob
