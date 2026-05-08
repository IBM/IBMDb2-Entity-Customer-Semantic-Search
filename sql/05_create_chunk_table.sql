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
-- Customer Semantic Search - Text Chunks Table
-- ============================================================================
-- This script creates the table to store text chunks extracted from JSON
-- Each chunk will later have an embedding generated for semantic search
-- Re-entrant: Drops and recreates the table
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- Drop existing table if it exists
UPDATE COMMAND OPTIONS USING s OFF;
DROP TABLE CUSTOMER_TEXT_CHUNKS;
UPDATE COMMAND OPTIONS USING s ON;

-- ============================================================================
-- Create Text Chunks Table
-- ============================================================================
-- This table stores text chunks extracted from JSON documents
-- Each customer's JSON document is split into multiple chunks
-- Each chunk will have an embedding generated for vector search
CREATE TABLE CUSTOMER_TEXT_CHUNKS (
    CHUNK_ID INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1),
    CUSTOMER_SK INTEGER NOT NULL,
    CUSTOMER_ID VARCHAR(16) NOT NULL,
    CHUNK_SEQUENCE INTEGER NOT NULL,
    CHUNK_TYPE VARCHAR(50),  -- e.g., 'customer_info', 'top_items', 'top_stores', 'monthly_spending'
    CHUNK_TEXT CLOB(30K),
    CHUNK_SIZE INTEGER,  -- Number of characters in the chunk
    EMBEDDING VECTOR(384, FLOAT32),  -- Will be populated later with TO_EMBEDDING (Granite 30M uses 384 dimensions)
    CREATED_TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (CHUNK_ID)
) IN cust_tbsp;

-- Create indexes for efficient querying
CREATE INDEX IDX_CHUNK_CUSTOMER ON CUSTOMER_TEXT_CHUNKS(CUSTOMER_SK);
CREATE INDEX IDX_CHUNK_CUSTOMER_ID ON CUSTOMER_TEXT_CHUNKS(CUSTOMER_ID);
CREATE INDEX IDX_CHUNK_TYPE ON CUSTOMER_TEXT_CHUNKS(CHUNK_TYPE);
CREATE INDEX IDX_CHUNK_SEQUENCE ON CUSTOMER_TEXT_CHUNKS(CUSTOMER_SK, CHUNK_SEQUENCE);

-- Add foreign key constraint
ALTER TABLE CUSTOMER_TEXT_CHUNKS 
ADD CONSTRAINT FK_CHUNK_CUSTOMER 
FOREIGN KEY (CUSTOMER_SK) 
REFERENCES CUSTOMER(C_CUSTOMER_SK);

COMMIT;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT 'Text chunks table created successfully' AS STATUS FROM SYSIBM.SYSDUMMY1;
SELECT TABNAME, COLNAME, TYPENAME, LENGTH 
FROM SYSCAT.COLUMNS 
WHERE TABSCHEMA = 'CUSTOMER_SEARCH' AND TABNAME = 'CUSTOMER_TEXT_CHUNKS'
ORDER BY COLNO;

-- Made with Bob
