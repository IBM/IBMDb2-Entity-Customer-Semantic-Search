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
-- Customer Semantic Search - Schema Creation
-- ============================================================================
-- This script creates the base schema for the customer semantic search project
-- Based on TPC-DS benchmark with enrichments for semantic search
-- Re-entrant: Drops and recreates all objects
-- ============================================================================

-- Create schema if it doesn't exist (ignore error if exists)
UPDATE COMMAND OPTIONS USING s OFF;
CREATE SCHEMA CUSTOMER_SEARCH;
UPDATE COMMAND OPTIONS USING s ON;

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Drop existing tables (in reverse dependency order)
-- ============================================================================
-- Disable stop-on-error to allow script to continue if objects don't exist
UPDATE COMMAND OPTIONS USING s OFF;

DROP TABLE STORE_RETURNS;
DROP TABLE STORE_SALES;
DROP TABLE DATE_DIM;
DROP TABLE STORE;
DROP TABLE ITEM;
DROP TABLE CUSTOMER_ADDRESS;
DROP TABLE INCOME_BAND;
DROP TABLE HOUSEHOLD_DEMOGRAPHICS;
DROP TABLE CUSTOMER_DEMOGRAPHICS;
DROP TABLE CUSTOMER;

DROP TABLESPACE cust_tbsp;
DROP BUFFERPOOL cust_bp;

-- Re-enable stop-on-error
UPDATE COMMAND OPTIONS USING s ON;

CREATE BUFFERPOOL cust_bp 
  SIZE AUTOMATIC 
  PAGESIZE 32K;

CREATE TABLESPACE cust_tbsp
  PAGESIZE 32K
  MANAGED BY AUTOMATIC STORAGE
  BUFFERPOOL cust_bp;

-- ============================================================================
-- Base Customer Table (TPC-DS inspired)
-- ============================================================================
CREATE TABLE CUSTOMER (
    C_CUSTOMER_SK INTEGER NOT NULL PRIMARY KEY,
    C_CUSTOMER_ID VARCHAR(16) NOT NULL,
    C_CURRENT_CDEMO_SK INTEGER,
    C_CURRENT_HDEMO_SK INTEGER,
    C_CURRENT_ADDR_SK INTEGER,
    C_FIRST_SHIPTO_DATE_SK INTEGER,
    C_FIRST_SALES_DATE_SK INTEGER,
    C_SALUTATION VARCHAR(10),
    C_FIRST_NAME VARCHAR(20),
    C_LAST_NAME VARCHAR(30),
    C_PREFERRED_CUST_FLAG CHAR(1),
    C_BIRTH_DAY INTEGER,
    C_BIRTH_MONTH INTEGER,
    C_BIRTH_YEAR INTEGER,
    C_BIRTH_COUNTRY VARCHAR(20),
    C_LOGIN VARCHAR(13),
    C_EMAIL_ADDRESS VARCHAR(50),
    C_LAST_REVIEW_DATE INTEGER
) IN cust_tbsp;

-- ============================================================================
-- Customer Demographics
-- ============================================================================
CREATE TABLE CUSTOMER_DEMOGRAPHICS (
    CD_DEMO_SK INTEGER NOT NULL PRIMARY KEY,
    CD_GENDER CHAR(1),
    CD_MARITAL_STATUS CHAR(1),
    CD_EDUCATION_STATUS VARCHAR(20),
    CD_PURCHASE_ESTIMATE INTEGER,
    CD_CREDIT_RATING VARCHAR(10),
    CD_DEP_COUNT INTEGER,
    CD_DEP_EMPLOYED_COUNT INTEGER,
    CD_DEP_COLLEGE_COUNT INTEGER
) IN cust_tbsp;

-- ============================================================================
-- Household Demographics
-- ============================================================================
CREATE TABLE HOUSEHOLD_DEMOGRAPHICS (
    HD_DEMO_SK INTEGER NOT NULL PRIMARY KEY,
    HD_INCOME_BAND_SK INTEGER,
    HD_BUY_POTENTIAL VARCHAR(15),
    HD_DEP_COUNT INTEGER,
    HD_VEHICLE_COUNT INTEGER
) IN cust_tbsp;

-- ============================================================================
-- Income Band
-- ============================================================================
CREATE TABLE INCOME_BAND (
    IB_INCOME_BAND_SK INTEGER NOT NULL PRIMARY KEY,
    IB_LOWER_BOUND INTEGER,
    IB_UPPER_BOUND INTEGER
) IN cust_tbsp;

