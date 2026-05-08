# Customer Semantic Search - Setup Guide

This guide walks you through setting up the Customer Semantic Search project on IBM Db2.

## Prerequisites

### Software Requirements

1. **IBM Db2** (version 12.1.5 EAP or later)
   - Db2 Early Access Program (EAP) features enabled when using EAP build
   - External model support for TO_EMBEDDING and TEXT_GENERATION function
   - Vector index support 

2. **Db2 Client Tools**
   - Db2 Command Line Processor (CLP)
   - Or Db2 Data Studio / DBeaver / other SQL client

3. **External Embedding Model** (one of):
   - Local model using llama-cpp server
   - OpenAI API access (text-embedding-ada-002 or similar)
   - Hugging Face model endpoint
   - Azure OpenAI Service
   - Other compatible embedding service

### Access Requirements

- Database administrator privileges (for creating schemas, tables, indexes)
- Network access to external embedding model API
- Sufficient storage for customer data and embeddings

### Resource Estimates

For 10,000 customers with 4 chunks each:
- **Storage**: ~500 MB (data) + ~250 MB (embeddings) + ~100 MB (indexes)
- **Memory**: 2-4 GB recommended for vector index
- **API Calls**: ~40,000 embedding generation calls

## Step-by-Step Setup

### Step 1: Configure Db2 EAP Features

1. **Enable Vector Indexing**
   ```bash
   db2set DB2_VECTOR_INDEXING=YES -immediate
   ```
   
   Note: The `-immediate` flag allows the change to take effect without restarting the instance.

2. **Verify Vector Indexing is Enabled**
   ```bash
   db2set DB2_VECTOR_INDEXING
   ```
   
   Should return: `DB2_VECTOR_INDEXING=YES`

### Step 2: Configure External Embedding Model

1. **Create External Model Configuration**

   For OpenAI:
   ```sql
   CREATE EXTERNAL MODEL embedding_model
   TYPE EMBEDDING
   ENDPOINT 'https://api.openai.com/v1/embeddings'
   MODEL 'text-embedding-ada-002'
   API_KEY 'your-openai-api-key'
   WITH (
       VECTOR_DIMENSION = 1536,
       MAX_BATCH_SIZE = 100,
       TIMEOUT = 30
   );
   ```

   For Azure OpenAI:
   ```sql
   CREATE EXTERNAL MODEL embedding_model
   TYPE EMBEDDING
   ENDPOINT 'https://your-resource.openai.azure.com/openai/deployments/your-deployment/embeddings'
   API_KEY 'your-azure-api-key'
   WITH (
       VECTOR_DIMENSION = 1536,
       API_VERSION = '2023-05-15'
   );
   ```

2. **Test Model Connection**
   ```sql
   SELECT TO_EMBEDDING('test query' USING GRANITE30)
   FROM SYSIBM.SYSDUMMY1;
   ```

### Step 3: Create Database Schema

1. **Connect to Database**
   ```bash
   db2 connect to your_database user your_username
   ```

2. **Run Schema Creation Script**
   ```bash
   db2 -tvf sql/01_create_schema.sql
   ```

3. **Verify Tables Created**
   ```sql
   SELECT TABNAME FROM SYSCAT.TABLES 
   WHERE TABSCHEMA = 'CUSTOMER_SEARCH' 
   ORDER BY TABNAME;
   ```

### Step 4: Load Sample Data

1. **Load Sample Data**
   ```bash
   db2 -tvf sql/02_load_sample_data.sql
   ```

2. **Verify Data Loaded**
   ```sql
   SET SCHEMA CUSTOMER_SEARCH;
   SELECT 'Customers: ' || COUNT(*) FROM CUSTOMER;
   SELECT 'Items: ' || COUNT(*) FROM ITEM;
   SELECT 'Sales: ' || COUNT(*) FROM STORE_SALES;
   ```

### Step 5: Generate JSON Documents

1. **Create JSON Table**
   ```bash
   db2 -tvf sql/03_create_json_table.sql
   ```

2. **Generate JSON Documents**
   ```bash
   db2 -tvf sql/04_generate_json.sql
   ```

3. **Verify JSON Generation**
   ```sql
   SELECT COUNT(*) FROM CUSTOMER_JSON_DOCS;
   SELECT SUBSTR(JSON_DOCUMENT, 1, 200) 
   FROM CUSTOMER_JSON_DOCS 
   WHERE CUSTOMER_SK = 1;
   ```

### Step 6: Create Text Chunks

1. **Create Chunks Table**
   ```bash
   db2 -tvf sql/05_create_chunk_table.sql
   ```

2. **Create Text Processing UDFs**
   ```bash
   db2 -tvf sql/06_text_chunking_udfs.sql
   ```

