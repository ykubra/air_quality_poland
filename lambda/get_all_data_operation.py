import json
import sys
import pymysql
import logging
from botocore.exceptions import ClientError
import boto3


logger = logging.getLogger()
logger.setLevel(logging.INFO) 

secret_name = "rds-proxy-secret"
region_name = "us-west-2"

# Create a Secrets Manager client
session = boto3.session.Session()
client = session.client(
    service_name='secretsmanager',
    region_name=region_name
)
logger.info('Secrets Manager Client created succesfully')
try:
    get_secret_value_response = client.get_secret_value(
        SecretId=secret_name
    )
except ClientError as e:
    logger.info("Couldn't get secret_value_response")
    raise e

# Decrypts secret using the associated KMS key.
secret = json.loads(get_secret_value_response['SecretString'])
logger.info(secret)

rds_host=secret["host"]
port=secret["port"]
user_name = secret["username"]
password = secret["password"]
db_name = secret["db_name"]


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
	logger.info("print the table")
    
	with connection.cursor() as cursor:  
		cursor.execute("SELECT * FROM energy_consumption")

			# fetch all rows from the result set
		rows = cursor.fetchall()
			
			# print the rows
		for row in rows:
			print(row)

		# Commit the changes
	connection.commit()
        
	# Construct the body of the response object
	response = {}
	response['message'] = rows

	# Construct http response object
	responseObject = {}
	responseObject['statusCode'] = 200
	responseObject['headers'] = {}
	responseObject['headers']['Content-Type'] = 'application/json'
	responseObject['body'] = json.dumps(response)

	# Return the response object
	return responseObject
			


# 1. connect to rds
# 2. get table from rds
# 3. return it