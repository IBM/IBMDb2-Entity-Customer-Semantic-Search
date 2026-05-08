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
-- Customer Semantic Search - JSON Document Table
-- ============================================================================
-- This script creates the table to store enriched customer JSON documents
-- Re-entrant: Drops and recreates the table
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- Drop existing table if it exists
UPDATE COMMAND OPTIONS USING s OFF;
DROP TABLE CUSTOMER_JSON_DOCS;
UPDATE COMMAND OPTIONS USING s ON;

-- ============================================================================
-- Create JSON Document Table
-- ============================================================================
-- This table stores the enriched customer profile as a JSON document
-- Each row represents one customer with all their enriched data
CREATE TABLE CUSTOMER_JSON_DOCS (
    CUSTOMER_SK INTEGER NOT NULL PRIMARY KEY,
    CUSTOMER_ID VARCHAR(16) NOT NULL,
    JSON_DOCUMENT CLOB(10M),
    CREATED_TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATED_TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) IN cust_tbsp;

-- Create index on customer_id for quick lookups
CREATE INDEX IDX_CUST_JSON_ID ON CUSTOMER_JSON_DOCS(CUSTOMER_ID);

-- Create index on timestamps for tracking
CREATE INDEX IDX_CUST_JSON_CREATED ON CUSTOMER_JSON_DOCS(CREATED_TIMESTAMP);

COMMIT;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT 'JSON document table created successfully' AS STATUS FROM SYSIBM.SYSDUMMY1;
SELECT TABNAME, COLNAME, TYPENAME, LENGTH 
FROM SYSCAT.COLUMNS 
WHERE TABSCHEMA = 'CUSTOMER_SEARCH' AND TABNAME = 'CUSTOMER_JSON_DOCS'
ORDER BY COLNO;

-- Made with Bob
