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
-- Customer Semantic Search - Generate Comprehensive LLM Profiles
-- ============================================================================
-- This script generates comprehensive AI-generated customer profiles (up to 1000 words)
-- Uses TEXT_GENERATION to create detailed natural language profiles from JSON data
-- Stores results in CUSTOMER_LLM_PROFILE table
-- ============================================================================

SET SCHEMA CUSTOMER_SEARCH;

-- ============================================================================
-- Prerequisites
-- ============================================================================
-- 1. QWEN_TEXT_GEN model must be created (see 08_generate_embeddings.sql)
-- 2. llama-server must be running on port 8081 with qwen2.5-3b-instruct model
-- 3. CUSTOMER_JSON_DOCS table must be populated
-- 4. CUSTOMER_LLM_PROFILE table must exist

-- ============================================================================
-- Clean Up: Delete existing profiles
-- ============================================================================
-- Ignore warning if table is empty
UPDATE COMMAND OPTIONS USING s OFF;
DELETE FROM CUSTOMER_LLM_PROFILE;
UPDATE COMMAND OPTIONS USING s ON;

COMMIT;

-- Show progress before generation
SELECT
    'Starting comprehensive LLM profile generation for ' || COUNT(*) || ' customers' AS STATUS
FROM CUSTOMER_JSON_DOCS
WHERE JSON_DOCUMENT IS NOT NULL;

-- ============================================================================
-- Generate Comprehensive Customer Profiles
-- ============================================================================
-- Creates detailed 1000-word profiles that will be chunked in the next step
-- Each profile includes all aspects: demographics, shopping, stores, spending

INSERT INTO CUSTOMER_LLM_PROFILE (
    CUSTOMER_SK,
    CUSTOMER_ID,
    PROFILE_TEXT,
    PROFILE_SIZE
)
SELECT
    CUSTOMER_SK,
    CUSTOMER_ID,
    GENERATED_TEXT AS PROFILE_TEXT,
    LENGTH(GENERATED_TEXT) AS PROFILE_SIZE
FROM (
    SELECT
        CUSTOMER_SK,
        CUSTOMER_ID,
        TEXT_GENERATION(
            'You are a customer analytics expert. Analyze the following customer JSON data and create a comprehensive natural language insightful customer profile description. Synthesize the raw data into a coherent story that highlights their behaviors and preferences. Include: 1) Customer demographics and location, 2) Shopping preferences and top purchased items with spending details, 3) Preferred stores and locations, 4) Overall spending patterns and customer lifetime value. Be specific with numbers and details. Keep the summary under 1000 words and make it suitable for semantic search.' || CHR(10) || CHR(10) ||
            'Customer Data:' || CHR(10) ||
            JSON_DOCUMENT
            USING QWEN_TEXT_GEN
        ) AS GENERATED_TEXT
    FROM CUSTOMER_JSON_DOCS
    WHERE JSON_DOCUMENT IS NOT NULL
) AS GENERATED_PROFILES;

COMMIT;

-- ============================================================================
-- Verify Profiles Created
-- ============================================================================
SELECT
    'Comprehensive LLM profiles created: ' || COUNT(*) AS STATUS
FROM CUSTOMER_LLM_PROFILE;

-- Show sample of generated profiles
SELECT
    CUSTOMER_SK,
    SUBSTR(PROFILE_TEXT, 1, 5000) || '...' AS PROFILE_PREVIEW,
    PROFILE_SIZE
FROM CUSTOMER_LLM_PROFILE
ORDER BY CUSTOMER_SK
FETCH FIRST 1 ROWS ONLY;

-- ============================================================================
-- Statistics
-- ============================================================================
SELECT
    'Total profiles: ' || COUNT(*) AS STAT
FROM CUSTOMER_LLM_PROFILE
UNION ALL
SELECT
    'Average profile size: ' || CAST(AVG(PROFILE_SIZE) AS INTEGER) || ' characters' AS STAT
FROM CUSTOMER_LLM_PROFILE
UNION ALL
SELECT
    'Min profile size: ' || MIN(PROFILE_SIZE) || ' characters' AS STAT
FROM CUSTOMER_LLM_PROFILE
UNION ALL
SELECT
    'Max profile size: ' || MAX(PROFILE_SIZE) || ' characters' AS STAT
FROM CUSTOMER_LLM_PROFILE;

COMMIT;

-- Made with Bob
