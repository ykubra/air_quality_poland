import sys
import logging
import pymysql
import json

# rds settings
rds_host  = "mydb.c90zzxhsmdkg.us-west-2.rds.amazonaws.com"
user_name = "admin"
password = "passw0rd!123"
db_name = "mydb"

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
    """
    This function creates a new RDS database table and writes records to it
    """
    message = event['Records'][0]['body']
    data = json.loads(message)
    CustID = data['CustID']
    Name = data['Name']

    item_count = 0
    sql_create_table = f"CREATE TABLE Customer ( CustID  int NOT NULL, Name varchar(255) NOT NULL, PRIMARY KEY (CustID))"
    sql_string = f"insert into Customer (CustID, Name) values({CustID}, '{Name}')"

    with connection.cursor() as cursor:
        if Name == "create":
            cursor.execute(sql_create_table)
            connection.commit()

        cursor.execute("create table if not exists Customer ( CustID  int NOT NULL, Name varchar(255) NOT NULL, PRIMARY KEY (CustID))")
        cursor.execute(sql_string)
        connection.commit()

        cursor.execute("select * from Customer")
        logger.info("The following items have been added to the database:")

        for row in cursor:
            item_count += 1
            logger.info(row)
    connection.commit()

    return "Added %d items to RDS MySQL table" %(item_count)
