import json
import sys
import pymysql
import logging
from botocore.exceptions import ClientError
import boto3

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
	logger.info("Print the table")
        
    # Establish a connection to the MySQL database and create a cursor object
	with connection.cursor() as cursor:  
                
        # Select all rows and columns from the "energy_consumption" table
		cursor.execute("SELECT * FROM energy_consumption")

		# Fetch all the rows returned by the query 
		rows = cursor.fetchall()
			
		# Print the rows
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
			


