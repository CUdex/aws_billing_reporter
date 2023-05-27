import requests
import json
import datetime

def exchange_won(doller: str):
    url = 'https://quotation-api-cdn.dunamu.com/v1/forex/recent?codes=FRX.KRWUSD'
    response = requests.get(url=url)

    if response.status_code == 200:
        data = json.loads(response.content)
        won = data[0]['basePrice']
        result = int(float(doller) * float(won))
        return (result)
    else:
        return False
    
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

print(time_select())



