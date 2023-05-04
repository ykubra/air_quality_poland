import json

print('Loading function')

def lambda_handler(event, context):
	#1. Parse out query string params
	name = event['queryStringParameters']['name']
	
	print('name = ' + name)

	#2. Construct the body of the response object
	response = {}
	response['message'] = f"Hello from Lambda land {name}"

	#3. Construct http response object
	responseObject = {}
	responseObject['statusCode'] = 200
	responseObject['headers'] = {}
	responseObject['headers']['Content-Type'] = 'application/json'
	responseObject['body'] = json.dumps(response)

	#4. Return the response object
	return responseObject