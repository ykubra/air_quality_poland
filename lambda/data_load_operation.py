import sys
import logging
import pymysql
import json
import requests
from pyjstat import pyjstat
import pandas as pd
from collections import OrderedDict
import boto3
from botocore.exceptions import ClientError

# Set up a logger to handle INFO-level log messages
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Specify the name of the secret and the region where the secret is stored
secret_name = "rds-proxy-secret"
region_name = "us-west-2"

# Create a Secrets Manager client using the AWS SDK
session = boto3.session.Session()
client = session.client(
    service_name='secretsmanager',
    region_name=region_name
)
logger.info('Secrets Manager Client created succesfully')

# Retrieve the secret value from AWS Secrets Manager 
try:
    get_secret_value_response = client.get_secret_value(
        SecretId=secret_name
    )
except ClientError as e:
    logger.info("Couldn't get secret_value_response")
    raise e

# Read the secret value from AWS Secrets Manager and load it into a Python dictionary
secret = json.loads(get_secret_value_response['SecretString'])

# Log the secret value to the console
logger.info(secret)

# Extract the connection details from the dictionary
rds_host=secret["host"]
port=secret["port"]
user_name = secret["username"]
password = secret["password"]
db_name = secret["db_name"]


# Try to establish a connection to the MySQL database using the provided credentials 
try:
    connection = pymysql.connect(host=rds_host, user=user_name, passwd=password, db=db_name, connect_timeout=5)
except pymysql.MySQLError as e:
    logger.error("ERROR: Unexpected error: Could not connect to MySQL instance.")
    logger.error(e)
    sys.exit()

logger.info("SUCCESS: Connection to RDS MySQL instance succeeded")

def lambda_handler(event, context):
        logger.info("making API call to get Energy Consumption Data")
        url = 'https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/TEN00123?format=JSON'
        response = requests.get(url)

        # Clean the data : rename inconsistent column names, delete unnecessary columns, fill the Null and NaN values
        logger.info("Cleaning the Energy Consumption data")
        results = pyjstat.from_json_stat(response.json(object_pairs_hook=OrderedDict))
        df =results[0]
        df = df.rename(columns={'Geopolitical entity (reporting)': 'Country'})
        df_filtered = df.loc[df['Standard international energy product classification (SIEC)'] == 'Total']
        df_filtered = df_filtered.drop(['Time frequency','Energy balance','Unit of measure','Standard international energy product classification (SIEC)'], axis =1)
        nrg_con_total = df_filtered.pivot(index='Country' , columns='Time', values ='value')
        nrg_con_total = nrg_con_total[~nrg_con_total.index.str.startswith('Euro')]
        nrg_con_total = nrg_con_total.fillna(0)
        logger.info("Data Cleaned")

        # Create column list for insertion
        cols = "`" + nrg_con_total.index.name + "`, `" + "`,`".join([str(i) for i in nrg_con_total.columns.tolist()]) + "`"

        # Establish a connection to the MySQL database and create a cursor object
        with connection.cursor() as cursor:
            # Generate the CREATE TABLE statement based on DataFrame columns
            create_table_query = f"CREATE TABLE IF NOT EXISTS energy_consumption ({nrg_con_total.index.name} varchar(255) PRIMARY KEY, `{'` FLOAT, `'.join(nrg_con_total.columns)}` FLOAT);"

            logger.info("Create table if it doesn't exist")
            logger.info(create_table_query)
            cursor.execute(create_table_query)
            logger.info("Table created")
           
            # Insert DataFrame records one by one
            for i, row in nrg_con_total.iterrows():
                values = tuple([i] + row.tolist())
                placeholders = ",".join(["%s"] * len(values))

                # Build the INSERT statement with cols and placeholders
                insert_query = f"INSERT IGNORE INTO `energy_consumption` ({cols}) VALUES ({placeholders})"

                # Execute insert_query and add values
                cursor.execute(insert_query, values)
                logger.info("Values inserted to the table")
            # Select all rows and columns from the "energy_consumption" table
            cursor.execute("SELECT * FROM energy_consumption")

            # Fetch all the rows returned by the query and print them
            rows = cursor.fetchall()
            print(rows)

         # Commit the changes
        connection.commit()
        
        responseObject = {}
        responseObject['statusCode'] = 200
        responseObject['headers'] = {}
        responseObject['headers']['Content-Type'] = 'application/json'
        responseObject['body'] = json.dumps('Data inserted successfully')

        return responseObject