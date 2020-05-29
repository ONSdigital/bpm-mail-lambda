import pytest
import boto3
from moto import mock_s3
import requests_mock
import os
os.environ['ATTACHMENT_BUCKET'] = 'attachments'
os.environ['BPM_CSRF_URL'] = 'https://localhost/bpm/dev/csrf'
os.environ['BPM_EMAIL_URL'] = 'https://localhost/bpm/dev/launch'
os.environ['BPM_PW'] = 'blah'
os.environ['BPM_USER'] = 'blah'

@pytest.fixture(scope='function')
def aws_credentials():
    """Mocked AWS Credentials for moto."""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'

@pytest.fixture(scope='function')
def s3(aws_credentials):
    with mock_s3():
        yield boto3.client('s3', region_name='us-east-1')

@mock_s3
def test_email_with_mixed_attachment(s3):
    from lambdas.lambda_function import lambda_handler
    s3.create_bucket(Bucket=os.environ['ATTACHMENT_BUCKET'])
    s3.create_bucket(Bucket='email')
    with open('tests/emails/email-attachments-mixed', 'r') as content_file:
        content = content_file.read()
    s3.put_object(Body=content,
                Bucket='email',
                Key='xyz')
    with requests_mock.Mocker() as mock:
        mock.post(os.getenv("BPM_CSRF_URL"), json={"csrf_token": "FAKETOKEN"}, status_code=201)
        mock.post(os.getenv("BPM_EMAIL_URL"), status_code=201)
        assert (lambda_handler({'Records': [
        {'s3': {
            'bucket': {'name': 'email'},
            'object': {'key': 'xyz'}
        }}
    ]}, None))['status'] == 201

@mock_s3
def test_email_with_related_attachment(s3):
    from lambdas.lambda_function import lambda_handler
    s3.create_bucket(Bucket=os.environ['ATTACHMENT_BUCKET'])
    s3.create_bucket(Bucket='email')
    with open('tests/emails/email-attachments-related', 'r') as content_file:
        content = content_file.read()
    s3.put_object(Body=content,
                Bucket='email',
                Key='xyz')
    with requests_mock.Mocker() as mock:
        mock.post(os.getenv("BPM_CSRF_URL"), json={"csrf_token": "FAKETOKEN"}, status_code=201)
        mock.post(os.getenv("BPM_EMAIL_URL"), status_code=201)
        assert (lambda_handler({'Records': [
        {'s3': {
            'bucket': {'name': 'email'},
            'object': {'key': 'xyz'}
        }}
    ]}, None))['status'] == 201