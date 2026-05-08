# Data Generation Scripts

## Overview

This directory contains scripts to generate sample data for the Customer Semantic Search demo with support for US and Canadian customers/stores.

## generate_sample_data.py

Python script that generates CSV files with configurable sample data for all tables.

### Requirements

- Python 3.6 or higher (no external dependencies required)

### Basic Usage

```bash
# Generate data files with defaults (50 customers, 10 stores, 50 items)
python3 scripts/generate_sample_data.py

# View all available options
python3 scripts/generate_sample_data.py --help
```

### Command-Line Options

#### Data Size Parameters
- `--customers N` - Total number of customers (default: 50)
- `--stores N` - Total number of stores (default: 10)
- `--items N` - Total number of items in catalog (default: 50)

#### Geographic Distribution
- `--us-customers N` - Number of US customers, rest will be Canadian (default: 30)
- `--us-stores N` - Number of US stores, rest will be Canadian (default: 5)

#### Purchase Behavior
- `--min-purchases N` - Minimum purchases per customer (default: 3)
- `--max-purchases N` - Maximum purchases per customer (default: 8)

#### Rates
- `--return-rate F` - Return rate as decimal, 0.05 = 5% (default: 0.05)
- `--cross-border-rate F` - Cross-border shopping rate, 0.1 = 10% (default: 0.1)

#### Reproducibility
- `-s, --seed N` - Random seed for reproducible data generation (default: 42)

### Usage Examples

```bash
# Generate with default settings
python3 scripts/generate_sample_data.py

# Generate with custom seed for different data
python3 scripts/generate_sample_data.py --seed 999

# Generate larger dataset
python3 scripts/generate_sample_data.py --customers 200 --stores 30 --items 150

# Generate with more US customers and stores
python3 scripts/generate_sample_data.py --customers 100 --us-customers 70 --stores 20 --us-stores 15

# Generate with higher return rate
python3 scripts/generate_sample_data.py --return-rate 0.15  # 15% returns

# Generate with more purchases per customer
python3 scripts/generate_sample_data.py --min-purchases 5 --max-purchases 15

# Combine multiple options
python3 scripts/generate_sample_data.py \
  --seed 123 \
  --customers 100 \
  --us-customers 60 \
  --stores 20 \
  --items 200 \
  --return-rate 0.08
```

### Generated Files

This will create a `data/` directory with the following CSV files:

- `income_band.csv` - 12 income bands
- `customer_demographics.csv` - Customer demographic profiles (configurable count)
- `household_demographics.csv` - Household profiles (configurable count)
- `customer_address.csv` - Customer addresses (US and Canada, configurable split)
- `customer.csv` - Sample customers (configurable count)
- `store.csv` - Retail stores (US and Canada, configurable split)
- `item.csv` - Product catalog (configurable count)
- `date_dim.csv` - Date dimension (365 dates for 2023)
- `store_sales.csv` - Sales transactions (based on customer/purchase settings)
- `store_returns.csv` - Return transactions (based on return rate)

### Data Format

All CSV files use:
- Pipe delimiter (`|`)
- Header row with column names
- UTF-8 encoding

### Data Characteristics

**Geographic Distribution:**
- Customers split between US (Illinois) and Canada (Ontario)
- Stores split between US and Canadian locations
- Cross-border shopping supported (configurable rate)

**Realistic Patterns:**
- Customers primarily shop at stores in their country
- Occasional cross-border shopping based on configured rate
- Varied purchase amounts and frequencies
- Returns occur at configured rate

### Integration with run_all.sh

The `run_all.sh` script automatically:
1. Checks if data files exist
2. Generates them if missing (with default settings)
3. Loads them into DB2 using IMPORT commands

You can also manually generate data:

```bash
# Regenerate all data files with defaults
rm -rf data/
python3 scripts/generate_sample_data.py

# Regenerate with custom settings
rm -rf data/
python3 scripts/generate_sample_data.py --customers 100 --seed 456
```

### Customization

**Via Command Line (Recommended):**
```bash
# Generate different dataset sizes
python3 scripts/generate_sample_data.py --customers 200 --stores 30

# Use different random seed for varied data
python3 scripts/generate_sample_data.py --seed 999

# Reload data into DB2
./run_all.sh -s 2
```

**Via Code Editing:**
1. Edit `generate_sample_data.py` for advanced customization
2. Regenerate files: `python3 scripts/generate_sample_data.py`
3. Reload data: `./run_all.sh -s 2`

## Benefits of CSV-Based Loading

✅ **Simpler SQL** - No complex recursive CTEs or INSERT statements
✅ **Faster Loading** - DB2 IMPORT is optimized for bulk data
✅ **Easier Testing** - Can inspect/modify CSV files directly
✅ **Reusable** - Same data files can be used across environments
✅ **Maintainable** - Python is easier to modify than complex SQL