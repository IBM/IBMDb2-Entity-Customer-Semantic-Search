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
-- Customer Semantic Search - JSON Document Generation
-- ============================================================================
-- This script generates enriched customer JSON documents from relational data
-- Uses Db2's native JSON functions (JSON_OBJECT, JSON_ARRAY, etc.)
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Generate JSON Documents for Each Customer
-- ============================================================================
-- This creates a comprehensive JSON document for each customer including:
-- 1. Basic customer information
-- 2. Demographics
-- 3. Top 3 purchased items with details
-- 4. Top 3 stores with spending patterns
-- 5. Monthly spending patterns

INSERT INTO CUSTOMER_JSON_DOCS (CUSTOMER_SK, CUSTOMER_ID, JSON_DOCUMENT)
WITH 
-- Get top 3 purchased items per customer
TOP_ITEMS AS (
    SELECT 
        SS.SS_CUSTOMER_SK,
        I.I_ITEM_SK,
        I.I_ITEM_DESC,
        I.I_CATEGORY,
        I.I_CLASS,
        I.I_COLOR,
        I.I_CURRENT_PRICE,
        SUM(SS.SS_EXT_SALES_PRICE) AS TOTAL_SPENDING,
        COALESCE(SUM(SR.SR_RETURN_AMT), 0) AS RETURN_AMOUNT,
        CASE 
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 300 THEN 'very_high'
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 150 THEN 'high'
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 50 THEN 'medium'
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 0 THEN 'low'
            ELSE 'very_low'
        END AS SPENDING_CLASSIFICATION,
        ROW_NUMBER() OVER (PARTITION BY SS.SS_CUSTOMER_SK ORDER BY SUM(SS.SS_EXT_SALES_PRICE) DESC) AS ITEM_RANK
    FROM STORE_SALES SS
    INNER JOIN ITEM I ON SS.SS_ITEM_SK = I.I_ITEM_SK
    LEFT JOIN STORE_RETURNS SR ON SS.SS_ITEM_SK = SR.SR_ITEM_SK 
        AND SS.SS_TICKET_NUMBER = SR.SR_TICKET_NUMBER
    GROUP BY SS.SS_CUSTOMER_SK, I.I_ITEM_SK, I.I_ITEM_DESC, I.I_CATEGORY, 
             I.I_CLASS, I.I_COLOR, I.I_CURRENT_PRICE
),
-- Get top 3 stores per customer
TOP_STORES AS (
    SELECT 
        SS.SS_CUSTOMER_SK,
        S.S_STORE_SK,
        S.S_STORE_NAME,
        S.S_NUMBER_EMPLOYEES,
        S.S_DIVISION_NAME,
        S.S_COMPANY_NAME,
        S.S_CITY,
        S.S_COUNTY,
        S.S_STATE,
        S.S_ZIP,
        S.S_COUNTRY,
        SUM(SS.SS_EXT_SALES_PRICE) AS CUSTOMER_SPENDING,
        COALESCE(SUM(SR.SR_RETURN_AMT), 0) AS CUSTOMER_RETURNS,
        CASE 
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 400 THEN 'very_high'
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 200 THEN 'high'
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 100 THEN 'medium'
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 0 THEN 'low'
            ELSE 'very_low'
        END AS SPENDING_CLASSIFICATION,
        ROW_NUMBER() OVER (PARTITION BY SS.SS_CUSTOMER_SK ORDER BY SUM(SS.SS_EXT_SALES_PRICE) DESC) AS STORE_RANK
    FROM STORE_SALES SS
    INNER JOIN STORE S ON SS.SS_STORE_SK = S.S_STORE_SK
    LEFT JOIN STORE_RETURNS SR ON SS.SS_STORE_SK = SR.SR_STORE_SK 
        AND SS.SS_TICKET_NUMBER = SR.SR_TICKET_NUMBER
        AND SS.SS_CUSTOMER_SK = SR.SR_CUSTOMER_SK
    GROUP BY SS.SS_CUSTOMER_SK, S.S_STORE_SK, S.S_STORE_NAME, S.S_NUMBER_EMPLOYEES,
             S.S_DIVISION_NAME, S.S_COMPANY_NAME, S.S_CITY, S.S_COUNTY, 
             S.S_STATE, S.S_ZIP, S.S_COUNTRY
),
-- Get monthly spending patterns
MONTHLY_SPENDING AS (
    SELECT 
        SS.SS_CUSTOMER_SK,
        D.D_YEAR,
        D.D_MOY AS MONTH,
        SUM(SS.SS_EXT_SALES_PRICE) AS TOTAL_SPENDING,
        COALESCE(SUM(SR.SR_RETURN_AMT), 0) AS TOTAL_RETURNS,
        SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) AS NET_SPENDING,
        CASE 
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 1000 THEN 'very high'
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 300 THEN 'high'
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 100 THEN 'medium'
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 25 THEN 'low'
            WHEN SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(SUM(SR.SR_RETURN_AMT), 0) > 1 THEN 'very low'
            ELSE 'low'
        END AS SPENDING_RANGE
    FROM STORE_SALES SS
    INNER JOIN DATE_DIM D ON SS.SS_SOLD_DATE_SK = D.D_DATE_SK
    LEFT JOIN STORE_RETURNS SR ON SS.SS_ITEM_SK = SR.SR_ITEM_SK 
        AND SS.SS_TICKET_NUMBER = SR.SR_TICKET_NUMBER
        AND SS.SS_CUSTOMER_SK = SR.SR_CUSTOMER_SK
    GROUP BY SS.SS_CUSTOMER_SK, D.D_YEAR, D.D_MOY
)
SELECT 
    C.C_CUSTOMER_SK,
    C.C_CUSTOMER_ID,
    JSON_OBJECT(
        'customer_id' VALUE C.C_CUSTOMER_SK,
        'customer_info' VALUE JSON_OBJECT(
            'customer_id_string' VALUE C.C_CUSTOMER_ID,
            'name' VALUE TRIM(COALESCE(C.C_SALUTATION, '') || ' ' ||
                             COALESCE(C.C_FIRST_NAME, '') || ' ' ||
                             COALESCE(C.C_LAST_NAME, '')),
            'email' VALUE C.C_EMAIL_ADDRESS,
            'preferred_customer' VALUE C.C_PREFERRED_CUST_FLAG,
            'demographics' VALUE JSON_OBJECT(
                'birth_year' VALUE C.C_BIRTH_YEAR,
                'birth_month' VALUE C.C_BIRTH_MONTH,
                'birth_day' VALUE C.C_BIRTH_DAY,
                'gender' VALUE CD.CD_GENDER,
                'marital_status' VALUE CD.CD_MARITAL_STATUS,
                'education' VALUE CD.CD_EDUCATION_STATUS,
                'credit_rating' VALUE CD.CD_CREDIT_RATING,
                'dependents' VALUE CD.CD_DEP_COUNT,
                'income_band' VALUE CASE
                    WHEN IB.IB_LOWER_BOUND IS NOT NULL THEN
                        '$' || CAST(IB.IB_LOWER_BOUND AS VARCHAR(10)) || '-$' ||
                        CAST(IB.IB_UPPER_BOUND AS VARCHAR(10))
                    ELSE 'Unknown'
                END
            ) FORMAT JSON,
            'address' VALUE JSON_OBJECT(
                'street' VALUE TRIM(COALESCE(CA.CA_STREET_NUMBER, '') || ' ' ||
                                   COALESCE(CA.CA_STREET_NAME, '') || ' ' ||
                                   COALESCE(CA.CA_STREET_TYPE, '')),
                'suite' VALUE CA.CA_SUITE_NUMBER,
                'city' VALUE CA.CA_CITY,
                'county' VALUE CA.CA_COUNTY,
                'state' VALUE CA.CA_STATE,
                'zip' VALUE CA.CA_ZIP,
                'country' VALUE CA.CA_COUNTRY,
                'location_type' VALUE CA.CA_LOCATION_TYPE
            ) FORMAT JSON
        ) FORMAT JSON,
        'top_purchased_items' VALUE COALESCE((
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'rank' VALUE TI.ITEM_RANK,
                    'item_description' VALUE TI.I_ITEM_DESC,
                    'category' VALUE TI.I_CATEGORY,
                    'class' VALUE TI.I_CLASS,
                    'color' VALUE TI.I_COLOR,
                    'current_price' VALUE TI.I_CURRENT_PRICE,
                    'total_spending' VALUE DECIMAL(TI.TOTAL_SPENDING, 10, 2),
                    'return_amount' VALUE DECIMAL(TI.RETURN_AMOUNT, 10, 2),
                    'net_spending' VALUE DECIMAL(TI.TOTAL_SPENDING - TI.RETURN_AMOUNT, 10, 2),
                    'spending_classification' VALUE TI.SPENDING_CLASSIFICATION
                ) FORMAT JSON
            )
            FROM TOP_ITEMS TI
            WHERE TI.SS_CUSTOMER_SK = C.C_CUSTOMER_SK
            AND TI.ITEM_RANK <= 3
        ), JSON_ARRAY()) FORMAT JSON,
        'top_stores' VALUE COALESCE((
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'rank' VALUE TS.STORE_RANK,
                    'store_name' VALUE TS.S_STORE_NAME,
                    'store_details' VALUE JSON_OBJECT(
                        'employees' VALUE TS.S_NUMBER_EMPLOYEES,
                        'division' VALUE TS.S_DIVISION_NAME,
                        'company' VALUE TS.S_COMPANY_NAME
                    ) FORMAT JSON,
                    'location' VALUE JSON_OBJECT(
                        'city' VALUE TS.S_CITY,
                        'county' VALUE TS.S_COUNTY,
                        'state' VALUE TS.S_STATE,
                        'zip' VALUE TS.S_ZIP,
                        'country' VALUE TS.S_COUNTRY
                    ) FORMAT JSON,
                    'customer_spending' VALUE DECIMAL(TS.CUSTOMER_SPENDING, 10, 2),
                    'customer_returns' VALUE DECIMAL(TS.CUSTOMER_RETURNS, 10, 2),
                    'net_spending' VALUE DECIMAL(TS.CUSTOMER_SPENDING - TS.CUSTOMER_RETURNS, 10, 2),
                    'spending_classification' VALUE TS.SPENDING_CLASSIFICATION
                ) FORMAT JSON
            )
            FROM TOP_STORES TS
            WHERE TS.SS_CUSTOMER_SK = C.C_CUSTOMER_SK
            AND TS.STORE_RANK <= 3
        ), JSON_ARRAY()) FORMAT JSON,
        'monthly_spending_patterns' VALUE COALESCE((
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'year' VALUE MS.D_YEAR,
                    'month' VALUE MS.MONTH,
                    'total_spending' VALUE DECIMAL(MS.TOTAL_SPENDING, 10, 2),
                    'total_returns' VALUE DECIMAL(MS.TOTAL_RETURNS, 10, 2),
                    'net_spending' VALUE DECIMAL(MS.NET_SPENDING, 10, 2),
                    'spending_range' VALUE MS.SPENDING_RANGE
                ) FORMAT JSON
            )
            FROM MONTHLY_SPENDING MS
            WHERE MS.SS_CUSTOMER_SK = C.C_CUSTOMER_SK
        ), JSON_ARRAY()) FORMAT JSON,
        'summary' VALUE JSON_OBJECT(
            'total_transactions' VALUE COALESCE((
                SELECT COUNT(*)
                FROM STORE_SALES SS
                WHERE SS.SS_CUSTOMER_SK = C.C_CUSTOMER_SK
            ), 0),
            'total_lifetime_spending' VALUE COALESCE((
                SELECT DECIMAL(SUM(SS.SS_EXT_SALES_PRICE), 10, 2)
                FROM STORE_SALES SS
                WHERE SS.SS_CUSTOMER_SK = C.C_CUSTOMER_SK
            ), 0.00),
            'total_returns' VALUE COALESCE((
                SELECT DECIMAL(COALESCE(SUM(SR.SR_RETURN_AMT), 0), 10, 2)
                FROM STORE_RETURNS SR
                WHERE SR.SR_CUSTOMER_SK = C.C_CUSTOMER_SK
            ), 0.00),
            'net_lifetime_value' VALUE COALESCE((
                SELECT DECIMAL(
                    SUM(SS.SS_EXT_SALES_PRICE) - COALESCE(
                        (SELECT SUM(SR.SR_RETURN_AMT)
                         FROM STORE_RETURNS SR
                         WHERE SR.SR_CUSTOMER_SK = C.C_CUSTOMER_SK), 0
                    ), 10, 2)
                FROM STORE_SALES SS
                WHERE SS.SS_CUSTOMER_SK = C.C_CUSTOMER_SK
            ), 0.00)
        ) FORMAT JSON
    )
