import json
from datetime import datetime
from os import getenv
from time import time
import logging
import boto3
import jsonschema
import requests
import bleach

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.DEBUG)

MANIFEST_SCHEMA = {
    "$schema": "http://json-schema.org/draft/2019-09/schema#",
    "type": "object",
    "properties": {
        "subject": "string",
        "sent": "string",
        "ccList": "string",
        "from": "string",
        "emailmimetype": "string",
        "Attachments": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "filename": "string",
                    "mailpart": "string",
                    "orig.attach.name": "string",
                    "attach.file.type": "string",
                    "sizeBytes": "string",
                    "body.mime.type": "string",
                },
            },
        },
    },
}

CSRF_TOKEN = None


def check_token():
    """Implements TTL-based local caching for BPM CSRF tokens"""
    global CSRF_TOKEN
    if CSRF_TOKEN is not None and CSRF_TOKEN.expiration < time():
        return CSRF_TOKEN
    csrf_resp = requests.post(
        getenv("BPM_CSRF_URL"),
        auth=(getenv("BPM_USER"), getenv("BPM_PW")),
        json={"refresh_groups": True, "requested_lifetime": 7200},
    )
    if csrf_resp.status_code != 201:
        raise Exception(
            f"ERROR {csrf_resp.status_code}: Cannot get CSRF token: {csrf_resp.text}"
        )
    CSRF_TOKEN = csrf_resp.json()
    # Subtracting 30 seconds to allow for bad clocks and latency
    CSRF_TOKEN.expiration = (CSRF_TOKEN.expiration - 30) + int(time())
    return CSRF_TOKEN


def lambda_handler(event, context):
    """Trigger a new Prices Correspondence process instance on new email.

       Triggered by a new manifest file being delivered to S3 bucket.
       Reads the manifest and email body files, and starts BPM Process
       via REST API call.
    """
    global CSRF_TOKEN
    timestamp = time()
    client = boto3.client("s3")
    s3_event = event["Records"][0]["s3"]

    bucket_name = s3_event["bucket"]["name"]
    s3_key = s3_event["object"]["key"]
    LOGGER.info(f"### S3 ### Bucket: {bucket_name}; Object key: {s3_key}")

    manifest_txt = client.get_object(Bucket=bucket_name, Key=s3_key)
    LOGGER.info(f"### TIME ### Time to get manifest: {time() - timestamp}")
    LOGGER.info(f"### MANIFEST ### Manifest is : {manifest_txt}")
    timestamp = time()
    if manifest_txt is None:
        raise Exception(
            "Cannot access manifest from S3 bucket: " + s3_event["bucket"]["name"]
        )

    manifest = json.loads(manifest_txt)
    try:
        jsonschema.validate(instance=manifest, schema=MANIFEST_SCHEMA)
    except jsonschema.exceptions.ValidationError:
        raise Exception("Manifest fails validation: " + s3_event["object"]["key"])

    # We get:  Wed, 7 Oct 2015 12:34:56 -0700
    # We need: ISO-8601 format 'yyyy-MM-dd'T'HH:mm:ssz'
    date_received = datetime.strptime(manifest.sent, r"%a, %d %b %Y %H:%M:%S %z")
    date_converted = date_received.strftime(r"%Y-%m-%dT%H:%M:%S%z")

    # Select the attachments object for the email body
    body = [att for att in manifest.Attachments if att.mailpart == "body"][0]
    # Retrieve email body from S3 bucket
    email_body = client.get_object(Bucket=bucket_name, Key="email/" + body.filename)
    email_content = bleach.clean(
        email_body,
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
    LOGGER.info(
        f"### TIME ### Time to get email and sanitise html: {time() - timestamp}"
    )
    timestamp = time()
    attachments = [att for att in manifest.Attachments if att.mailpart == "attachment"]
    req_attachments = []
    if attachments:
        bucket = getenv("ATTACHMENT_BUCKET")
        region = client.get_bucket_location(Bucket=bucket)["LocationConstraint"]
        for attachment in attachments:
            req_attachments.append(
                {
                    "url": f"https://s3.{region}.amazonaws.com/{bucket}/{attachment.filename}",
                    "contentType": attachment.get("attach.file.type"),
                    "originalFilename": attachment.get("orig.attach.name"),
                    "fileSizeBytes": int(attachment.sizeBytes),
                }
            )

    LOGGER.info(f'### EMAIL ### From: {manifest["from"]}, Subject: {manifest.subject}')
    bpm_data = {
        "input": [
            {
                "name": "email",
                "data": {
                    "from": manifest["from"],
                    "cc": manifest.ccList,
                    "dateReceived": date_converted,
                    "subject": manifest.subject,
                    "body": email_content,
                    "contentType": body.get("body.mime.type"),
                    "attachments": req_attachments,
                },
            }
        ]
    }

    CSRF_TOKEN = check_token()
    task_resp = requests.post(
        getenv("BPM_EMAIL_URL"),
        headers={"BPMCSRFToken": CSRF_TOKEN.csrf_token},
        auth=(getenv("BPM_USER"), getenv("BPM_PW")),
        json=bpm_data,
    )

    if task_resp.status_code != 201:
        raise Exception(
            f"ERROR {task_resp.status_code}: Cannot init new task: {task_resp.text}"
        )
    LOGGER.info(f"### TIME ### Time to trigger bpm: {time() - timestamp}")
    timestamp = time()
    return {
        "status": task_resp.status_code,
        "body": task_resp.text,
        "bpm_data": bpm_data,
    }
