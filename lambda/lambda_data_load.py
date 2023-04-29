import sys
import logging
import pymysql
import json
import requests
from pyjstat import pyjstat
import pandas as pd

from collections import OrderedDict
from sqlalchemy import create_engine

# rds settings
rds_host  = "terraform-proxy-db.proxy-cgzqqxf93pea.us-west-2.rds.amazonaws.com"
user_name = "admin"
password = "passw0rd!123"
db_name = "airqualitydatabase"

def lambda_handler(event, context):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

# create the database connection outside of the handler to allow connections to be
# re-used by subsequent function invocations.
    try:
        #connection = pymysql.connect(host=rds_host, user=user_name, passwd=password, db=db_name, connect_timeout=5)
        db_url = f'mysql+pymysql://admin:passw0rd!123@hostname:port/airqualitydatabase'
        engine = create_engine(db_url)


        logger.info("SUCCESS: Connection to RDS MySQL instance succeeded")


   
        with engine.connect() as conn:
            url = 'https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/TEN00123?format=JSON'
            response = requests.get(url)
            dataset = pyjstat.Dataset.read(response.text)
            results = pyjstat.from_json_stat(response.json(object_pairs_hook=OrderedDict))
            df =results[0]
            df = df.rename(columns={'Geopolitical entity (reporting)': 'Country'})
            df_filtered = df.loc[df['Standard international energy product classification (SIEC)'] == 'Total']
            df_filtered = df_filtered.drop(['Time frequency','Energy balance','Unit of measure','Standard international energy product classification (SIEC)'], axis =1)
            nrg_con_total = df_filtered.pivot(index='Country' , columns='Time', values ='value')
            nrg_con_total = nrg_con_total[~nrg_con_total.index.str.startswith('Euro')]
            nrg_con_total = nrg_con_total.fillna(0)
            # Bulk insert the DataFrame into the SQL table
            table_name = 'energy_consumption'
            nrg_con_total.to_sql(table_name, engine, if_exists='replace', index=False)

            # Retrieve the column names and convert the DataFrame to a list of tuples
            columns = nrg_con_total.columns.tolist()
            values = nrg_con_total.values.tolist()
            # Generate the SQL statement for bulk insert
            stmt = f"INSERT INTO {table_name} ({', '.join(columns)}) VALUES %s"
            # Execute the bulk insert
            conn.execute(stmt, values)

            return {
                'statusCode': 200,
                'body': 'Data inserted successfully'
            }
    except pymysql.MySQLError as e:
        logger.error("ERROR: Unexpected error: Could not connect to MySQL instance.")
        logger.error(e)
        sys.exit()