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
-- Customer Semantic Search - LLM-Generated Profile Table
-- ============================================================================
-- This script creates a table to store comprehensive LLM-generated customer profiles
-- Similar to CUSTOMER_JSON_DOCS but stores AI-generated natural language profiles
-- Re-entrant: Drops and recreates the table
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- Drop existing table if it exists
UPDATE COMMAND OPTIONS USING s OFF;
DROP TABLE CUSTOMER_LLM_PROFILE;
UPDATE COMMAND OPTIONS USING s ON;

-- ============================================================================
-- Create LLM Profile Table
-- ============================================================================
-- This table stores comprehensive AI-generated customer profiles
-- Each customer gets one long-form profile (up to 1000 words)
-- These profiles will be chunked in a later step
CREATE TABLE CUSTOMER_LLM_PROFILE (
    CUSTOMER_SK INTEGER NOT NULL,
    CUSTOMER_ID VARCHAR(16) NOT NULL,
    PROFILE_TEXT CLOB(50K),  -- Comprehensive LLM-generated profile
    PROFILE_SIZE INTEGER,     -- Number of characters in the profile
    CREATED_TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (CUSTOMER_SK)
) IN cust_tbsp;

-- Create index for efficient querying
CREATE INDEX IDX_LLM_PROFILE_CUSTOMER_ID ON CUSTOMER_LLM_PROFILE(CUSTOMER_ID);

-- Add foreign key constraint
ALTER TABLE CUSTOMER_LLM_PROFILE 
ADD CONSTRAINT FK_LLM_PROFILE_CUSTOMER 
FOREIGN KEY (CUSTOMER_SK) 
REFERENCES CUSTOMER(C_CUSTOMER_SK);

COMMIT;

-- ============================================================================
-- Create LLM Chunks Table
-- ============================================================================
-- This table stores chunks from the LLM-generated profiles
-- Similar to CUSTOMER_CHUNKS but for LLM profiles

-- Drop existing table if it exists
UPDATE COMMAND OPTIONS USING s OFF;
DROP TABLE CUSTOMER_LLM_CHUNKS;
UPDATE COMMAND OPTIONS USING s ON;

CREATE TABLE CUSTOMER_LLM_CHUNKS (
    CHUNK_ID INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1),
    CUSTOMER_SK INTEGER NOT NULL,
    CUSTOMER_ID VARCHAR(16) NOT NULL,
    CHUNK_SEQUENCE INTEGER NOT NULL,
    CHUNK_TYPE VARCHAR(50) NOT NULL,
    CHUNK_TEXT VARCHAR(5000),
    CHUNK_SIZE INTEGER,
    EMBEDDING VECTOR(384, FLOAT32),  -- 384 dimensions for GRANITE30 model
    CREATED_TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (CHUNK_ID)
) IN cust_tbsp;

-- Create indexes for efficient querying
CREATE INDEX IDX_LLM_CHUNKS_CUSTOMER_SK ON CUSTOMER_LLM_CHUNKS(CUSTOMER_SK);
CREATE INDEX IDX_LLM_CHUNKS_CUSTOMER_ID ON CUSTOMER_LLM_CHUNKS(CUSTOMER_ID);
CREATE INDEX IDX_LLM_CHUNKS_TYPE ON CUSTOMER_LLM_CHUNKS(CHUNK_TYPE);

-- Add foreign key constraint
ALTER TABLE CUSTOMER_LLM_CHUNKS
ADD CONSTRAINT FK_LLM_CHUNKS_CUSTOMER
FOREIGN KEY (CUSTOMER_SK)
REFERENCES CUSTOMER(C_CUSTOMER_SK);

COMMIT;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT 'LLM profile table created successfully' AS STATUS FROM SYSIBM.SYSDUMMY1;
SELECT TABNAME, COLNAME, TYPENAME, LENGTH
FROM SYSCAT.COLUMNS
WHERE TABSCHEMA = 'CUSTOMER_SEARCH' AND TABNAME = 'CUSTOMER_LLM_PROFILE'
ORDER BY COLNO;

SELECT 'LLM chunks table created successfully' AS STATUS FROM SYSIBM.SYSDUMMY1;
SELECT TABNAME, COLNAME, TYPENAME, LENGTH
FROM SYSCAT.COLUMNS
WHERE TABSCHEMA = 'CUSTOMER_SEARCH' AND TABNAME = 'CUSTOMER_LLM_CHUNKS'
ORDER BY COLNO;

-- Made with Bob