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
-- Customer Semantic Search - Sample Queries for Testing
-- ============================================================================
-- This file contains sample queries to test and demonstrate the system
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Query 1: Basic Customer Lookup
-- ============================================================================
-- Verify customer data is loaded correctly
SELECT 
    C_CUSTOMER_SK,
    C_CUSTOMER_ID,
    C_FIRST_NAME,
    C_LAST_NAME,
    C_EMAIL_ADDRESS
FROM CUSTOMER
ORDER BY C_CUSTOMER_SK
FETCH FIRST 5 ROWS ONLY;

-- ============================================================================
-- Query 2: View JSON Documents
-- ============================================================================
-- Check generated JSON documents
SELECT 
    CUSTOMER_SK,
    CUSTOMER_ID,
    SUBSTR(JSON_DOCUMENT, 1, 500) AS JSON_PREVIEW,
    LENGTH(JSON_DOCUMENT) AS JSON_SIZE
FROM CUSTOMER_JSON_DOCS
ORDER BY CUSTOMER_SK
FETCH FIRST 3 ROWS ONLY;

-- ============================================================================
-- Query 3: View Text Chunks
-- ============================================================================
-- Examine generated text chunks
SELECT 
    CHUNK_ID,
    CUSTOMER_SK,
    CHUNK_SEQUENCE,
    CHUNK_TYPE,
    SUBSTR(CHUNK_TEXT, 1, 150) AS CHUNK_PREVIEW,
    CHUNK_SIZE,
    CASE WHEN EMBEDDING IS NOT NULL THEN 'Yes' ELSE 'No' END AS HAS_EMBEDDING
FROM CUSTOMER_TEXT_CHUNKS
WHERE CUSTOMER_SK = 1
ORDER BY CHUNK_SEQUENCE;

-- ============================================================================
-- Query 4: Customer Purchase Summary
-- ============================================================================
-- Analyze customer purchase patterns
SELECT 
    C.C_CUSTOMER_SK,
    C.C_CUSTOMER_ID,
    C.C_FIRST_NAME || ' ' || C.C_LAST_NAME AS CUSTOMER_NAME,
    COUNT(DISTINCT SS.SS_ITEM_SK) AS UNIQUE_ITEMS_PURCHASED,
    COUNT(SS.SS_TICKET_NUMBER) AS TOTAL_TRANSACTIONS,
    SUM(SS.SS_EXT_SALES_PRICE) AS TOTAL_SPENDING,
    AVG(SS.SS_EXT_SALES_PRICE) AS AVG_TRANSACTION_VALUE
FROM CUSTOMER C
INNER JOIN STORE_SALES SS ON C.C_CUSTOMER_SK = SS.SS_CUSTOMER_SK
GROUP BY C.C_CUSTOMER_SK, C.C_CUSTOMER_ID, C.C_FIRST_NAME, C.C_LAST_NAME
ORDER BY TOTAL_SPENDING DESC;

-- ============================================================================
-- Query 5: Top Items by Category
-- ============================================================================
-- Find most popular items by category
SELECT 
    I.I_CATEGORY,
    I.I_ITEM_DESC,
    COUNT(DISTINCT SS.SS_CUSTOMER_SK) AS UNIQUE_CUSTOMERS,
    SUM(SS.SS_QUANTITY) AS TOTAL_QUANTITY_SOLD,
    SUM(SS.SS_EXT_SALES_PRICE) AS TOTAL_REVENUE
FROM ITEM I
INNER JOIN STORE_SALES SS ON I.I_ITEM_SK = SS.SS_ITEM_SK
GROUP BY I.I_CATEGORY, I.I_ITEM_DESC
ORDER BY TOTAL_REVENUE DESC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- Query 6: Store Performance
-- ============================================================================
-- Analyze store performance metrics
SELECT 
    S.S_STORE_NAME,
    S.S_CITY,
    S.S_STATE,
    COUNT(DISTINCT SS.SS_CUSTOMER_SK) AS UNIQUE_CUSTOMERS,
    COUNT(SS.SS_TICKET_NUMBER) AS TOTAL_TRANSACTIONS,
    SUM(SS.SS_EXT_SALES_PRICE) AS TOTAL_REVENUE,
    AVG(SS.SS_EXT_SALES_PRICE) AS AVG_TRANSACTION_VALUE