-- ============================================================================
-- Customer Address
-- ============================================================================
CREATE TABLE CUSTOMER_ADDRESS (
    CA_ADDRESS_SK INTEGER NOT NULL PRIMARY KEY,
    CA_ADDRESS_ID VARCHAR(16) NOT NULL,
    CA_STREET_NUMBER VARCHAR(10),
    CA_STREET_NAME VARCHAR(60),
    CA_STREET_TYPE VARCHAR(15),
    CA_SUITE_NUMBER VARCHAR(10),
    CA_CITY VARCHAR(60),
    CA_COUNTY VARCHAR(30),
    CA_STATE CHAR(2),
    CA_ZIP VARCHAR(10),
    CA_COUNTRY VARCHAR(20),
    CA_GMT_OFFSET DECIMAL(5,2),
    CA_LOCATION_TYPE VARCHAR(20)
) IN cust_tbsp;

-- ============================================================================
-- Item Table
-- ============================================================================
CREATE TABLE ITEM (
    I_ITEM_SK INTEGER NOT NULL PRIMARY KEY,
    I_ITEM_ID VARCHAR(16) NOT NULL,
    I_REC_START_DATE DATE,
    I_REC_END_DATE DATE,
    I_ITEM_DESC VARCHAR(200),
    I_CURRENT_PRICE DECIMAL(7,2),
    I_WHOLESALE_COST DECIMAL(7,2),
    I_BRAND_ID INTEGER,
    I_BRAND VARCHAR(50),
    I_CLASS_ID INTEGER,
    I_CLASS VARCHAR(50),
    I_CATEGORY_ID INTEGER,
    I_CATEGORY VARCHAR(50),
    I_MANUFACT_ID INTEGER,
    I_MANUFACT VARCHAR(50),
    I_SIZE VARCHAR(20),
    I_FORMULATION VARCHAR(20),
    I_COLOR VARCHAR(20),
    I_UNITS VARCHAR(10),
    I_CONTAINER VARCHAR(10),
    I_MANAGER_ID INTEGER,
    I_PRODUCT_NAME VARCHAR(50)
) IN cust_tbsp;

-- ============================================================================
-- Store Table
-- ============================================================================
CREATE TABLE STORE (
    S_STORE_SK INTEGER NOT NULL PRIMARY KEY,
    S_STORE_ID VARCHAR(16) NOT NULL,
    S_REC_START_DATE DATE,
    S_REC_END_DATE DATE,
    S_CLOSED_DATE_SK INTEGER,
    S_STORE_NAME VARCHAR(50),
    S_NUMBER_EMPLOYEES INTEGER,
    S_FLOOR_SPACE INTEGER,
    S_HOURS VARCHAR(20),
    S_MANAGER VARCHAR(40),
    S_MARKET_ID INTEGER,
    S_GEOGRAPHY_CLASS VARCHAR(100),
    S_MARKET_DESC VARCHAR(100),
    S_MARKET_MANAGER VARCHAR(40),
    S_DIVISION_ID INTEGER,
    S_DIVISION_NAME VARCHAR(50),
    S_COMPANY_ID INTEGER,
    S_COMPANY_NAME VARCHAR(50),
    S_STREET_NUMBER VARCHAR(10),
    S_STREET_NAME VARCHAR(60),
    S_STREET_TYPE VARCHAR(15),
    S_SUITE_NUMBER VARCHAR(10),
    S_CITY VARCHAR(60),
    S_COUNTY VARCHAR(30),
    S_STATE CHAR(2),
    S_ZIP VARCHAR(10),
    S_COUNTRY VARCHAR(20),
    S_GMT_OFFSET DECIMAL(5,2),
    S_TAX_PERCENTAGE DECIMAL(5,2)
) IN cust_tbsp;

-- ============================================================================
-- Store Sales Table
-- ============================================================================
CREATE TABLE STORE_SALES (
    SS_SOLD_DATE_SK INTEGER,
    SS_SOLD_TIME_SK INTEGER,
    SS_ITEM_SK INTEGER NOT NULL,
    SS_CUSTOMER_SK INTEGER,
    SS_CDEMO_SK INTEGER,
    SS_HDEMO_SK INTEGER,
    SS_ADDR_SK INTEGER,
    SS_STORE_SK INTEGER,
    SS_PROMO_SK INTEGER,
    SS_TICKET_NUMBER BIGINT NOT NULL,
    SS_QUANTITY INTEGER,
    SS_WHOLESALE_COST DECIMAL(7,2),
    SS_LIST_PRICE DECIMAL(7,2),
    SS_SALES_PRICE DECIMAL(7,2),
    SS_EXT_DISCOUNT_AMT DECIMAL(7,2),
    SS_EXT_SALES_PRICE DECIMAL(7,2),
    SS_EXT_WHOLESALE_COST DECIMAL(7,2),
    SS_EXT_LIST_PRICE DECIMAL(7,2),
    SS_EXT_TAX DECIMAL(7,2),
    SS_COUPON_AMT DECIMAL(7,2),
    SS_NET_PAID DECIMAL(7,2),
    SS_NET_PAID_INC_TAX DECIMAL(7,2),
    SS_NET_PROFIT DECIMAL(7,2),
    PRIMARY KEY (SS_ITEM_SK, SS_TICKET_NUMBER)
) IN cust_tbsp;