FROM CUSTOMER C
LEFT JOIN CUSTOMER_DEMOGRAPHICS CD ON C.C_CURRENT_CDEMO_SK = CD.CD_DEMO_SK
LEFT JOIN HOUSEHOLD_DEMOGRAPHICS HD ON C.C_CURRENT_HDEMO_SK = HD.HD_DEMO_SK
LEFT JOIN INCOME_BAND IB ON HD.HD_INCOME_BAND_SK = IB.IB_INCOME_BAND_SK
LEFT JOIN CUSTOMER_ADDRESS CA ON C.C_CURRENT_ADDR_SK = CA.CA_ADDRESS_SK
WHERE EXISTS (
    SELECT 1 FROM STORE_SALES SS WHERE SS.SS_CUSTOMER_SK = C.C_CUSTOMER_SK
);

COMMIT;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT 'JSON documents generated successfully' AS STATUS FROM SYSIBM.SYSDUMMY1;
SELECT 'Total JSON documents: ' || COUNT(*) AS COUNT FROM CUSTOMER_JSON_DOCS;

-- Display sample JSON document (first customer)
SELECT 
    CUSTOMER_SK,
    CUSTOMER_ID,
    SUBSTR(JSON_DOCUMENT, 1, 500) AS JSON_SAMPLE
FROM CUSTOMER_JSON_DOCS
WHERE CUSTOMER_SK = 1;

-- Made with Bob
