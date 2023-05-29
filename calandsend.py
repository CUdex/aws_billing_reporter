#https://quotation-api-cdn.dunamu.com/v1/forex/recent?codes=FRX.KRWUSD 환율정보 받아오는 곳 basePrice 사용
import boto3
import pandas as pd
import json
import requests
import datetime

#access key 테스트용
def read_keys():
    # 파일을 읽기 모드로 엽니다.
    path = r'C:\Users\sumone\app.txt'
    with open(path, 'r') as file:
        content = file.readlines()

    result = {}

    for origin in content:
        split_origin = origin.split('=')
        split_origin[1] = split_origin[1].rstrip('\n')
        result[split_origin[0]] = split_origin[1]
    
    return result

#amazon sns에 전달
def send_sns(massage: str):
    sns_client = boto3.client('sns', region_name='ap-northeast-2')
    topics = sns_client.list_topics()
    topic_arn = next(topic['TopicArn'] for topic in topics['Topics'] if 'billing_report' in topic['TopicArn'])
    sns_client.publish(
        TopicArn=topic_arn,
        Message=massage
    )

#환율 정보를 기반으로 달러에서 원화로 변경 값 반환
def exchange_won(dollar: str):
    url = 'https://quotation-api-cdn.dunamu.com/v1/forex/recent?codes=FRX.KRWUSD'
    response = requests.get(url=url)

    if response.status_code == 200:
        data = json.loads(response.content)
        won = data[0]['basePrice']
        result = int(float(dollar) * float(won))
        return (result)
    else:
        return False

#where에 넣은 시간 조건 계산  
def time_select():
    result = []
    today = datetime.date.today()

    yesterday = today - datetime.timedelta(days=1)
    two_days_ago = yesterday - datetime.timedelta(days=1)
    
    yesterday = yesterday.strftime("%Y-%m-%dT%H:%M:%SZ")
    two_days_ago = two_days_ago.strftime("%Y-%m-%dT%H:%M:%SZ")

    result.append(two_days_ago)
    result.append(yesterday)

    return result


aws_key = read_keys()

# Create a client object for athena service
client = boto3.client('athena', region_name='us-east-1')

# where 조건으로 줄 날짜
time = time_select()
start_time = time[0]
end_time = time[1]

# Execute a query and get the query execution ID
response = client.start_query_execution(
    QueryString=f"SELECT sum(line_item_blended_cost) FROM billing_database.reportresult WHERE identity_time_interval = '{start_time}/{end_time}'",
    QueryExecutionContext={
        'Database': 'billing_database'
    },
    ResultConfiguration={
        'OutputLocation': 's3://billing-report-bucket-genians/'
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

output_location = response['QueryExecution']['ResultConfiguration']['OutputLocation']
print('Query output location:', output_location)

# Get the query results as a dictionary
response = client.get_query_results(QueryExecutionId=query_id)
rows = response['ResultSet']['Rows']
data = [[col['VarCharValue'] for col in row['Data']] for row in rows[1:]]

# Convert the dictionary to a dataframe
df = pd.DataFrame(data)
won = exchange_won(df.iloc[0].values[0])
if not won:
    print("fail exchange")
else:
    result = str(won) + "원이 사용되었습니다."
    send_sns(result)