-- ============================================================================
-- Store Returns Table
-- ============================================================================
CREATE TABLE STORE_RETURNS (
    SR_RETURNED_DATE_SK INTEGER,
    SR_RETURN_TIME_SK INTEGER,
    SR_ITEM_SK INTEGER NOT NULL,
    SR_CUSTOMER_SK INTEGER,
    SR_CDEMO_SK INTEGER,
    SR_HDEMO_SK INTEGER,
    SR_ADDR_SK INTEGER,
    SR_STORE_SK INTEGER,
    SR_REASON_SK INTEGER,
    SR_TICKET_NUMBER BIGINT NOT NULL,
    SR_RETURN_QUANTITY INTEGER,
    SR_RETURN_AMT DECIMAL(7,2),
    SR_RETURN_TAX DECIMAL(7,2),
    SR_RETURN_AMT_INC_TAX DECIMAL(7,2),
    SR_FEE DECIMAL(7,2),
    SR_RETURN_SHIP_COST DECIMAL(7,2),
    SR_REFUNDED_CASH DECIMAL(7,2),
    SR_REVERSED_CHARGE DECIMAL(7,2),
    SR_STORE_CREDIT DECIMAL(7,2),
    SR_NET_LOSS DECIMAL(7,2),
    PRIMARY KEY (SR_ITEM_SK, SR_TICKET_NUMBER)
) IN cust_tbsp;

-- ============================================================================
-- Date Dimension
-- ============================================================================
CREATE TABLE DATE_DIM (
    D_DATE_SK INTEGER NOT NULL PRIMARY KEY,
    D_DATE_ID VARCHAR(16) NOT NULL,
    D_DATE DATE,
    D_MONTH_SEQ INTEGER,
    D_WEEK_SEQ INTEGER,
    D_QUARTER_SEQ INTEGER,
    D_YEAR INTEGER,
    D_DOW INTEGER,
    D_MOY INTEGER,
    D_DOM INTEGER,
    D_QOY INTEGER,
    D_FY_YEAR INTEGER,
    D_FY_QUARTER_SEQ INTEGER,
    D_FY_WEEK_SEQ INTEGER,
    D_DAY_NAME VARCHAR(9),
    D_QUARTER_NAME VARCHAR(6),
    D_HOLIDAY CHAR(1),
    D_WEEKEND CHAR(1),
    D_FOLLOWING_HOLIDAY CHAR(1),
    D_FIRST_DOM INTEGER,
    D_LAST_DOM INTEGER,
    D_SAME_DAY_LY INTEGER,
    D_SAME_DAY_LQ INTEGER,
    D_CURRENT_DAY CHAR(1),
    D_CURRENT_WEEK CHAR(1),
    D_CURRENT_MONTH CHAR(1),
    D_CURRENT_QUARTER CHAR(1),
    D_CURRENT_YEAR CHAR(1)
) IN cust_tbsp;

-- ============================================================================
-- Create Indexes for Performance
-- ============================================================================
CREATE INDEX IDX_CUSTOMER_DEMO ON CUSTOMER(C_CURRENT_CDEMO_SK);
CREATE INDEX IDX_CUSTOMER_ADDR ON CUSTOMER(C_CURRENT_ADDR_SK);
CREATE INDEX IDX_SS_CUSTOMER ON STORE_SALES(SS_CUSTOMER_SK);
CREATE INDEX IDX_SS_ITEM ON STORE_SALES(SS_ITEM_SK);
CREATE INDEX IDX_SS_STORE ON STORE_SALES(SS_STORE_SK);
CREATE INDEX IDX_SS_DATE ON STORE_SALES(SS_SOLD_DATE_SK);
CREATE INDEX IDX_SR_CUSTOMER ON STORE_RETURNS(SR_CUSTOMER_SK);
CREATE INDEX IDX_SR_ITEM ON STORE_RETURNS(SR_ITEM_SK);
CREATE INDEX IDX_SR_STORE ON STORE_RETURNS(SR_STORE_SK);

-- ============================================================================
-- Grant Permissions (adjust as needed)
-- ============================================================================
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA CUSTOMER_SEARCH TO PUBLIC;

COMMIT;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT 'Schema created successfully. Tables:' AS STATUS FROM SYSIBM.SYSDUMMY1;
SELECT TABNAME, TYPE FROM SYSCAT.TABLES WHERE TABSCHEMA = 'CUSTOMER_SEARCH' ORDER BY TABNAME;

-- Made with Bob
