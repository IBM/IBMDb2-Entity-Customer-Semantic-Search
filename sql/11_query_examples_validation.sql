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
-- Customer Semantic Search - Query Examples Validation
-- ============================================================================
-- This script contains all query examples from docs/query_examples.md
-- Use this to validate that all documented queries work correctly
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Basic Semantic Search
-- ============================================================================

-- OUTPUT: ============================================================================
-- OUTPUT: Example 1: Find Customers by Shopping Behavior
-- OUTPUT: Find customers who frequently buy electronics
-- OUTPUT: ============================================================================

WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who frequently purchases electronics and technology products'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT 
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    C.CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 200) AS CHUNK_PREVIEW,
    VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS SIMILARITY_SCORE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
ORDER BY SIMILARITY_SCORE ASC
FETCH FIRST 10 ROWS ONLY;

-- OUTPUT: ============================================================================
-- OUTPUT: Example 2: Find High-Value Customers
-- OUTPUT: ============================================================================

WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Loyal customer with high lifetime value and regular monthly spending patterns'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    SUBSTR(C.CHUNK_TEXT, 1, 150) AS PREVIEW,
    VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS SIMILARITY
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
AND C.CHUNK_TYPE = 'spending_summary'
ORDER BY SIMILARITY ASC
FETCH APPROX FIRST 15 ROWS ONLY;

-- ============================================================================
-- Customer Discovery
-- ============================================================================

-- OUTPUT: ============================================================================
-- OUTPUT: Example 3: Find Customers with Specific Interests
-- OUTPUT: Find customers interested in fitness and wellness
-- OUTPUT: ============================================================================

WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer interested in fitness, health, wellness, and sports products'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT 
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    C.CHUNK_TYPE,
    SUBSTR(C.CHUNK_TEXT, 1, 200) AS PREVIEW,
    VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS SIMILARITY
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
AND C.CHUNK_TYPE = 'top_items'
AND VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) < 40
ORDER BY SIMILARITY ASC
FETCH FIRST 20 ROWS ONLY;

-- OUTPUT: ============================================================================
-- OUTPUT: Example 4: Find Customers by Shopping Location Preference
-- OUTPUT: ============================================================================

WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who shops at large stores in urban downtown areas with many employees'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT 
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    SUBSTR(C.CHUNK_TEXT, 1, 200) AS PREVIEW,
    VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS SIMILARITY
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
AND C.CHUNK_TYPE = 'top_stores'
ORDER BY SIMILARITY ASC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- Filtered Search
-- ============================================================================

-- OUTPUT: ============================================================================
-- OUTPUT: Example 5: Semantic Search with Geographic Filter
-- OUTPUT: Find fitness enthusiasts in Illinois
-- OUTPUT: ============================================================================

WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who buys fitness equipment, workout clothes, and health products'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT 
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    CUST.C_FIRST_NAME || ' ' || CUST.C_LAST_NAME AS NAME,
    CA.CA_CITY,
    CA.CA_STATE,
    SUBSTR(C.CHUNK_TEXT, 1, 150) AS PREVIEW,
    VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS SIMILARITY
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
INNER JOIN CUSTOMER CUST ON C.CUSTOMER_SK = CUST.C_CUSTOMER_SK
INNER JOIN CUSTOMER_ADDRESS CA ON CUST.C_CURRENT_ADDR_SK = CA.CA_ADDRESS_SK
WHERE C.EMBEDDING IS NOT NULL
AND CA.CA_STATE = 'IL'
AND C.CHUNK_TYPE = 'top_items'
ORDER BY SIMILARITY ASC
FETCH FIRST 15 ROWS ONLY;

-- OUTPUT: ============================================================================
-- OUTPUT: Example 6: Semantic Search with Demographic Filter
-- OUTPUT: Find tech-savvy customers with college education
-- OUTPUT: ============================================================================

WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who purchases technology, electronics, and smart devices'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT 
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    CD.CD_EDUCATION_STATUS,
    CD.CD_GENDER,
    SUBSTR(C.CHUNK_TEXT, 1, 150) AS PREVIEW,
    VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS SIMILARITY
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
INNER JOIN CUSTOMER CUST ON C.CUSTOMER_SK = CUST.C_CUSTOMER_SK
INNER JOIN CUSTOMER_DEMOGRAPHICS CD ON CUST.C_CURRENT_CDEMO_SK = CD.CD_DEMO_SK
WHERE C.EMBEDDING IS NOT NULL
AND CD.CD_EDUCATION_STATUS IN ('College', 'Bachelor', 'Graduate')
ORDER BY SIMILARITY ASC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- Similar Customer Finding
-- ============================================================================

-- OUTPUT: ============================================================================
-- OUTPUT: Example 7: Find Customers Similar to a Specific Customer
-- OUTPUT: Find customers similar to customer #1
-- OUTPUT: ============================================================================

SELECT 
    C2.CUSTOMER_SK AS SIMILAR_CUSTOMER,
    C2.CUSTOMER_ID,
    C2.CHUNK_TYPE,
    SUBSTR(C2.CHUNK_TEXT, 1, 150) AS PREVIEW,
    AVG(VECTOR_DISTANCE(C1.EMBEDDING, C2.EMBEDDING, EUCLIDEAN)) AS AVG_SIMILARITY
FROM CUSTOMER_TEXT_CHUNKS C1
INNER JOIN CUSTOMER_TEXT_CHUNKS C2 
    ON C1.CUSTOMER_SK != C2.CUSTOMER_SK
    AND C1.CHUNK_TYPE = C2.CHUNK_TYPE
WHERE C1.CUSTOMER_SK = 1
AND C1.EMBEDDING IS NOT NULL
AND C2.EMBEDDING IS NOT NULL
GROUP BY C2.CUSTOMER_SK, C2.CUSTOMER_ID, C2.CHUNK_TYPE, C2.CHUNK_TEXT
ORDER BY AVG_SIMILARITY ASC
FETCH FIRST 10 ROWS ONLY;

-- OUTPUT: ============================================================================
-- OUTPUT: Example 8: Find Similar Customers with Full Profile
-- OUTPUT: ============================================================================

WITH SIMILAR_CUSTOMERS AS (
    SELECT 
        C2.CUSTOMER_SK,
        AVG(VECTOR_DISTANCE(C1.EMBEDDING, C2.EMBEDDING, EUCLIDEAN)) AS SIMILARITY
    FROM CUSTOMER_TEXT_CHUNKS C1
    INNER JOIN CUSTOMER_TEXT_CHUNKS C2 ON C1.CUSTOMER_SK != C2.CUSTOMER_SK
    WHERE C1.CUSTOMER_SK = 1
    AND C1.EMBEDDING IS NOT NULL
    AND C2.EMBEDDING IS NOT NULL
    GROUP BY C2.CUSTOMER_SK
    ORDER BY SIMILARITY ASC
    FETCH FIRST 5 ROWS ONLY
)
SELECT 
    SC.CUSTOMER_SK,
    CUST.C_CUSTOMER_ID,
    CUST.C_FIRST_NAME || ' ' || CUST.C_LAST_NAME AS NAME,
    CUST.C_EMAIL_ADDRESS,
    CA.CA_CITY || ', ' || CA.CA_STATE AS LOCATION,
    SC.SIMILARITY,
    JSON_VALUE(CJD.JSON_DOCUMENT, '$.summary.net_lifetime_value') AS LIFETIME_VALUE
FROM SIMILAR_CUSTOMERS SC
INNER JOIN CUSTOMER CUST ON SC.CUSTOMER_SK = CUST.C_CUSTOMER_SK
LEFT JOIN CUSTOMER_ADDRESS CA ON CUST.C_CURRENT_ADDR_SK = CA.CA_ADDRESS_SK
LEFT JOIN CUSTOMER_JSON_DOCS CJD ON SC.CUSTOMER_SK = CJD.CUSTOMER_SK
ORDER BY SC.SIMILARITY;

