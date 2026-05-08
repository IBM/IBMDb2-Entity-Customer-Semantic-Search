# Customer Semantic Search - Process Flowchart

## Complete End-to-End Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          STEP 1: DATA INGESTION                             │
│                         (01_create_schema.sql)                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │   Relational Database Tables    │
                    ├─────────────────────────────────┤
                    │ • CUSTOMER                      │
                    │ • CUSTOMER_DEMOGRAPHICS         │
                    │ • CUSTOMER_ADDRESS              │
                    │ • ITEM                          │
                    │ • STORE                         │
                    │ • STORE_SALES                   │
                    │ • STORE_RETURNS                 │
                    │ • DATE_DIM                      │
                    └─────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       STEP 2: LOAD SAMPLE DATA                              │
│                      (02_load_sample_data.sql)                              │
│                                                                             │
│  Populates tables with TPC-DS inspired customer data:                       │
│  • 50 Customers with demographics                                           │
│  • 50 Items across categories                                               │
│  • 10 Stores with locations                                                  │
│  • Sales transactions and returns                                           │
│  • 730 days of date dimension (2023-2024)                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    STEP 3: CREATE JSON TABLE                                │
│                    (03_create_json_table.sql)                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │   CUSTOMER_JSON_DOCS Table      │
                    ├─────────────────────────────────┤
                    │ • CUSTOMER_SK (PK)              │
                    │ • CUSTOMER_ID                   │
                    │ • JSON_DOCUMENT (CLOB)          │
                    │ • CREATED_TIMESTAMP             │
                    │ • UPDATED_TIMESTAMP             │
                    └─────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   STEP 4: GENERATE JSON DOCUMENTS                           │
│                     (04_generate_json.sql)                                  │
│                                                                             │
│  Uses Db2 JSON Functions:                                                   │
│  ┌────────────────────────────────────────────────────────────────┐         │
│  │ JSON_OBJECT(                                                   │         │
│  │   'customer_id' VALUE ...,                                     │         │
│  │   'customer_info' VALUE JSON_OBJECT(...),                      │         │
│  │   'top_purchased_items' VALUE JSON_ARRAYAGG(...),              │         │
│  │   'top_stores' VALUE JSON_ARRAYAGG(...),                       │         │
│  │   'monthly_spending_patterns' VALUE JSON_ARRAYAGG(...)         │         │
│  │ )                                                              │         │
│  └────────────────────────────────────────────────────────────────┘         │
│                                                                             │
│  Aggregates data from multiple tables into enriched JSON documents          │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │    JSON Document Example        │
                    ├─────────────────────────────────┤
                    │ {                               │
                    │   "customer_id": 1,             │
                    │   "customer_info": {            │
                    │     "name": "John Smith",       │
                    │     "demographics": {...},      │
                    │     "address": {...}            │
                    │   },                            │
                    │   "top_purchased_items": [...], │
                    │   "top_stores": [...],          │
                    │   "monthly_spending": [...]     │
                    │ }                               │
                    └─────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   STEP 5: CREATE CHUNKS TABLE                               │
│                   (05_create_chunk_table.sql)                               │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │  CUSTOMER_TEXT_CHUNKS Table     │
                    ├─────────────────────────────────┤
                    │ • CHUNK_ID (PK, Identity)       │
                    │ • CUSTOMER_SK                   │
                    │ • CUSTOMER_ID                   │
                    │ • CHUNK_SEQUENCE                │
                    │ • CHUNK_TYPE                    │
                    │ • CHUNK_TEXT (CLOB)             │
                    │ • CHUNK_SIZE                    │
                    │ • EMBEDDING (VECTOR(1536))      │
                    │ • CREATED_TIMESTAMP             │
                    └─────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                 STEP 6: CREATE TEXT PROCESSING UDFs                         │
