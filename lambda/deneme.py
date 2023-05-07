import sys
import logging
import pymysql
import requests
from pyjstat import pyjstat
from collections import OrderedDict

rds_host="terraform-proxy-db.proxy-cq9xirobakjy.us-west-2.rds.amazonaws.com"
port=int(3306)
user_name = "admin"
password = "passw0rd!123"
db_name = "airqualitydatabase"

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# create the database connection outside of the handler to allow connections to be
# re-used by subsequent function invocations.
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

        logger.info("cleaning the Energy Consumption data")
        results = pyjstat.from_json_stat(response.json(object_pairs_hook=OrderedDict))
        df =results[0]
        df = df.rename(columns={'Geopolitical entity (reporting)': 'Country'})
        df_filtered = df.loc[df['Standard international energy product classification (SIEC)'] == 'Total']
        df_filtered = df_filtered.drop(['Time frequency','Energy balance','Unit of measure','Standard international energy product classification (SIEC)'], axis =1)
        nrg_con_total = df_filtered.pivot(index='Country' , columns='Time', values ='value')
        nrg_con_total = nrg_con_total[~nrg_con_total.index.str.startswith('Euro')]
        nrg_con_total = nrg_con_total.fillna(0)
        # Iterate over the dataset rows
        '''
        for _, row in nrg_con_total.iterrows():
            # Extract column names and values
            columns = ', '.join(row.keys())
            values = ', '.join(['%s'] * len(row))
        '''
        # creating column list for insertion
        cols = ",".join([str(i) for i in nrg_con_total.columns.tolist()])



        with connection.cursor() as cursor:
            # Generate the CREATE TABLE statement based on DataFrame columns
            create_table_query = f"CREATE TABLE IF NOT EXISTS energy_consumption ({nrg_con_total.index.name} varchar(255), `{'` FLOAT, `'.join(nrg_con_total.columns)}` FLOAT);"
            logger.info("Create table if it doesn't exist")
            logger.info(create_table_query)
            cursor.execute(create_table_query)
            logger.info("Table created")

            # Build and execute the SQL INSERT statement
            #insert_query = f"INSERT INTO energy_consumption ({columns}) VALUES ({values})"
            # Insert DataFrame records one by one
            for i, row in nrg_con_total.iterrows():
                # Build the SQL INSERT statement
                insert_query = "INSERT INTO movies_details (" + cols + ") VALUES (" + "%s," * (len(row) - 1) + "%s)"
                cursor.execute(insert_query, tuple(row()))

         # Commit the changes
        connection.commit()
    
        return {
                'statusCode': 200,
                'body': 'Data inserted successfully'
            }