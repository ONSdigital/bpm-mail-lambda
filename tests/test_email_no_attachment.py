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
@pytest.mark.skip(reason="Needs updating to new nifi method")
def test_load_good_manifest(s3):
    from lambdas.lambda_function import lambda_handler
    s3.create_bucket(Bucket=os.environ['ATTACHMENT_BUCKET'])
    s3.create_bucket(Bucket='email')
    with open('tests/json/manifest_ok.json', 'r') as manifest_file:
        manifest_json = manifest_file.read()
    s3.put_object(Body=manifest_json,
                Bucket='manifest',
                Key='xyz')
    with requests_mock.Mocker() as mock:
        mock.post(os.getenv("BPM_CSRF_URL"), json={"csrf_token": "FAKETOKEN"}, status_code=201)
        mock.post(os.getenv("BPM_EMAIL_URL"), status_code=201)
        assert (lambda_handler({'Records': [
        {'s3': {
            'bucket': {'name': 'manifest'},
            'object': {'key': 'xyz'}
        }}
    ]}, None))['status'] == 201