3. **Generate Text Chunks**
   ```bash
   db2 -tvf sql/07_generate_chunks.sql
   ```

4. **Verify Chunks Created**
   ```sql
   SELECT CHUNK_TYPE, COUNT(*) 
   FROM CUSTOMER_TEXT_CHUNKS 
   GROUP BY CHUNK_TYPE;
   ```

### Step 7: Generate Embeddings

1. **Update Model Name in Script**
   
   Edit `sql/08_generate_embeddings.sql` and replace `'embedding_model'` with your actual model name.

2. **Generate Embeddings**
   ```bash
   db2 -tvf sql/08_generate_embeddings.sql
   ```

   **Note**: This step may take time depending on:
   - Number of chunks
   - API rate limits
   - Network latency

3. **Monitor Progress**
   ```sql
   SELECT 
       COUNT(*) AS TOTAL_CHUNKS,
       SUM(CASE WHEN EMBEDDING IS NOT NULL THEN 1 ELSE 0 END) AS WITH_EMBEDDING,
       SUM(CASE WHEN EMBEDDING IS NULL THEN 1 ELSE 0 END) AS WITHOUT_EMBEDDING
   FROM CUSTOMER_TEXT_CHUNKS;
   ```

### Step 8: Create Vector Index

1. **Create Index**
   ```bash
   db2 -tvf sql/09_create_vector_index.sql
   ```

2. **Verify Index Created**
   ```sql
   SELECT INDNAME, INDEXTYPE, COLNAMES 
   FROM SYSCAT.INDEXES 
   WHERE TABSCHEMA = 'CUSTOMER_SEARCH' 
   AND TABNAME = 'CUSTOMER_TEXT_CHUNKS';
   ```

### Step 9: Test Semantic Search

1. **Run Sample Queries**
   ```bash
   db2 -tvf sql/10_semantic_search.sql
   ```

2. **Test Custom Query**
   ```sql
   SET SCHEMA CUSTOMER_SEARCH;
   
   WITH QUERY_EMBEDDING AS (
       SELECT TO_EMBEDDING(
           'Customer who frequently buys electronics'
           USING GRANITE30
       ) AS QUERY_VECTOR
       FROM SYSIBM.SYSDUMMY1
   )
   SELECT
       C.CUSTOMER_SK,
       C.CUSTOMER_ID,
       SUBSTR(C.CHUNK_TEXT, 1, 100) AS PREVIEW,
       VECTOR_DISTANCE(C.EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS SIMILARITY
   FROM CUSTOMER_TEXT_CHUNKS C
   CROSS JOIN QUERY_EMBEDDING Q
   WHERE C.EMBEDDING IS NOT NULL
   ORDER BY SIMILARITY ASC
   FETCH FIRST 5 ROWS ONLY;
   ```

## Troubleshooting

### Issue: External Model Connection Fails

**Symptoms**: TO_EMBEDDING returns error or NULL

**Solutions**:
1. Verify API key is correct
2. Check network connectivity to API endpoint
3. Verify API quota/rate limits
4. Check Db2 logs: `db2diag.log`

**Test Connection**:
```sql
SELECT TO_EMBEDDING('test' USING GRANITE30) FROM SYSIBM.SYSDUMMY1;
```

### Issue: Embedding Generation is Slow

**Symptoms**: UPDATE statement takes very long

**Solutions**:
1. Process in smaller batches
2. Check API rate limits
3. Increase timeout settings
4. Use parallel processing if available

**Batch Processing Example**:
```sql
-- Process 100 chunks at a time
UPDATE CUSTOMER_TEXT_CHUNKS
SET EMBEDDING = TO_EMBEDDING(CHUNK_TEXT USING GRANITE30)
WHERE CHUNK_ID IN (
    SELECT CHUNK_ID
    FROM CUSTOMER_TEXT_CHUNKS
    WHERE EMBEDDING IS NULL
    FETCH FIRST 100 ROWS ONLY
);
COMMIT;
```

### Issue: Vector Index Not Being Used

**Symptoms**: Queries are slow despite having index

**Solutions**:
1. Use FETCH APPROX in queries
2. Update statistics: `RUNSTATS ON TABLE CUSTOMER_TEXT_CHUNKS AND INDEXES ALL`
3. Check index health
4. Verify index parameters
5. Ensure K (FETCH FIRST value) <= SEARCH_LIST_SIZE

**Force Index Usage**:
```sql
WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING('query text' USING GRANITE30) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT * FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE EMBEDDING IS NOT NULL
ORDER BY VECTOR_DISTANCE(EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN)
FETCH APPROX FIRST 10 ROWS ONLY;
```

### Issue: Out of Memory During Index Creation

**Symptoms**: Index creation fails with memory error

