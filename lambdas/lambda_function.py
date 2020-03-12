import json
import requests
import bleach
from datetime import datetime
from uuid import uuid4
from email import policy, message_from_bytes
from os import getenv
import boto3
from time import time
import logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def lambda_handler(event, context):
    timestamp = time()
    client = boto3.client("s3")
    s3_event = event["Records"][0]["s3"]
    
    bucket_name = s3_event["bucket"]["name"]
    s3_key = s3_event["object"]["key"]
    logger.info(f"### S3 ### Bucket: {bucket_name}; Object key: {s3_key}")

    email_obj = client.get_object(
        Bucket=bucket_name, Key=s3_key
    )
    logger.info(f"### TIME ### Time to get email: {time() - timestamp}")
    timestamp = time()
    if email_obj == None:
        raise Exception(
            "Cannot access email from S3 bucket: " + s3_event["bucket"]["name"]
        )

    message = message_from_bytes(email_obj["Body"].read(), policy=policy.default)
    if message == None or len(message) == 0:
        raise Exception(
            "Email appears empty or unparseable: " + s3_event["object"]["key"]
        )
    logger.info(f"### TIME ### Time to parse email: {time() - timestamp}")
    timestamp = time()
    # We get:  Wed, 7 Oct 2015 12:34:56 -0700
    # We need: ISO-8601 format 'yyyy-MM-dd'T'HH:mm:ssz'
    date_received = datetime.strptime(message.get("Date"), r"%a, %d %b %Y %H:%M:%S %z")
    date_converted = date_received.strftime(r"%Y-%m-%dT%H:%M:%S%z")
    email_body_part = message.get_body(preferencelist=("related", "plain", "html"))
    logger.debug(email_body_part)
    email_content = bleach.clean(
        email_body_part.get_content(),
        tags=[
            "a",
            "abbr",
            "acronym",
            "b",
            "blockquote",
            "br",
            "code",
            "div",
            "em",
            "i",
            "li",
            "ol",
            "p",
            "span",
            "strong",
            "ul",
        ],
    )
    logger.info(f"### TIME ### Time to sanitise html: {time() - timestamp}")
    timestamp = time()
    attachments = []
    bucket = getenv("ATTACHMENT_BUCKET")
    
    message_iter = message.iter_attachments()
    attachment = next(message_iter, None)
    if attachment != None:
        region = client.get_bucket_location(Bucket=bucket)["LocationConstraint"]
        while attachment != None:
            key = str(uuid4()) + str(uuid4())
            content_type = attachment.get_content_type()
            filename = attachment.get_filename()
            file_content = attachment.get_content()
            client.put_object(
                Body=file_content,
                Bucket=bucket,
                Key=key,
                ContentType=content_type,
                ContentDisposition=f'attachment; filename="{filename}"',
            )
            attachments.append(
                {
                    "url": f"https://s3.{region}.amazonaws.com/{bucket}/{key}",
                    "contentType": content_type,
                    "originalFilename": filename,
                    "fileSizeBytes": len(file_content),
                }
            )
            attachment = next(message_iter, None)
    logger.info(f"### TIME ### Time to store attachments: {time() - timestamp}")
    timestamp = time()
    logger.info(f'### EMAIL ### From: {message.get("From")}, Subject: {message.get("Subject")}')
    bpm_data = {
        "input": [
            {
                "name": "email",
                "data": {
                    "from": message.get("From"),
                    "cc": message.get("Cc"),
                    "dateReceived": date_converted,
                    "subject": message.get("Subject"),
                    "body": email_content,
                    "contentType": email_body_part.get_content_type(),
                    "attachments": attachments,
                },
            }
        ]
    }

    csrf_resp = requests.post(
        getenv("BPM_CSRF_URL"),
        auth=(getenv("BPM_USER"), getenv("BPM_PW")),
        json={"refresh_groups": True, "requested_lifetime": 7200},
    )
    if csrf_resp.status_code != 201:
        raise Exception(
            f"ERROR {csrf_resp.status_code}: Cannot get CSRF token: {csrf_resp.text}"
        )
    csrf_token = csrf_resp.json()["csrf_token"]
    logger.info(f"### TIME ### Time to get csrf: {time() - timestamp}")
    timestamp = time()
    task_resp = requests.post(
        getenv("BPM_EMAIL_URL"),
        headers={"BPMCSRFToken": csrf_token},
        auth=(getenv("BPM_USER"), getenv("BPM_PW")),
        json=bpm_data,
    )

    if task_resp.status_code != 201:
        raise Exception(
            f"ERROR {task_resp.status_code}: Cannot init new task: {task_resp.text}"
        )
    logger.info(f"### TIME ### Time to trigger bpm: {time() - timestamp}")
    timestamp = time()
    return {
        "status": task_resp.status_code,
        "body": task_resp.text,
        "bpm_data": bpm_data,
    }