-- ============================================================================
-- Multi-Aspect Search
-- ============================================================================

-- OUTPUT: ============================================================================
-- OUTPUT: Example 9: Find Customers Matching Multiple Criteria
-- OUTPUT: ============================================================================

WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Customer who returns items frequently and shops at multiple different stores'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT 
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    COUNT(DISTINCT C.CHUNK_TYPE) AS MATCHING_ASPECTS,
    MIN(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN)) AS BEST_MATCH,
    AVG(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN)) AS AVG_MATCH,
    LISTAGG(C.CHUNK_TYPE, ', ') AS MATCHED_TYPES
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE C.EMBEDDING IS NOT NULL
AND VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) < 50
GROUP BY C.CUSTOMER_SK, C.CUSTOMER_ID
HAVING COUNT(DISTINCT C.CHUNK_TYPE) >= 2
ORDER BY BEST_MATCH ASC
FETCH FIRST 10 ROWS ONLY;

-- OUTPUT: ============================================================================
-- OUTPUT: Example 10: Comprehensive Customer Profile Match
-- OUTPUT: ============================================================================

WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING(
        'Middle-aged professional with high income who shops regularly at premium stores and buys quality electronics and clothing'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
),
CUSTOMER_SCORES AS (
    SELECT 
        C.CUSTOMER_SK,
        C.CUSTOMER_ID,
        AVG(VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN)) AS OVERALL_SIMILARITY,
        MIN(CASE WHEN C.CHUNK_TYPE = 'customer_info' 
            THEN VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) END) AS INFO_SIMILARITY,
        MIN(CASE WHEN C.CHUNK_TYPE = 'top_items' 
            THEN VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) END) AS ITEMS_SIMILARITY,
        MIN(CASE WHEN C.CHUNK_TYPE = 'top_stores' 
            THEN VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) END) AS STORES_SIMILARITY
    FROM CUSTOMER_TEXT_CHUNKS C
    CROSS JOIN QUERY_EMBEDDING Q
    WHERE C.EMBEDDING IS NOT NULL
    GROUP BY C.CUSTOMER_SK, C.CUSTOMER_ID
)
SELECT 
    CS.*,
    CUST.C_FIRST_NAME || ' ' || CUST.C_LAST_NAME AS NAME,
    CD.CD_EDUCATION_STATUS,
    JSON_VALUE(CJD.JSON_DOCUMENT, '$.summary.net_lifetime_value') AS LIFETIME_VALUE
FROM CUSTOMER_SCORES CS
INNER JOIN CUSTOMER CUST ON CS.CUSTOMER_SK = CUST.C_CUSTOMER_SK
LEFT JOIN CUSTOMER_DEMOGRAPHICS CD ON CUST.C_CURRENT_CDEMO_SK = CD.CD_DEMO_SK
LEFT JOIN CUSTOMER_JSON_DOCS CJD ON CS.CUSTOMER_SK = CJD.CUSTOMER_SK
ORDER BY CS.OVERALL_SIMILARITY ASC
FETCH FIRST 10 ROWS ONLY;

-- ============================================================================
-- Business Intelligence Queries
-- ============================================================================

-- OUTPUT: ============================================================================
-- OUTPUT: Example 11: Customer Segmentation for Marketing
-- OUTPUT: ============================================================================

