import json
import requests
#from pyjstat import pyjstat


def lambda_handler(event, context):
    url = 'https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/nrg_pc_202?format=JSON&CURRENCY=EUR'
    response = requests.get(url)
    print(response.status_code)
    print(response.json())

    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda! ' + str(response.status_code))
    }