FROM STORE S
INNER JOIN STORE_SALES SS ON S.S_STORE_SK = SS.SS_STORE_SK
GROUP BY S.S_STORE_NAME, S.S_CITY, S.S_STATE
ORDER BY TOTAL_REVENUE DESC;

-- ============================================================================
-- Query 7: Customer Segmentation by Spending
-- ============================================================================
-- Segment customers by spending levels
WITH CUSTOMER_SPENDING AS (
    SELECT 
        SS.SS_CUSTOMER_SK,
        SUM(SS.SS_EXT_SALES_PRICE) AS TOTAL_SPENDING
    FROM STORE_SALES SS
    GROUP BY SS.SS_CUSTOMER_SK
)
SELECT 
    CASE 
        WHEN TOTAL_SPENDING >= 500 THEN 'High Value'
        WHEN TOTAL_SPENDING >= 200 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS CUSTOMER_SEGMENT,
    COUNT(*) AS CUSTOMER_COUNT,
    AVG(TOTAL_SPENDING) AS AVG_SPENDING,
    MIN(TOTAL_SPENDING) AS MIN_SPENDING,
    MAX(TOTAL_SPENDING) AS MAX_SPENDING
FROM CUSTOMER_SPENDING
GROUP BY 
    CASE 
        WHEN TOTAL_SPENDING >= 500 THEN 'High Value'
        WHEN TOTAL_SPENDING >= 200 THEN 'Medium Value'
        ELSE 'Low Value'
    END
ORDER BY AVG_SPENDING DESC;

-- ============================================================================
-- Query 8: Return Rate Analysis
-- ============================================================================
-- Analyze return patterns
SELECT 
    C.C_CUSTOMER_SK,
    C.C_CUSTOMER_ID,
    C.C_FIRST_NAME || ' ' || C.C_LAST_NAME AS CUSTOMER_NAME,
    COUNT(DISTINCT SS.SS_TICKET_NUMBER) AS TOTAL_PURCHASES,
    COUNT(DISTINCT SR.SR_TICKET_NUMBER) AS TOTAL_RETURNS,
    CASE 
        WHEN COUNT(DISTINCT SS.SS_TICKET_NUMBER) > 0 
        THEN DECIMAL(COUNT(DISTINCT SR.SR_TICKET_NUMBER), 10, 2) / 
             DECIMAL(COUNT(DISTINCT SS.SS_TICKET_NUMBER), 10, 2) * 100
        ELSE 0
    END AS RETURN_RATE_PCT,
    SUM(SS.SS_EXT_SALES_PRICE) AS TOTAL_SALES,
    COALESCE(SUM(SR.SR_RETURN_AMT), 0) AS TOTAL_RETURNS_AMT
FROM CUSTOMER C
INNER JOIN STORE_SALES SS ON C.C_CUSTOMER_SK = SS.SS_CUSTOMER_SK
LEFT JOIN STORE_RETURNS SR ON SS.SS_ITEM_SK = SR.SR_ITEM_SK 
    AND SS.SS_TICKET_NUMBER = SR.SR_TICKET_NUMBER
GROUP BY C.C_CUSTOMER_SK, C.C_CUSTOMER_ID, C.C_FIRST_NAME, C.C_LAST_NAME
HAVING COUNT(DISTINCT SR.SR_TICKET_NUMBER) > 0
ORDER BY RETURN_RATE_PCT DESC;

-- ============================================================================
-- Query 9: Monthly Sales Trend
-- ============================================================================
-- Analyze sales trends over time
SELECT 
    D.D_YEAR,
    D.D_MOY AS MONTH,
    COUNT(DISTINCT SS.SS_CUSTOMER_SK) AS UNIQUE_CUSTOMERS,
    COUNT(SS.SS_TICKET_NUMBER) AS TOTAL_TRANSACTIONS,
    SUM(SS.SS_EXT_SALES_PRICE) AS TOTAL_REVENUE,
    AVG(SS.SS_EXT_SALES_PRICE) AS AVG_TRANSACTION_VALUE
