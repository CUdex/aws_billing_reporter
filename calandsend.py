#https://quotation-api-cdn.dunamu.com/v1/forex/recent?codes=FRX.KRWUSD 환율정보 받아오는 곳 basePrice 사용
import boto3
import pandas as pd

# Create a client object for athena service
client = boto3.client('athena', region_name='us-east-1')

# Execute a query and get the query execution ID
response = client.start_query_execution(
    QueryString="SELECT sum(line_item_blended_cost) FROM billing_database.reportresult WHERE identity_time_interval = '2023-05-08T00:00:00Z/2023-05-09T00:00:00Z'",
    QueryExecutionContext={
        'Database': 'billing_database'
    },
    ResultConfiguration={
        'OutputLocation': 's3://billingbucketgenians/'
    }
)

query_id = response['QueryExecutionId']

# Wait for the query to complete and get the output location
status = 'RUNNING'
while not status == 'SUCCEEDED':
    response = client.get_query_execution(QueryExecutionId=query_id)
    status = response['QueryExecution']['Status']['State']
    if status == 'FAILED' or status == 'CANCELLED':
        raise Exception('Query failed or cancelled')
    print('Query status:', status)

output_location = response['QueryExecution']['ResultConfiguration']['OutputLocation']
print('Query output location:', output_location)

# Get the query results as a dictionary
response = client.get_query_results(QueryExecutionId=query_id)
rows = response['ResultSet']['Rows']

print(rows)
data = [[col['VarCharValue'] for col in row['Data']] for row in rows[1:]]


# Convert the dictionary to a dataframe
df = pd.DataFrame(data)
print(df.iloc[0].values[0])