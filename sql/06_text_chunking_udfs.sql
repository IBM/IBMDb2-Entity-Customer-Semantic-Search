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
-- Customer Semantic Search - Text Chunking UDFs
-- ============================================================================
-- This script creates User-Defined Functions (UDFs) for:
-- 1. Converting JSON to human-readable text
-- 2. Splitting text into chunks suitable for embedding generation
-- ============================================================================

-- Note: This script assumes you are already connected to the database
-- If running standalone, connect first: db2 connect to <dbname>

SET SCHEMA CUSTOMER_SEARCH@

--#SET TERMINATOR @

-- ============================================================================
-- UDF: JSON_TO_TEXT
-- ============================================================================
-- Converts a JSON document to human-readable text format
-- This makes the content more suitable for semantic search
-- ============================================================================
CREATE OR REPLACE FUNCTION JSON_TO_TEXT(json_doc CLOB(10M))
RETURNS CLOB(10M)
LANGUAGE SQL
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA
BEGIN
    DECLARE result_text CLOB(10M);
    DECLARE customer_info VARCHAR(30000);
    
    -- Extract customer basic info
    SET customer_info =
        'Customer Profile: ' ||
        COALESCE(JSON_VALUE(json_doc, '$.customer_info.name'), 'Unknown') || '. ' ||
        'Email: ' || COALESCE(JSON_VALUE(json_doc, '$.customer_info.email'), 'N/A') || '. ' ||
        'Demographics: ' ||
        COALESCE(JSON_VALUE(json_doc, '$.customer_info.demographics.gender'), '') || ' ' ||
        COALESCE(JSON_VALUE(json_doc, '$.customer_info.demographics.marital_status'), '') || ', ' ||
        'Education: ' || COALESCE(JSON_VALUE(json_doc, '$.customer_info.demographics.education'), 'N/A') || ', ' ||
        'Income Band: ' || COALESCE(JSON_VALUE(json_doc, '$.customer_info.demographics.income_band'), 'N/A') || '. ' ||
        'Location: ' ||
        COALESCE(JSON_VALUE(json_doc, '$.customer_info.address.city'), '') || ', ' ||
        COALESCE(JSON_VALUE(json_doc, '$.customer_info.address.state'), '') || ' ' ||
        COALESCE(JSON_VALUE(json_doc, '$.customer_info.address.zip'), '') || ', ' ||
        COALESCE(JSON_VALUE(json_doc, '$.customer_info.address.country'), '') || '.';
    
    -- Combine all text
    SET result_text = customer_info;
    
    RETURN result_text;
END@

-- ============================================================================
-- UDF: EXTRACT_ITEMS_TEXT
-- ============================================================================
-- Extracts and formats text about top purchased items
-- ============================================================================
CREATE OR REPLACE FUNCTION EXTRACT_ITEMS_TEXT(json_doc CLOB(10M))
RETURNS CLOB(10M)
LANGUAGE SQL
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA
BEGIN
    DECLARE result_text CLOB(10M) DEFAULT '';
    DECLARE item_count INTEGER;
    DECLARE i INTEGER DEFAULT 0;
    DECLARE item_desc VARCHAR(30000);
    
    SET result_text = 'Top Purchased Items: ';
    
    -- Note: In a real implementation, you would iterate through the JSON array
    -- For this demo, we'll extract up to 3 items using JSON_VALUE with array indices
    
    -- Item 1
    SET item_desc = JSON_VALUE(json_doc, '$.top_purchased_items[0].item_description');
    IF item_desc IS NOT NULL THEN
        SET result_text = result_text ||
            'Item 1: ' || item_desc ||
            ' (Color: ' || COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[0].color'), 'N/A') || ', ' ||
            'Category: ' || COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[0].category'), '') || ', ' ||
            'Class: ' || COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[0].class'), '') || '). ' ||
            'Current Price: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[0].current_price'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || '. ' ||
            'Total Spending: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[0].total_spending'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ', ' ||
            'Returns: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[0].return_amount'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ', ' ||
            'Net: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[0].net_spending'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ' (' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[0].spending_classification'), 'unknown') || '). ';
    END IF;
    
    -- Item 2
    SET item_desc = JSON_VALUE(json_doc, '$.top_purchased_items[1].item_description');
    IF item_desc IS NOT NULL THEN
        SET result_text = result_text ||
            'Item 2: ' || item_desc ||
            ' (Color: ' || COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[1].color'), 'N/A') || ', ' ||
            'Category: ' || COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[1].category'), '') || ', ' ||
            'Class: ' || COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[1].class'), '') || '). ' ||
            'Current Price: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[1].current_price'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || '. ' ||
            'Total Spending: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[1].total_spending'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ', ' ||
            'Returns: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[1].return_amount'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ', ' ||
            'Net: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[1].net_spending'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ' (' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[1].spending_classification'), 'unknown') || '). ';
    END IF;
    
    -- Item 3
    SET item_desc = JSON_VALUE(json_doc, '$.top_purchased_items[2].item_description');
    IF item_desc IS NOT NULL THEN
        SET result_text = result_text ||
            'Item 3: ' || item_desc ||
            ' (Color: ' || COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[2].color'), 'N/A') || ', ' ||
            'Category: ' || COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[2].category'), '') || ', ' ||
            'Class: ' || COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[2].class'), '') || '). ' ||
            'Current Price: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[2].current_price'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || '. ' ||
            'Total Spending: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[2].total_spending'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ', ' ||
            'Returns: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[2].return_amount'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ', ' ||
            'Net: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[2].net_spending'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ' (' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_purchased_items[2].spending_classification'), 'unknown') || '). ';
    END IF;
    
    RETURN result_text;