WITH SEGMENT_QUERIES AS (
    SELECT 'Budget Shoppers' AS SEGMENT,
           TO_EMBEDDING('Customer who looks for deals, discounts, and low prices' USING GRANITE30) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT 'Premium Buyers',
           TO_EMBEDDING('Customer who buys high-end premium products and luxury items' USING GRANITE30)
    FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT 'Tech Enthusiasts',
           TO_EMBEDDING('Customer who purchases latest technology and electronic gadgets' USING GRANITE30)
    FROM SYSIBM.SYSDUMMY1
)
SELECT 
    SQ.SEGMENT,
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    VECTOR_DISTANCE(C.EMBEDDING, SQ.QUERY_VECTOR, EUCLIDEAN) AS SEGMENT_SCORE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN SEGMENT_QUERIES SQ
WHERE C.EMBEDDING IS NOT NULL
AND C.CHUNK_TYPE = 'top_items'
AND VECTOR_DISTANCE(C.EMBEDDING, SQ.QUERY_VECTOR, EUCLIDEAN) < 40
ORDER BY SQ.SEGMENT, SEGMENT_SCORE ASC;

-- OUTPUT: ============================================================================
-- OUTPUT: Example 12: Churn Risk Identification
-- OUTPUT: ============================================================================

WITH CHURN_PATTERN AS (
    SELECT TO_EMBEDDING(
        'Customer with decreasing purchase frequency, increasing returns, and shopping at fewer stores'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT 
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    CUST.C_EMAIL_ADDRESS,
    AVG(VECTOR_DISTANCE(C.EMBEDDING, CP.QUERY_VECTOR, EUCLIDEAN)) AS CHURN_RISK_SCORE,
    JSON_VALUE(CJD.JSON_DOCUMENT, '$.summary.total_transactions') AS TOTAL_TRANSACTIONS,
    JSON_VALUE(CJD.JSON_DOCUMENT, '$.summary.total_returns') AS TOTAL_RETURNS
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN CHURN_PATTERN CP
INNER JOIN CUSTOMER CUST ON C.CUSTOMER_SK = CUST.C_CUSTOMER_SK
LEFT JOIN CUSTOMER_JSON_DOCS CJD ON C.CUSTOMER_SK = CJD.CUSTOMER_SK
WHERE C.EMBEDDING IS NOT NULL
GROUP BY C.CUSTOMER_SK, C.CUSTOMER_ID, CUST.C_EMAIL_ADDRESS, 
         CJD.JSON_DOCUMENT
HAVING AVG(VECTOR_DISTANCE(C.EMBEDDING, CP.QUERY_VECTOR, EUCLIDEAN)) < 45
ORDER BY CHURN_RISK_SCORE ASC
FETCH FIRST 20 ROWS ONLY;

-- ============================================================================
-- Advanced Use Cases
-- ============================================================================

-- OUTPUT: ============================================================================
-- OUTPUT: Example 13: Cross-Sell Recommendations
-- OUTPUT: ============================================================================

WITH PRODUCT_PROFILE AS (
    SELECT TO_EMBEDDING(
        'Customer who would be interested in smart home devices, IoT products, and home automation'
        USING GRANITE30
    ) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT 
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    CUST.C_EMAIL_ADDRESS,
    SUBSTR(C.CHUNK_TEXT, 1, 150) AS CURRENT_INTERESTS,
    VECTOR_DISTANCE(C.EMBEDDING, PP.QUERY_VECTOR, EUCLIDEAN) AS RECOMMENDATION_SCORE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN PRODUCT_PROFILE PP
INNER JOIN CUSTOMER CUST ON C.CUSTOMER_SK = CUST.C_CUSTOMER_SK
WHERE C.EMBEDDING IS NOT NULL
AND C.CHUNK_TYPE = 'top_items'
AND VECTOR_DISTANCE(C.EMBEDDING, PP.QUERY_VECTOR, EUCLIDEAN) < 50
-- Exclude customers who already bought smart home products
AND C.CHUNK_TEXT NOT LIKE '%smart%'
AND C.CHUNK_TEXT NOT LIKE '%IoT%'
ORDER BY RECOMMENDATION_SCORE ASC
FETCH FIRST 25 ROWS ONLY;

-- OUTPUT: ============================================================================
-- OUTPUT: Example 14: Lookalike Audience for Best Customers
-- OUTPUT: ============================================================================

WITH TOP_CUSTOMERS AS (
    SELECT C.C_CUSTOMER_SK
    FROM CUSTOMER C
    INNER JOIN STORE_SALES SS ON C.C_CUSTOMER_SK = SS.SS_CUSTOMER_SK
    GROUP BY C.C_CUSTOMER_SK
    HAVING SUM(SS.SS_EXT_SALES_PRICE) > (
        SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY TOTAL_SPENDING)
        FROM (
            SELECT SUM(SS2.SS_EXT_SALES_PRICE) AS TOTAL_SPENDING
            FROM STORE_SALES SS2
            GROUP BY SS2.SS_CUSTOMER_SK
        )
    )
),
TOP_CUSTOMER_EMBEDDINGS AS (
    SELECT EMBEDDING
    FROM CUSTOMER_TEXT_CHUNKS
    WHERE CUSTOMER_SK IN (SELECT C_CUSTOMER_SK FROM TOP_CUSTOMERS)
    AND EMBEDDING IS NOT NULL
)
SELECT 
    C.CUSTOMER_SK,
    C.CUSTOMER_ID,
    AVG(
        (SELECT MIN(VECTOR_DISTANCE(C.EMBEDDING, TCE.EMBEDDING, EUCLIDEAN))
         FROM TOP_CUSTOMER_EMBEDDINGS TCE)
    ) AS SIMILARITY_TO_TOP_CUSTOMERS
FROM CUSTOMER_TEXT_CHUNKS C
WHERE C.EMBEDDING IS NOT NULL
AND C.CUSTOMER_SK NOT IN (SELECT C_CUSTOMER_SK FROM TOP_CUSTOMERS)
GROUP BY C.CUSTOMER_SK, C.CUSTOMER_ID
ORDER BY SIMILARITY_TO_TOP_CUSTOMERS ASC
FETCH FIRST 50 ROWS ONLY;

-- OUTPUT: ============================================================================
-- OUTPUT: Example 15: Batch Customer Matching
-- OUTPUT: ============================================================================

WITH TARGET_CUSTOMERS AS (
    SELECT C_CUSTOMER_SK, C_CUSTOMER_ID
    FROM CUSTOMER
    WHERE C_CUSTOMER_SK IN (1, 2, 3, 4, 5)
)
SELECT 
    TC.C_CUSTOMER_SK AS SOURCE_CUSTOMER,
    TC.C_CUSTOMER_ID AS SOURCE_ID,
    C2.CUSTOMER_SK AS SIMILAR_CUSTOMER,
    C2.CUSTOMER_ID AS SIMILAR_ID,
    AVG(VECTOR_DISTANCE(C1.EMBEDDING, C2.EMBEDDING, EUCLIDEAN)) AS SIMILARITY
FROM TARGET_CUSTOMERS TC
INNER JOIN CUSTOMER_TEXT_CHUNKS C1 ON TC.C_CUSTOMER_SK = C1.CUSTOMER_SK
INNER JOIN CUSTOMER_TEXT_CHUNKS C2 
    ON C1.CUSTOMER_SK != C2.CUSTOMER_SK
    AND C1.CHUNK_TYPE = C2.CHUNK_TYPE
WHERE C1.EMBEDDING IS NOT NULL
AND C2.EMBEDDING IS NOT NULL
GROUP BY TC.C_CUSTOMER_SK, TC.C_CUSTOMER_ID, C2.CUSTOMER_SK, C2.CUSTOMER_ID
HAVING AVG(VECTOR_DISTANCE(C1.EMBEDDING, C2.EMBEDDING, EUCLIDEAN)) < 30
ORDER BY TC.C_CUSTOMER_SK, SIMILARITY ASC;

-- ============================================================================
-- Validation Complete
-- ============================================================================
-- OUTPUT: ============================================================================
-- OUTPUT: All query examples from docs/query_examples.md have been executed
-- OUTPUT: Review the results above to verify all queries work correctly
-- OUTPUT: ============================================================================

-- Made with Bob
