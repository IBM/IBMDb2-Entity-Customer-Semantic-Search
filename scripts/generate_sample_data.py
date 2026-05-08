#!/usr/bin/env python3
# Copyright 2026 Entity Customer Semantic Search in Db2 LUW Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Generate sample data files for Customer Semantic Search demo
Creates CSV files that can be loaded into DB2 tables
Configurable data generation with support for US and Canadian customers/stores
"""

import csv
import random
import argparse
from datetime import datetime, timedelta
from pathlib import Path

# ============================================================================
# Parse command line arguments
# ============================================================================
parser = argparse.ArgumentParser(
    description='Generate sample data files for Customer Semantic Search demo',
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog='''
Examples:
  %(prog)s                                    # Generate with defaults
  %(prog)s --seed 123                         # Custom seed
  %(prog)s --customers 100 --stores 20        # More customers and stores
  %(prog)s --customers 100 --us-customers 60  # 100 customers, 60 US
  %(prog)s --items 200 --min-purchases 5      # More items and purchases
  %(prog)s --return-rate 0.10                 # 10%% return rate
    '''
)

# Data size parameters
parser.add_argument(
    '-s', '--seed',
    type=int,
    default=42,
    help='Random seed for reproducible data generation (default: 42)'
)
parser.add_argument(
    '--customers',
    type=int,
    default=50,
    help='Total number of customers (default: 50)'
)
parser.add_argument(
    '--stores',
    type=int,
    default=10,
    help='Total number of stores (default: 10)'
)
parser.add_argument(
    '--items',
    type=int,
    default=50,
    help='Total number of items in catalog (default: 50)'
)
parser.add_argument(
    '--us-customers',
    type=int,
    default=30,
    help='Number of US customers, rest will be Canadian (default: 30)'
)
parser.add_argument(
    '--us-stores',
    type=int,
    default=5,
    help='Number of US stores, rest will be Canadian (default: 5)'
)
parser.add_argument(
    '--min-purchases',
    type=int,
    default=3,
    help='Minimum purchases per customer (default: 3)'
)
parser.add_argument(
    '--max-purchases',
    type=int,
    default=8,
    help='Maximum purchases per customer (default: 8)'
)
parser.add_argument(
    '--return-rate',
    type=float,
    default=0.05,
    help='Percentage of sales that result in returns, 0.05 = 5%% (default: 0.05)'
)
parser.add_argument(
    '--cross-border-rate',
    type=float,
    default=0.1,
    help='Chance of shopping in other country, 0.1 = 10%% (default: 0.1)'
)

args = parser.parse_args()

# Validate arguments
if args.us_customers > args.customers:
    parser.error(f"--us-customers ({args.us_customers}) cannot exceed --customers ({args.customers})")
if args.us_stores > args.stores:
    parser.error(f"--us-stores ({args.us_stores}) cannot exceed --stores ({args.stores})")
if args.min_purchases > args.max_purchases:
    parser.error(f"--min-purchases ({args.min_purchases}) cannot exceed --max-purchases ({args.max_purchases})")
if not 0 <= args.return_rate <= 1:
    parser.error(f"--return-rate must be between 0 and 1, got {args.return_rate}")
if not 0 <= args.cross_border_rate <= 1:
    parser.error(f"--cross-border-rate must be between 0 and 1, got {args.cross_border_rate}")

# ============================================================================
# CONFIGURATION - Set from command line arguments
# ============================================================================
NUM_CUSTOMERS = args.customers
NUM_STORES = args.stores
NUM_ITEMS = args.items
NUM_US_CUSTOMERS = args.us_customers
NUM_US_STORES = args.us_stores
MIN_PURCHASES_PER_CUSTOMER = args.min_purchases
MAX_PURCHASES_PER_CUSTOMER = args.max_purchases
RETURN_RATE = args.return_rate
CROSS_BORDER_SHOPPING_RATE = args.cross_border_rate

# Date range for sales data
SALES_START_DATE = datetime(2023, 1, 1)
SALES_END_DATE = datetime(2023, 12, 31)

# Create data directory
DATA_DIR = Path("data")
DATA_DIR.mkdir(exist_ok=True)

# Set random seed for reproducibility
RANDOM_SEED = args.seed
random.seed(RANDOM_SEED)

print("=" * 70)
print("📊 Data Generation Configuration")
print("=" * 70)
print(f"🎲 Random seed: {RANDOM_SEED}")
print(f"📁 Output directory: {DATA_DIR.absolute()}")
print(f"\n👥 Customers: {NUM_CUSTOMERS} total ({NUM_US_CUSTOMERS} US, {NUM_CUSTOMERS - NUM_US_CUSTOMERS} Canada)")
print(f"🏪 Stores: {NUM_STORES} total ({NUM_US_STORES} US, {NUM_STORES - NUM_US_STORES} Canada)")
print(f"📦 Items: {NUM_ITEMS}")
print(f"🛒 Purchases per customer: {MIN_PURCHASES_PER_CUSTOMER}-{MAX_PURCHASES_PER_CUSTOMER}")
print(f"↩️  Return rate: {RETURN_RATE * 100:.1f}%")
print(f"🌍 Cross-border shopping rate: {CROSS_BORDER_SHOPPING_RATE * 100:.1f}%")
print("=" * 70)
print()

def write_csv(filename, headers, rows):
    """Write data to CSV file"""
    filepath = DATA_DIR / filename
    with open(filepath, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f, delimiter='|')
        writer.writerow(headers)
        writer.writerows(rows)
    print(f"✓ Generated {filepath} ({len(rows)} rows)")

# ============================================================================
# Income Bands
# ============================================================================
income_bands = [
    (1, 0, 10000),
    (2, 10001, 20000),
    (3, 20001, 30000),
    (4, 30001, 40000),
    (5, 40001, 50000),
    (6, 50001, 60000),
    (7, 60001, 70000),
    (8, 70001, 80000),
    (9, 80001, 90000),
    (10, 90001, 100000),
    (11, 100001, 150000),
    (12, 150001, 200000),
]

write_csv('income_band.csv', 
          ['IB_INCOME_BAND_SK', 'IB_LOWER_BOUND', 'IB_UPPER_BOUND'],
          income_bands)

# ============================================================================
# Customer Demographics (50 entries)
# ============================================================================
genders = ['M', 'F']
marital_statuses = ['M', 'S', 'D', 'W']
education_levels = ['High School', 'College', 'Bachelor', 'Master', 'PhD']
credit_ratings = ['Excellent', 'Good', 'Fair', 'Poor']

customer_demographics = []
for i in range(1, NUM_CUSTOMERS + 1):
    cd_demo_sk = i
    cd_gender = random.choice(genders)
    cd_marital_status = random.choice(marital_statuses)
    cd_education_status = random.choice(education_levels)
    cd_purchase_estimate = random.randint(500, 10000)
    cd_credit_rating = random.choice(credit_ratings)
    cd_dep_count = random.randint(0, 5)
    cd_dep_employed_count = random.randint(0, cd_dep_count)
    cd_dep_college_count = random.randint(0, cd_dep_count)
    
    customer_demographics.append((cd_demo_sk, cd_gender, cd_marital_status, cd_education_status,
                                  cd_purchase_estimate, cd_credit_rating, cd_dep_count,
                                  cd_dep_employed_count, cd_dep_college_count))

write_csv('customer_demographics.csv',
          ['CD_DEMO_SK', 'CD_GENDER', 'CD_MARITAL_STATUS', 'CD_EDUCATION_STATUS',
           'CD_PURCHASE_ESTIMATE', 'CD_CREDIT_RATING', 'CD_DEP_COUNT',
           'CD_DEP_EMPLOYED_COUNT', 'CD_DEP_COLLEGE_COUNT'],
          customer_demographics)

# ============================================================================
# Household Demographics (50 entries)
# ============================================================================
buy_potentials = ['Unknown', '501-1000', '1001-5000', '5001+']

household_demographics = []
for i in range(1, NUM_CUSTOMERS + 1):
    hd_demo_sk = i
    hd_income_band_sk = random.randint(1, 12)
    hd_buy_potential = random.choice(buy_potentials)
    hd_dep_count = random.randint(0, 5)
    hd_vehicle_count = random.randint(0, 3)
    
    household_demographics.append((hd_demo_sk, hd_income_band_sk, hd_buy_potential,
                                   hd_dep_count, hd_vehicle_count))

write_csv('household_demographics.csv',
          ['HD_DEMO_SK', 'HD_INCOME_BAND_SK', 'HD_BUY_POTENTIAL', 
           'HD_DEP_COUNT', 'HD_VEHICLE_COUNT'],
          household_demographics)

# ============================================================================
# Customer Addresses (50 entries - mix of US and Canada)
# ============================================================================
us_cities = [
    ('Springfield', 'Sangamon', 'IL', '62701'),
    ('Chicago', 'Cook', 'IL', '60601'),
    ('Naperville', 'DuPage', 'IL', '60540'),
    ('Peoria', 'Peoria', 'IL', '61602'),
    ('Rockford', 'Winnebago', 'IL', '61101'),
    ('Aurora', 'Kane', 'IL', '60505'),
    ('Joliet', 'Will', 'IL', '60432'),
    ('Champaign', 'Champaign', 'IL', '61820'),
    ('Bloomington', 'McLean', 'IL', '61701'),
    ('Decatur', 'Macon', 'IL', '62521'),
]

ca_cities = [
    ('Toronto', 'Toronto', 'ON', 'M5B 2H1'),
    ('Richmond Hill', 'York Region', 'ON', 'L4S 1Z5'),
    ('Aurora', 'York Region', 'ON', 'L4G 6C1'),
    ('Ottawa', 'Ottawa', 'ON', 'K1P 1J1'),
    ('Mississauga', 'Peel', 'ON', 'L5B 1M2'),
    ('Brampton', 'Peel', 'ON', 'L6T 3T1'),
    ('Markham', 'York Region', 'ON', 'L3R 5H7'),
    ('Vaughan', 'York Region', 'ON', 'L4L 8A6'),
    ('Hamilton', 'Hamilton', 'ON', 'L8P 4R5'),
    ('Kitchener', 'Waterloo', 'ON', 'N2G 1C5'),
]

street_names = ['Main', 'Oak', 'Elm', 'Pine', 'Maple', 'Cedar', 'Birch', 'Willow', 'Spruce', 'Ash']
street_types = ['Street', 'Avenue', 'Drive', 'Road', 'Lane', 'Court', 'Boulevard', 'Way']
location_types = ['apartment', 'condo', 'single family']

customer_addresses = []
for i in range(1, NUM_CUSTOMERS + 1):
    ca_address_sk = i
    ca_address_id = f'ADDR{i:03d}'
    ca_street_number = str(random.randint(100, 999))
    ca_street_name = random.choice(street_names)
    ca_street_type = random.choice(street_types)
    ca_suite_number = f'Suite {random.randint(100, 999)}' if random.random() < 0.3 else ''
    ca_location_type = random.choice(location_types)
    
    # Split addresses between US and Canada based on configuration
    if i <= NUM_US_CUSTOMERS:
        city, county, state, zip_code = random.choice(us_cities)
        country = 'United States'
        gmt_offset = -6.00
    else:
        city, county, state, zip_code = random.choice(ca_cities)
        country = 'Canada'
        gmt_offset = -5.00
    
    customer_addresses.append((ca_address_sk, ca_address_id, ca_street_number, ca_street_name,
                              ca_street_type, ca_suite_number, city, county, state, zip_code,
                              country, gmt_offset, ca_location_type))

write_csv('customer_address.csv',
          ['CA_ADDRESS_SK', 'CA_ADDRESS_ID', 'CA_STREET_NUMBER', 'CA_STREET_NAME', 
           'CA_STREET_TYPE', 'CA_SUITE_NUMBER', 'CA_CITY', 'CA_COUNTY', 'CA_STATE', 
           'CA_ZIP', 'CA_COUNTRY', 'CA_GMT_OFFSET', 'CA_LOCATION_TYPE'],
          customer_addresses)

# ============================================================================
# Customers (50 entries)
# ============================================================================
first_names_m = ['John', 'Michael', 'David', 'Robert', 'James', 'William', 'Richard', 'Thomas', 'Charles', 'Daniel']
first_names_f = ['Sarah', 'Emily', 'Jennifer', 'Patricia', 'Lisa', 'Mary', 'Linda', 'Barbara', 'Susan', 'Jessica']
last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Martinez', 'Rodriguez', 'Wilson', 'Anderson',
              'Taylor', 'Thomas', 'Moore', 'Jackson', 'Martin', 'Lee', 'Thompson', 'White', 'Harris', 'Clark']
salutations_m = ['Mr.', 'Dr.', 'Prof.']
salutations_f = ['Ms.', 'Mrs.', 'Dr.', 'Prof.']

customers = []
for i in range(1, NUM_CUSTOMERS + 1):
    c_customer_sk = i
    c_customer_id = f'CUST{i:06d}'
    c_current_cdemo_sk = i
    c_current_hdemo_sk = i
    c_current_addr_sk = i
    
    # Determine gender from demographics
    gender = customer_demographics[i-1][1]
    
    if gender == 'M':
        c_salutation = random.choice(salutations_m)
        c_first_name = random.choice(first_names_m)
    else:
        c_salutation = random.choice(salutations_f)
        c_first_name = random.choice(first_names_f)
    
    c_last_name = random.choice(last_names)
    c_preferred_cust_flag = random.choice(['Y', 'N'])
    c_birth_day = random.randint(1, 28)
    c_birth_month = random.randint(1, 12)
    c_birth_year = random.randint(1960, 2000)
    
    # Birth country matches address country
    c_birth_country = customer_addresses[i-1][10]  # country from address
    
    c_login = f"{c_first_name[0].lower()}{c_last_name.lower()}"
    c_email_address = f"{c_first_name.lower()}.{c_last_name.lower()}@email.com"
    
    # Random dates in 2023
    days_offset = random.randint(1, 300)
    first_date = 20230101 + days_offset
    c_first_shipto_date_sk = first_date
    c_first_sales_date_sk = first_date + random.randint(1, 14)
    c_last_review_date = first_date + 10000  # One year later
    
    customers.append((c_customer_sk, c_customer_id, c_current_cdemo_sk, c_current_hdemo_sk,
                     c_current_addr_sk, c_first_shipto_date_sk, c_first_sales_date_sk,
                     c_salutation, c_first_name, c_last_name, c_preferred_cust_flag,
                     c_birth_day, c_birth_month, c_birth_year, c_birth_country,
                     c_login, c_email_address, c_last_review_date))

write_csv('customer.csv',
          ['C_CUSTOMER_SK', 'C_CUSTOMER_ID', 'C_CURRENT_CDEMO_SK', 'C_CURRENT_HDEMO_SK', 
           'C_CURRENT_ADDR_SK', 'C_FIRST_SHIPTO_DATE_SK', 'C_FIRST_SALES_DATE_SK', 
           'C_SALUTATION', 'C_FIRST_NAME', 'C_LAST_NAME', 'C_PREFERRED_CUST_FLAG', 
           'C_BIRTH_DAY', 'C_BIRTH_MONTH', 'C_BIRTH_YEAR', 'C_BIRTH_COUNTRY', 
           'C_LOGIN', 'C_EMAIL_ADDRESS', 'C_LAST_REVIEW_DATE'],
          customers)

# ============================================================================
# Stores (configurable split between US and Canada)
# ============================================================================
# Generate stores dynamically based on configuration
stores = []
us_store_names = ['Springfield Mall Store', 'Chicago Downtown Store', 'Naperville Plaza Store',
                  'Peoria Center Store', 'Rockford Mall Store', 'Aurora Plaza Store',
                  'Joliet Center Store', 'Champaign Mall Store', 'Bloomington Store', 'Decatur Store']
ca_store_names = ['Toronto Eaton Centre Store', 'Richmond Hill Centre Store', 'Ottawa Rideau Store',
                  'Mississauga Square One Store', 'Markham Pacific Mall Store', 'Brampton Store',
                  'Vaughan Mills Store', 'Hamilton Centre Store', 'Kitchener Store', 'London Store']

for i in range(1, NUM_STORES + 1):
    if i <= NUM_US_STORES:
        # US Store
        store_name = us_store_names[i-1] if i <= len(us_store_names) else f'US Store {i}'
        stores.append((i, f'STORE{i:03d}', '2020-01-01', '', '', store_name,
                      random.randint(100, 200), random.randint(40000, 75000), '9AM-9PM',
                      'Store Manager', 1, 'Midwest', 'Illinois Market', 'Jane Smith',
                      1, 'Central Division', 1, 'RetailCo', str(random.randint(100, 999)),
                      random.choice(['Main', 'State', 'Commerce']),
                      random.choice(['Street', 'Avenue', 'Drive']), '',
                      random.choice(['Springfield', 'Chicago', 'Naperville']),
                      random.choice(['Sangamon', 'Cook', 'DuPage']), 'IL',
                      f'{random.randint(60000, 62999)}', 'United States', -6.00, 0.0725))
    else:
        # Canadian Store
        ca_idx = i - NUM_US_STORES - 1
        store_name = ca_store_names[ca_idx] if ca_idx < len(ca_store_names) else f'CA Store {i}'
        stores.append((i, f'STORE{i:03d}', '2020-01-01', '', '', store_name,
                      random.randint(140, 180), random.randint(52000, 65000), '9AM-9PM',
                      'Store Manager', 2, 'Urban', 'Ontario Market', 'Margaret Wong',
                      2, 'Canada Division', 1, 'RetailCo', str(random.randint(100, 999)),
                      random.choice(['Yonge', 'Rideau', 'City Centre']),
                      random.choice(['Street', 'Avenue', 'Drive']), '',
                      random.choice(['Toronto', 'Richmond Hill', 'Ottawa']),
                      random.choice(['Toronto', 'York Region', 'Ottawa']), 'ON',
                      f'M{random.randint(1,9)}B {random.randint(1,9)}H{random.randint(1,9)}',
                      'Canada', -5.00, 0.13))

write_csv('store.csv',
          ['S_STORE_SK', 'S_STORE_ID', 'S_REC_START_DATE', 'S_REC_END_DATE', 'S_CLOSED_DATE_SK', 
           'S_STORE_NAME', 'S_NUMBER_EMPLOYEES', 'S_FLOOR_SPACE', 'S_HOURS', 'S_MANAGER', 
           'S_MARKET_ID', 'S_GEOGRAPHY_CLASS', 'S_MARKET_DESC', 'S_MARKET_MANAGER', 
           'S_DIVISION_ID', 'S_DIVISION_NAME', 'S_COMPANY_ID', 'S_COMPANY_NAME', 
           'S_STREET_NUMBER', 'S_STREET_NAME', 'S_STREET_TYPE', 'S_SUITE_NUMBER', 
           'S_CITY', 'S_COUNTY', 'S_STATE', 'S_ZIP', 'S_COUNTRY', 'S_GMT_OFFSET', 'S_TAX_PERCENTAGE'],
          stores)

# ============================================================================
# Items (configurable number)
# ============================================================================
categories = ['Electronics', 'Apparel', 'Home', 'Sports', 'Health', 'Office', 'Toys', 'Books', 'Beauty', 'Automotive']
item_templates = [
    ('Wireless Bluetooth Headphones', 'Electronics', 'Audio', ['Black', 'White', 'Silver']),
    ('Smart Watch Fitness Tracker', 'Electronics', 'Wearables', ['Black', 'Silver', 'Rose Gold']),
    ('Cotton T-Shirt Crew Neck', 'Apparel', 'Shirts', ['Blue', 'Red', 'Green', 'Black', 'White']),
    ('Water Bottle Insulated', 'Home', 'Bottles', ['Green', 'Blue', 'Silver', 'Black']),
    ('Yoga Mat Non-Slip', 'Sports', 'Exercise', ['Purple', 'Blue', 'Green', 'Pink']),
    ('Coffee Maker Programmable', 'Home', 'Appliances', ['Black', 'Silver', 'White']),
    ('Running Shoes Lightweight', 'Sports', 'Footwear', ['Red', 'Blue', 'Black', 'White']),
    ('LED Desk Lamp Adjustable', 'Office', 'Lighting', ['White', 'Black', 'Silver']),
    ('Protein Powder Whey', 'Health', 'Supplements', ['Vanilla', 'Chocolate', 'Strawberry']),
    ('Laptop Backpack', 'Office', 'Bags', ['Navy', 'Black', 'Gray']),
]

items = []
for i in range(1, NUM_ITEMS + 1):
    template = item_templates[i % len(item_templates)]
    item_desc = template[0]
    category = template[1]
    item_class = template[2]
    color = random.choice(template[3])
    
    i_item_sk = i
    i_item_id = f'ITEM{i:06d}'
    i_rec_start_date = '2023-01-01'
    i_rec_end_date = ''
    i_item_desc = f"{item_desc} {color}"
    i_current_price = round(random.uniform(19.99, 299.99), 2)
    i_wholesale_cost = round(i_current_price * 0.5, 2)
    i_brand_id = (i % 10) + 1
    i_brand = f"Brand{i_brand_id}"
    i_class_id = (i % 10) + 1
    i_class = item_class
    i_category_id = (i % 10) + 1
    i_category = category
    i_manufact_id = (i % 10) + 1
    i_manufact = f"Manufacturer{i_manufact_id}"
    i_size = random.choice(['Small', 'Medium', 'Large', 'XL'])
    i_formulation = random.choice(['Standard', 'Premium', 'Deluxe'])
    i_color = color
    i_units = 'Each'
    i_container = random.choice(['Box', 'Bag', 'Container'])
    i_manager_id = (i % 5) + 1
    i_product_name = item_desc
    
    items.append((i_item_sk, i_item_id, i_rec_start_date, i_rec_end_date, i_item_desc,
                 i_current_price, i_wholesale_cost, i_brand_id, i_brand, i_class_id,
                 i_class, i_category_id, i_category, i_manufact_id, i_manufact,
                 i_size, i_formulation, i_color, i_units, i_container,
                 i_manager_id, i_product_name))

write_csv('item.csv',
          ['I_ITEM_SK', 'I_ITEM_ID', 'I_REC_START_DATE', 'I_REC_END_DATE', 'I_ITEM_DESC', 
           'I_CURRENT_PRICE', 'I_WHOLESALE_COST', 'I_BRAND_ID', 'I_BRAND', 'I_CLASS_ID', 
           'I_CLASS', 'I_CATEGORY_ID', 'I_CATEGORY', 'I_MANUFACT_ID', 'I_MANUFACT', 
           'I_SIZE', 'I_FORMULATION', 'I_COLOR', 'I_UNITS', 'I_CONTAINER', 
           'I_MANAGER_ID', 'I_PRODUCT_NAME'],
          items)

# ============================================================================
# Date Dimension (based on configured date range)
# ============================================================================
dates = []
current_date = SALES_START_DATE

while current_date <= SALES_END_DATE:
    d_date_sk = int(current_date.strftime('%Y%m%d'))
    d_date_id = current_date.strftime('%Y%m%d')
    d_date = current_date.strftime('%Y-%m-%d')
    d_year = current_date.year
    d_dow = current_date.isoweekday()
    d_moy = current_date.month
    d_dom = current_date.day
    d_qoy = (current_date.month - 1) // 3 + 1
    d_day_name = current_date.strftime('%A')
    d_quarter_name = f'Q{d_qoy}'
    d_holiday = 'N'
    d_weekend = 'Y' if d_dow in [6, 7] else 'N'
    d_current_day = 'N'
    d_current_week = 'N'
    d_current_month = 'N'
    d_current_quarter = 'N'
    d_current_year = 'N'
    
    dates.append((d_date_sk, d_date_id, d_date, '', '', '', d_year, d_dow, d_moy, d_dom, 
                  d_qoy, '', '', '', d_day_name, d_quarter_name, d_holiday, d_weekend, 
                  '', '', '', '', '', d_current_day, d_current_week, d_current_month, 
                  d_current_quarter, d_current_year))
    
    current_date += timedelta(days=1)

write_csv('date_dim.csv',
          ['D_DATE_SK', 'D_DATE_ID', 'D_DATE', 'D_MONTH_SEQ', 'D_WEEK_SEQ', 'D_QUARTER_SEQ',
           'D_YEAR', 'D_DOW', 'D_MOY', 'D_DOM', 'D_QOY', 'D_FY_YEAR', 'D_FY_QUARTER_SEQ',
           'D_FY_WEEK_SEQ', 'D_DAY_NAME', 'D_QUARTER_NAME', 'D_HOLIDAY', 'D_WEEKEND',
           'D_FOLLOWING_HOLIDAY', 'D_FIRST_DOM', 'D_LAST_DOM', 'D_SAME_DAY_LY',
           'D_SAME_DAY_LQ', 'D_CURRENT_DAY', 'D_CURRENT_WEEK', 'D_CURRENT_MONTH',
           'D_CURRENT_QUARTER', 'D_CURRENT_YEAR'],
          dates)

# ============================================================================
# Store Sales (Generate realistic sales data)
# ============================================================================
print("Generating store sales data...")
store_sales = []
ticket_number = 1000

for customer_sk in range(1, NUM_CUSTOMERS + 1):
    # Determine if customer is Canadian
    is_canadian = customer_sk > NUM_US_CUSTOMERS
    
    # Canadian customers shop mostly at Canadian stores
    # US customers shop mostly at US stores
    if is_canadian:
        available_stores = list(range(NUM_US_STORES + 1, NUM_STORES + 1))
        # Occasionally shop at US stores
        if random.random() < CROSS_BORDER_SHOPPING_RATE:
            available_stores.extend(range(1, NUM_US_STORES + 1))
    else:
        available_stores = list(range(1, NUM_US_STORES + 1))
        # Occasionally shop at Canadian stores
        if random.random() < CROSS_BORDER_SHOPPING_RATE:
            available_stores.extend(range(NUM_US_STORES + 1, NUM_STORES + 1))
    
    # Each customer makes a random number of purchases
    num_purchases = random.randint(MIN_PURCHASES_PER_CUSTOMER, MAX_PURCHASES_PER_CUSTOMER)
    customer_stores = random.sample(available_stores, min(random.randint(2, 3), len(available_stores)))
    
    for _ in range(num_purchases):
        # Random date in 2023
        days_offset = random.randint(1, 350)
        sold_date_sk = 20230101 + days_offset
        sold_time_sk = random.randint(28800, 72000)  # 8 AM to 8 PM
        
        # Random item
        item_sk = random.randint(1, NUM_ITEMS)
        item_price = items[item_sk - 1][5]  # current_price
        wholesale_cost = items[item_sk - 1][6]
        
        # Random store from customer's preferred stores
        store_sk = random.choice(customer_stores)
        
        # Quantity
        quantity = random.randint(1, 3)
        
        # Calculate amounts
        ss_list_price = item_price
        ss_sales_price = item_price
        ss_ext_discount_amt = 0.00
        ss_ext_sales_price = round(ss_sales_price * quantity, 2)
        ss_ext_wholesale_cost = round(wholesale_cost * quantity, 2)
        ss_ext_list_price = round(ss_list_price * quantity, 2)
        ss_ext_tax = round(ss_ext_sales_price * 0.0725, 2)  # Simplified tax
        ss_coupon_amt = 0.00
        ss_net_paid = ss_ext_sales_price
        ss_net_paid_inc_tax = round(ss_net_paid + ss_ext_tax, 2)
        ss_net_profit = round(ss_ext_sales_price - ss_ext_wholesale_cost, 2)
        
        store_sales.append((sold_date_sk, sold_time_sk, item_sk, customer_sk,
                           customer_sk, customer_sk, customer_sk, store_sk, 1,
                           ticket_number, quantity, wholesale_cost, ss_list_price,
                           ss_sales_price, ss_ext_discount_amt, ss_ext_sales_price,
                           ss_ext_wholesale_cost, ss_ext_list_price, ss_ext_tax,
                           ss_coupon_amt, ss_net_paid, ss_net_paid_inc_tax, ss_net_profit))
        
        ticket_number += 1

write_csv('store_sales.csv',
          ['SS_SOLD_DATE_SK', 'SS_SOLD_TIME_SK', 'SS_ITEM_SK', 'SS_CUSTOMER_SK', 
           'SS_CDEMO_SK', 'SS_HDEMO_SK', 'SS_ADDR_SK', 'SS_STORE_SK', 'SS_PROMO_SK', 
           'SS_TICKET_NUMBER', 'SS_QUANTITY', 'SS_WHOLESALE_COST', 'SS_LIST_PRICE', 
           'SS_SALES_PRICE', 'SS_EXT_DISCOUNT_AMT', 'SS_EXT_SALES_PRICE', 
           'SS_EXT_WHOLESALE_COST', 'SS_EXT_LIST_PRICE', 'SS_EXT_TAX', 'SS_COUPON_AMT', 
           'SS_NET_PAID', 'SS_NET_PAID_INC_TAX', 'SS_NET_PROFIT'],
          store_sales)

# ============================================================================
# Store Returns (About 5% of sales)
# ============================================================================
print("Generating store returns data...")
store_returns = []
num_returns = int(len(store_sales) * 0.05)
return_indices = random.sample(range(len(store_sales)), num_returns)

for idx in return_indices:
    sale = store_sales[idx]
    
    # Return happens 7-30 days after purchase
    return_date_sk = sale[0] + random.randint(7, 30)
    return_time_sk = random.randint(28800, 72000)
    
    sr_item_sk = sale[2]
    sr_customer_sk = sale[3]
    sr_cdemo_sk = sale[4]
    sr_hdemo_sk = sale[5]
    sr_addr_sk = sale[6]
    sr_store_sk = sale[7]
    sr_reason_sk = 1
    sr_ticket_number = sale[9]
    sr_return_quantity = sale[10]  # Return all items
    sr_return_amt = sale[15]  # ext_sales_price
    sr_return_tax = sale[18]
    sr_return_amt_inc_tax = sale[20]
    sr_fee = 10.00
    sr_return_ship_cost = 5.00
    sr_refunded_cash = sr_return_amt
    sr_reversed_charge = 0.00
    sr_store_credit = 0.00
    sr_net_loss = sale[22]  # net_profit
    
    store_returns.append((return_date_sk, return_time_sk, sr_item_sk, sr_customer_sk,
                         sr_cdemo_sk, sr_hdemo_sk, sr_addr_sk, sr_store_sk, sr_reason_sk,
                         sr_ticket_number, sr_return_quantity, sr_return_amt, sr_return_tax,
                         sr_return_amt_inc_tax, sr_fee, sr_return_ship_cost, sr_refunded_cash,
                         sr_reversed_charge, sr_store_credit, sr_net_loss))

write_csv('store_returns.csv',
          ['SR_RETURNED_DATE_SK', 'SR_RETURN_TIME_SK', 'SR_ITEM_SK', 'SR_CUSTOMER_SK', 
           'SR_CDEMO_SK', 'SR_HDEMO_SK', 'SR_ADDR_SK', 'SR_STORE_SK', 'SR_REASON_SK', 
           'SR_TICKET_NUMBER', 'SR_RETURN_QUANTITY', 'SR_RETURN_AMT', 'SR_RETURN_TAX', 
           'SR_RETURN_AMT_INC_TAX', 'SR_FEE', 'SR_RETURN_SHIP_COST', 'SR_REFUNDED_CASH', 
           'SR_REVERSED_CHARGE', 'SR_STORE_CREDIT', 'SR_NET_LOSS'],
          store_returns)

print("\n✅ All sample data files generated successfully!")
print(f"📁 Data files are in: {DATA_DIR.absolute()}")
print(f"🎲 Random seed used: {RANDOM_SEED}")
print(f"\n📊 Summary:")
print(f"  - {NUM_CUSTOMERS} customers ({NUM_US_CUSTOMERS} US, {NUM_CUSTOMERS - NUM_US_CUSTOMERS} Canada)")
print(f"  - {NUM_STORES} stores ({NUM_US_STORES} US, {NUM_STORES - NUM_US_STORES} Canada)")
print(f"  - {NUM_ITEMS} items")
print(f"  - {len(store_sales)} sales transactions")
print(f"  - {len(store_returns)} returns")
print("\nNext step: Run ./run_all.sh to load the data into DB2")
print(f"\nTo regenerate with a different seed: python3 {__file__} --seed <number>")

# Made with Bob