│                   (06_text_chunking_udfs.sql)                               │
│                                                                             │
│  User-Defined Functions:                                                    │
│  ┌────────────────────────────────────────────────────────────────┐         │
│  │ • JSON_TO_TEXT(json_doc)                                       │         │
│  │   → Extracts customer info and demographics                    │         │
│  │                                                                │         │
│  │ • EXTRACT_ITEMS_TEXT(json_doc)                                 │         │
│  │   → Formats top 3 purchased items                              │         │
│  │                                                                │         │
│  │ • EXTRACT_STORES_TEXT(json_doc)                                │         │
│  │   → Formats top 3 stores                                       │         │
│  │                                                                │         │
│  │ • EXTRACT_SPENDING_TEXT(json_doc)                              │         │
│  │   → Formats spending patterns and summary                      │         │
│  │                                                                │         │
│  │ • CHUNK_TEXT(text, max_size)                                   │         │
│  │   → Splits text into manageable chunks                         │         │
│  └────────────────────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    STEP 7: GENERATE TEXT CHUNKS                             │
│                     (07_generate_chunks.sql)                                │
│                                                                             │
│  For each customer, creates 4 types of chunks:                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                    ▼                                   ▼
        ┌────────────────────────┐        ┌────────────────────────┐
        │  Chunk 1: customer_info│        │  Chunk 2: top_items    │
        ├────────────────────────┤        ├────────────────────────┤
        │ "Customer Profile:     │        │ "Top Purchased Items:  │
        │  John Smith.           │        │  Item 1: Wireless      │
        │  Email: john@...       │        │  Headphones            │
        │  Demographics: M M,    │        │  (Electronics, Audio), │
        │  Education: College,   │        │  Spending: $269.97     │
        │  Income: $40k-$50k.    │        │  (high). Item 2: ...   │
        │  Location: Springfield │        │  ..."                  │
        │  , IL 62701."          │        │                        │
        └────────────────────────┘        └────────────────────────┘
                    │                                   │
                    ▼                                   ▼
        ┌───────────────────────┐         ┌───────────────────────┐
        │  Chunk 3: top_stores  │         │ Chunk 4: spending_    │
        ├───────────────────────┤         │         summary       │
        │ "Top Stores:          │         ├───────────────────────┤
        │  Store 1: Springfield │         │ "Customer Summary:    │
        │  Mall Store in        │         │  Total transactions:  │
        │  Springfield, IL.     │         │  3, Lifetime spending:│
        │  Customer spending:   │         │  $539.94, Total       │
        │  $539.94 (very_high). │         │  returns: $199.99,    │
        │  Store 2: ..."        │         │  Net lifetime value:  │
        │                       │         │  $339.95. Monthly     │
        │                       │         │  Spending Patterns:." │
        └───────────────────────┘         └───────────────────────┘
                    │                                   │
                    └─────────────────┬─────────────────┘
                                      ▼
                    ┌─────────────────────────────────┐
                    │   ~40 Text Chunks Created       │
                    │   (4 chunks × 10 customers)     │
                    └─────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   STEP 8: GENERATE EMBEDDINGS                               │
│                   (08_generate_embeddings.sql)                              │
│                                                                             │
│  Uses Db2 EAP TO_EMBEDDING Function:                                        │
│  ┌────────────────────────────────────────────────────────────────┐         │
│  │ UPDATE CUSTOMER_TEXT_CHUNKS                                    │         │
│  │ SET EMBEDDING = TO_EMBEDDING(                                  │         │
│  │     CHUNK_TEXT,                                                │         │
│  │     'embedding_model'  -- External model (OpenAI, etc.)        │         │
│  │ )                                                              │         │
│  │ WHERE CHUNK_TEXT IS NOT NULL                                   │         │
│  └────────────────────────────────────────────────────────────────┘         │
│                                                                             │
│  External Model Integration:                                                │
│  ┌────────────────────────────────────────────────────────────────┐         │
│  │  Db2 → API Call → OpenAI/HuggingFace → 1536-dim Vector         │         │
│  └────────────────────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │   Text Chunk with Embedding     │
                    ├─────────────────────────────────┤
                    │ CHUNK_TEXT:                     │
                    │ "Customer Profile: John Smith." │
                    │                                 │
                    │ EMBEDDING:                      │
                    │ [0.023, -0.015, 0.041, ...,     │
                    │  0.008, -0.032, 0.019]          │
                    │ (1536 dimensions)               │
                    └─────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                   STEP 9: CREATE VECTOR INDEX                               │