FROM STORE_SALES SS
INNER JOIN DATE_DIM D ON SS.SS_SOLD_DATE_SK = D.D_DATE_SK
GROUP BY D.D_YEAR, D.D_MOY
ORDER BY D.D_YEAR, D.D_MOY;

-- ============================================================================
-- Query 10: Customer Lifetime Value
-- ============================================================================
-- Calculate customer lifetime value metrics
SELECT 
    C.C_CUSTOMER_SK,
    C.C_CUSTOMER_ID,
    C.C_FIRST_NAME || ' ' || C.C_LAST_NAME AS CUSTOMER_NAME,
    MIN(D.D_DATE) AS FIRST_PURCHASE_DATE,
    MAX(D.D_DATE) AS LAST_PURCHASE_DATE,
    DAYS(MAX(D.D_DATE)) - DAYS(MIN(D.D_DATE)) AS CUSTOMER_TENURE_DAYS,
    COUNT(DISTINCT SS.SS_TICKET_NUMBER) AS TOTAL_TRANSACTIONS,
    SUM(SS.SS_EXT_SALES_PRICE) AS TOTAL_REVENUE,
    COALESCE(SUM(SR.SR_RETURN_AMT), 0) AS TOTAL_RETURNS,
    SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) AS NET_REVENUE,
    CASE 
        WHEN DAYS(MAX(D.D_DATE)) - DAYS(MIN(D.D_DATE)) > 0
        THEN (SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0)) / 
             (DAYS(MAX(D.D_DATE)) - DAYS(MIN(D.D_DATE)))
        ELSE 0
    END AS DAILY_VALUE
FROM CUSTOMER C
INNER JOIN STORE_SALES SS ON C.C_CUSTOMER_SK = SS.SS_CUSTOMER_SK
INNER JOIN DATE_DIM D ON SS.SS_SOLD_DATE_SK = D.D_DATE_SK
LEFT JOIN STORE_RETURNS SR ON SS.SS_ITEM_SK = SR.SR_ITEM_SK 
    AND SS.SS_TICKET_NUMBER = SR.SR_TICKET_NUMBER
GROUP BY C.C_CUSTOMER_SK, C.C_CUSTOMER_ID, C.C_FIRST_NAME, C.C_LAST_NAME
ORDER BY NET_REVENUE DESC;

-- ============================================================================
-- Query 11: Test Semantic Search (requires embeddings)
-- ============================================================================
-- Simple semantic search test
-- Note: Replace 'embedding_model' with your actual model name
-- Uncomment when embeddings are generated:

-- WITH QUERY_EMBEDDING AS (
--     SELECT TO_EMBEDDING(
--         'Customer who buys electronics' USING GRANITE30
--     ) AS QUERY_VECTOR
--     FROM SYSIBM.SYSDUMMY1
-- )
-- SELECT 
--     C.CUSTOMER_SK,
--     C.CUSTOMER_ID,
--     C.CHUNK_TYPE,
--     SUBSTR(C.CHUNK_TEXT, 1, 100) AS PREVIEW,
--     VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS SIMILARITY
-- FROM CUSTOMER_TEXT_CHUNKS C
-- CROSS JOIN QUERY_EMBEDDING Q
-- WHERE C.EMBEDDING IS NOT NULL
-- ORDER BY SIMILARITY ASC
-- FETCH FIRST 5 ROWS ONLY;

-- ============================================================================
-- Query 12: System Health Check
-- ============================================================================
-- Verify all components are working
SELECT 'Customers' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM CUSTOMER
UNION ALL
SELECT 'Items', COUNT(*) FROM ITEM
UNION ALL
SELECT 'Stores', COUNT(*) FROM STORE
UNION ALL
SELECT 'Sales', COUNT(*) FROM STORE_SALES
UNION ALL
SELECT 'Returns', COUNT(*) FROM STORE_RETURNS
UNION ALL
SELECT 'JSON Documents', COUNT(*) FROM CUSTOMER_JSON_DOCS
UNION ALL
SELECT 'Text Chunks', COUNT(*) FROM CUSTOMER_TEXT_CHUNKS
UNION ALL
SELECT 'Chunks with Embeddings', COUNT(*) FROM CUSTOMER_TEXT_CHUNKS WHERE EMBEDDING IS NOT NULL;

-- Made with Bob
