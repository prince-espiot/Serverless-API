import boto3
import json

def lambda_handler(event, context):
    # Initialize a session using Amazon DynamoDB
    dynamodb = boto3.resource('dynamodb')
    
    # Select your DynamoDB table
    table = dynamodb.Table('Books')
    print (table)
    
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
                    'body': json.dumps(response['Item'], indent=2)
                }
            else:
                # Return an error message if the item was not found
                return {
                    'statusCode': 404,
                    'body': json.dumps({"error": "Book not found"})
                }
        
        except Exception as e:
            # Log and return an error message if the retrieval fails
            print(f"Unable to read item. Error: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps({"error": "Unable to read item", "message": str(e)})
            }
    else:
        # Return an error if 'queryStringParameters' or 'bookid' is missing
        return {
            'statusCode': 400,
            'body': json.dumps({"error": "Missing query string parameter 'bookid'"})
        }