**Solutions**:
1. Increase database memory: `db2 update db cfg using SHEAPTHRES_SHR 50000`
2. Reduce M parameter in index configuration
3. Create index on subset of data first
4. Increase system memory

### Issue: JSON Generation Fails

**Symptoms**: NULL values in JSON_DOCUMENT column

**Solutions**:
1. Check for NULL values in source tables
2. Verify JSON function syntax
3. Check for data type mismatches
4. Review Db2 error messages

**Debug Query**:
```sql
SELECT C_CUSTOMER_SK, C_CUSTOMER_ID
FROM CUSTOMER
WHERE C_CUSTOMER_SK NOT IN (
    SELECT CUSTOMER_SK FROM CUSTOMER_JSON_DOCS
);
```

## Performance Tuning

### Database Configuration

```sql
-- Increase buffer pool size
ALTER BUFFERPOOL IBMDEFAULTBP SIZE 10000;

-- Increase sort heap
UPDATE DB CFG USING SORTHEAP 2048;

-- Enable query optimization
UPDATE DB CFG USING DFT_QUERYOPT 5;

-- Increase lock list
UPDATE DB CFG USING LOCKLIST 10000;
```

### Index Tuning

For better recall (slower build, better accuracy, larger index):
```sql
CREATE VECTOR INDEX idx_embeddings_high_recall
ON CUSTOMER_TEXT_CHUNKS(EMBEDDING)
WITH DISTANCE EUCLIDEAN
BUILD_LIST_SIZE 150
PCT_COMP_VECT_SIZE 20
MAX_NODE_DEGREE 96;
```

For faster build (faster index creation, lower recall, smaller index):
```sql
CREATE VECTOR INDEX idx_embeddings_fast
ON CUSTOMER_TEXT_CHUNKS(EMBEDDING)
WITH DISTANCE EUCLIDEAN
BUILD_LIST_SIZE 50
PCT_COMP_VECT_SIZE 5
MAX_NODE_DEGREE 48;
```

### Query Optimization

```sql
-- Set optimization level
SET CURRENT QUERY OPTIMIZATION = 5;

-- Use optimizer hints to tune search parameters
WITH QUERY_EMBEDDING AS (
    SELECT TO_EMBEDDING('query' USING GRANITE30) AS QUERY_VECTOR
    FROM SYSIBM.SYSDUMMY1
)
SELECT CUSTOMER_SK, CHUNK_TEXT,
       VECTOR_DISTANCE(EMBEDDING, Q.QUERY_VECTOR, EUCLIDEAN) AS DISTANCE
FROM CUSTOMER_TEXT_CHUNKS C
CROSS JOIN QUERY_EMBEDDING Q
WHERE EMBEDDING IS NOT NULL
ORDER BY DISTANCE
FETCH APPROX FIRST 10 ROWS ONLY
/* <OPTGUIDELINES> <IXSCAN TABLE='CUSTOMER_TEXT_CHUNKS'
   SEARCH_LIST_SIZE='100' SEARCH_BEAM_WIDTH='4'/> </OPTGUIDELINES> */;
```

**Search Parameters**:
- `SEARCH_LIST_SIZE`: Candidate list size (1-200, default 50)
- `SEARCH_BEAM_WIDTH`: Beam width for traversal (2-64, default 2)

## Maintenance Tasks

### Daily Tasks
- Monitor embedding generation queue
- Check API usage and costs
- Review query performance logs

### Weekly Tasks
- Update statistics: `RUNSTATS ON TABLE CUSTOMER_TEXT_CHUNKS AND INDEXES ALL`
- Check index fragmentation
- Review slow query log

### Monthly Tasks
- Rebuild indexes: `REORG INDEXES ALL FOR TABLE CUSTOMER_TEXT_CHUNKS`
- Archive old data
- Review and optimize chunk sizes
- Update embedding model if needed

## Next Steps

1. **Load Production Data**: Replace sample data with real customer data
2. **Customize Chunks**: Adjust text extraction UDFs for your use case
3. **Tune Parameters**: Optimize index and query parameters
4. **Build Applications**: Integrate semantic search into applications
5. **Monitor Performance**: Set up monitoring and alerting
6. **Scale Up**: Add more customers and optimize for production load

## Additional Resources

- [Db2 Vector Search Documentation](https://www.ibm.com/docs/en/db2/12.1.x?topic=list-vector-values)
- [Db2 JSON Functions Reference](https://www.ibm.com/docs/en/db2/12.1.x?topic=applications-json)
- [Llama-cpp](https://https://github.com/ggml-org/llama.cpp)
- [OpenAI Embeddings API](https://platform.openai.com/docs/guides/embeddings)

## Support

For issues or questions:
1. Check Db2 logs: `db2diag.log`
2. Review error messages in SQL output
3. Consult Db2 documentation
4. Contact IBM Support for EAP features
