import boto3
import json
from decimal import Decimal

def format_item(item):
    """Helper function to format DynamoDB item."""
    formatted_item = {}
    for key, value in item.items():
        if isinstance(value, dict):
            # Recursively format nested dictionaries
            if 'S' in value:
                formatted_item[key] = value['S']
            elif 'N' in value:
                formatted_item[key] = float(value['N'])  # Convert decimal.Decimal to float
            elif 'BOOL' in value:
                formatted_item[key] = value['BOOL']
            elif 'L' in value:
                formatted_item[key] = [format_item(v) if isinstance(v, dict) else format_value(v) for v in value['L']]
            elif 'M' in value:
                formatted_item[key] = format_item(value['M'])
            else:
                formatted_item[key] = format_value(value)
        else:
            formatted_item[key] = format_value(value)
    return formatted_item

def format_value(value):
    """Helper function to format individual DynamoDB values."""
    if isinstance(value, Decimal):
        return float(value)  # Convert decimal.Decimal to float
    return value

def lambda_handler(event, context):
    # Initialize a session using Amazon DynamoDB
    print(event)
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('Books')
    
    # Check if 'queryStringParameters' exists in the event object
    if 'queryStringParameters' in event and 'bookid' in event['queryStringParameters']:
        try:
            # Parse the bookid from the event
            bookid = int(event['queryStringParameters']['bookid'])
            
            # Define the key to retrieve the item
            response = table.get_item(
                Key={
                    'bookid': bookid
                }
            )
            
            # Check if the item was found
            if 'Item' in response:
                # Return the retrieved item
                return {
                    'statusCode': 200,
                    'body': json.dumps(format_item(response['Item'])),
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                }
            else:
                # Return an error message if the item was not found
                return {
                    'statusCode': 404,
                    'body': json.dumps({"error": "Book not found"}),
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                }
        
        except Exception as e:
            # Log and return an error message if the retrieval fails
            print(f"Unable to read item. Error: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps({"error": "Unable to read item", "message": str(e)}),
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
            }
    else:
        # Scan the 'Books' table if 'bookid' is not present
        try:
            data = table.scan()
            items = data.get('Items', [])
            formatted_items = [format_item(item) for item in items]
            
            return {
                'statusCode': 200,
                'body': json.dumps(formatted_items, indent=2),
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
            }
        
        except Exception as e:
            # Log and return an error message if the scan fails
            print(f"Unable to scan table. Error: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps({"error": "Unable to scan table", "message": str(e)}),
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
            }