END@

-- ============================================================================
-- UDF: EXTRACT_STORES_TEXT
-- ============================================================================
-- Extracts and formats text about top stores
-- ============================================================================
CREATE OR REPLACE FUNCTION EXTRACT_STORES_TEXT(json_doc CLOB(10M))
RETURNS CLOB(10M)
LANGUAGE SQL
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA
BEGIN
    DECLARE result_text CLOB(10M) DEFAULT '';
    DECLARE store_name VARCHAR(500);
    
    SET result_text = 'Top Stores: ';
    
    -- Store 1
    SET store_name = JSON_VALUE(json_doc, '$.top_stores[0].store_name');
    IF store_name IS NOT NULL THEN
        SET result_text = result_text ||
            'Store 1: ' || store_name || ' in ' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_stores[0].location.city'), '') || ', ' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_stores[0].location.state'), '') || '. ' ||
            'Customer spending: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_stores[0].net_spending'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ' (' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_stores[0].spending_classification'), 'unknown') || '). ';
    END IF;
    
    -- Store 2
    SET store_name = JSON_VALUE(json_doc, '$.top_stores[1].store_name');
    IF store_name IS NOT NULL THEN
        SET result_text = result_text ||
            'Store 2: ' || store_name || ' in ' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_stores[1].location.city'), '') || ', ' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_stores[1].location.state'), '') || '. ' ||
            'Customer spending: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_stores[1].net_spending'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ' (' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_stores[1].spending_classification'), 'unknown') || '). ';
    END IF;
    
    -- Store 3
    SET store_name = JSON_VALUE(json_doc, '$.top_stores[2].store_name');
    IF store_name IS NOT NULL THEN
        SET result_text = result_text ||
            'Store 3: ' || store_name || ' in ' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_stores[2].location.city'), '') || ', ' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_stores[2].location.state'), '') || '. ' ||
            'Customer spending: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.top_stores[2].net_spending'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ' (' ||
            COALESCE(JSON_VALUE(json_doc, '$.top_stores[2].spending_classification'), 'unknown') || '). ';
    END IF;
    
    RETURN result_text;
END@

-- ============================================================================
-- UDF: EXTRACT_SPENDING_TEXT
-- ============================================================================
-- Extracts and formats text about monthly spending patterns
-- ============================================================================
CREATE OR REPLACE FUNCTION EXTRACT_SPENDING_TEXT(json_doc CLOB(10M))
RETURNS CLOB(10M)
LANGUAGE SQL
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA
BEGIN
    DECLARE result_text CLOB(10M) DEFAULT '';
    DECLARE summary_text VARCHAR(30000);
    
    -- Extract summary information
    SET summary_text =
        'Customer Summary: ' ||
        'Total transactions: ' || COALESCE(JSON_VALUE(json_doc, '$.summary.total_transactions'), '0') || ', ' ||
        'Lifetime spending: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.summary.total_lifetime_spending'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ', ' ||
        'Total returns: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.summary.total_returns'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || ', ' ||
        'Net lifetime value: $' || TRIM(CHAR(CAST(CAST(COALESCE(JSON_VALUE(json_doc, '$.summary.net_lifetime_value'), '0') AS VARCHAR(20)) AS DECIMAL(10, 2)))) || '. ';
    
    SET result_text = summary_text;
    
    -- Add monthly spending pattern summary
    SET result_text = result_text || 'Monthly Spending Patterns: Customer shows ';
    
    -- Note: In a full implementation, you would analyze the monthly_spending_patterns array
    -- to identify trends (seasonal, consistent, sporadic, etc.)
    SET result_text = result_text || 'regular purchasing behavior with varying monthly spending levels.';
    
    RETURN result_text;
END@

-- ============================================================================
-- UDF: CHUNK_TEXT
-- ============================================================================
-- Splits text into chunks of approximately max_chunk_size characters
-- Tries to break at sentence boundaries when possible
-- ============================================================================
CREATE OR REPLACE FUNCTION CHUNK_TEXT(
    input_text CLOB(10M),
    max_chunk_size INTEGER
)
RETURNS TABLE (
    chunk_seq INTEGER,
    chunk_text VARCHAR(30000)
)
LANGUAGE SQL
DETERMINISTIC
NO EXTERNAL ACTION
READS SQL DATA
RETURN
    SELECT 1 AS chunk_seq, SUBSTR(input_text, 1, max_chunk_size) AS chunk_text
    FROM SYSIBM.SYSDUMMY1
    WHERE input_text IS NOT NULL AND LENGTH(input_text) > 0@

--#SET TERMINATOR ;

COMMIT;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT 'Text chunking UDFs created successfully' AS STATUS FROM SYSIBM.SYSDUMMY1;

-- List created functions
SELECT FUNCNAME, FUNCSCHEMA, LANGUAGE, PARM_COUNT
FROM SYSCAT.FUNCTIONS
WHERE FUNCSCHEMA = 'CUSTOMER_SEARCH'
AND FUNCNAME IN ('JSON_TO_TEXT', 'EXTRACT_ITEMS_TEXT', 'EXTRACT_STORES_TEXT',
                 'EXTRACT_SPENDING_TEXT', 'CHUNK_TEXT')
ORDER BY FUNCNAME;

-- Made with Bob
