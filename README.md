terraform을 이용하여 일별 aws요금 내역을 관리자 이메일로 보내주는 AWS RESOURCE 생성
CUR 내역을 S3로 전송 해당 내용을 glue crawler를 이용하여 glue database에 저장하고 해당 내용을 lambda를 이용해서 athena로 query 후 결과 값을 환율 계산 후 sns로 
email 발송