│                   (09_create_vector_index.sql)                              │
│                                                                             │
│  Creates DiskANN-based Vector Index (Graph-based ANN):                      │
│  ┌────────────────────────────────────────────────────────────────┐         │
│  │ CREATE VECTOR INDEX IDX_CUSTOMER_EMBEDDINGS                    │         │
│  │ ON CUSTOMER_TEXT_CHUNKS(EMBEDDING)                             │         │
│  │ WITH DISTANCE COSINE                                           │         │
│  │ BUILD_LIST_SIZE 100        -- Candidate list during build      │         │
│  │ PCT_COMP_VECT_SIZE 10      -- Compressed vector size (10%)     │         │
│  │ MAX_NODE_DEGREE 64;        -- Neighbors per node               │         │
│  └────────────────────────────────────────────────────────────────┘         │
│                                                                             │
│  Index Parameters (all optional):                                           │
│  • BUILD_LIST_SIZE: 1-200 (default 50) - Higher = better quality            │
│  • PCT_COMP_VECT_SIZE: 1-75% (default 5%) - Higher = better recall          │
│  • MAX_NODE_DEGREE: 32-128 (default 64) - Higher = better recall            │
│                                                                             │
│  Graph Structure (DiskANN):                                                 │
│  ┌────────────────────────────────────────────────────────────────┐         │
│  │         Layer 2 (Top)                                          │         │
│  │            ●───●                                               │         │
│  │           /│\ /│\                                              │         │
│  │         Layer 1                                                │         │
│  │        ●───●───●───●                                           │         │
│  │       /│\ /│\ /│\ /│\                                          │         │
│  │     Layer 0 (Base)                                             │         │
│  │    ●─●─●─●─●─●─●─●─●─●  (All vectors)                          │         │
│  └────────────────────────────────────────────────────────────────┘         │
│                                                                             │
│  Enables fast approximate nearest neighbor (ANN) search                     │
│  • Graph-based navigation                                                   │
│  • Vector compression (quantization)                                        │
│  • On-disk search for scalability                                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                  STEP 10: SEMANTIC SEARCH QUERIES                           │
│                   (10_semantic_search.sql)                                  │
│                                                                             │
│  Query Process:                                                             │
│  ┌────────────────────────────────────────────────────────────────┐         │
│  │ 1. User enters natural language query                          │         │
│  │    "Find customers who buy electronics frequently"             │         │
│  │                                                                │         │
│  │ 2. Convert query to embedding                                  │         │
│  │    TO_EMBEDDING(query_text USING embedding_model)              │         │
│  │    → [0.031, -0.022, 0.055, ..., 0.012]                        │         │
│  │                                                                │         │
│  │ 3. Search using vector index                                   │         │
│  │    ORDER BY VECTOR_DISTANCE(                                   │         │
│  │        EMBEDDING,                                              │         │
│  │        query_vector,                                           │         │
│  │        'EUCLIDEAN'                                             │         │
│  │    )                                                           │         │
│  │    FETCH APPROX FIRST 10 ROWS ONLY                             │         │
│  │                                                                │         │
│  │ 4. Return ranked results                                       │         │
│  │    (Approximate nearest neighbors)                             │         │
│  └────────────────────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │      Search Results             │
                    ├─────────────────────────────────┤
                    │ Customer 1: John Smith          │
                    │ Similarity: 0.23 (High match)   │
                    │ Preview: "Customer who          │
                    │ purchases electronics..."       │
                    │                                 │
                    │ Customer 5: David Jones         │
                    │ Similarity: 0.31 (Good match)   │
                    │ Preview: "Top Items: Wireless." │
                    │                                 │
                    │ Customer 7: Robert Martinez     │
                    │ Similarity: 0.38 (Good match)   │
                    │ ...                             │
                    └─────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │   Use Cases Enabled:            │
                    ├─────────────────────────────────┤
                    │ ✓ Customer Discovery            │
                    │ ✓ Similar Customer Finding      │
                    │ ✓ Customer Segmentation         │
                    │ ✓ Churn Prediction              │
                    │ ✓ Cross-sell Recommendations    │
                    │ ✓ Lookalike Audiences           │
                    │ ✓ Personalized Marketing        │
                    └─────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════
                            KEY TECHNOLOGIES USED
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────┬──────────────────────────────────────────────────────────┐
│ Layer           │ Technology                                               │
├─────────────────┼──────────────────────────────────────────────────────────┤
│ Storage         │ Db2 Relational Tables                                    │
│ Transformation  │ Db2 JSON Functions (JSON_OBJECT, JSON_ARRAY, etc.)       │
│ Processing      │ Db2 User-Defined Functions (UDFs)                        │
│ AI Integration  │ Db2 TO_EMBEDDING (EAP) + External Models                 │
│ Indexing        │ Db2 Vector Index (DiskANN Algorithm)                     │
│ Search          │ Db2 EXACT and APPROXIMATE VECTOR_DISTANCE                │
│ Query Language  │ Standard SQL with Vector Extensions                      │
└─────────────────┴──────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════
                         PERFORMANCE CHARACTERISTICS
═══════════════════════════════════════════════════════════════════════════════

Data Volume:        10 customers → 40 chunks → 40 embeddings
Embedding Size:     1536 dimensions per vector
Index Type:         DiskANN-based 
Search Complexity:  O(log n) with APPROXIMATE search
Distance Metric:    Euclidean Similarity
Query Time:         < 10ms for 10K vectors (with index)
Scalability:        Millions of vectors supported


═══════════════════════════════════════════════════════════════════════════════
                              ADVANTAGES
═══════════════════════════════════════════════════════════════════════════════

✓ All-in-Db2:       No external vector databases needed
✓ ACID Compliance:  Full transactional support
✓ SQL Integration:  Familiar query language
✓ Security:         Enterprise-grade data protection
✓ Governance:       Centralized data management
✓ Performance:      Optimized with vector indexes
✓ Scalability:      Production-ready architecture
```

## Quick Reference: SQL Script Execution Order

```
1. 01_create_schema.sql       → Create tables
2. 02_load_sample_data.sql     → Insert data
3. 03_create_json_table.sql    → Create JSON table
4. 04_generate_json.sql        → Generate JSON docs
5. 05_create_chunk_table.sql   → Create chunks table
6. 06_text_chunking_udfs.sql   → Create UDFs
7. 07_generate_chunks.sql      → Generate text chunks
8. 08_generate_embeddings.sql  → Generate embeddings (requires external model)
9. 09_create_vector_index.sql  → Create vector index
10. 10_semantic_search.sql     → Run semantic searches
```

## Data Flow Summary

```
Raw Data → JSON → Text → Chunks → Embeddings → Index → Search Results
   ↓         ↓      ↓       ↓         ↓          ↓         ↓
 Tables   CLOB   String  Multiple  Vectors   HNSW    Ranked List
