# bpm-mail-lambda

**bpm-mail-lambda** is an AWS lambda function intended to create task instances in [IBM's BPM](https://www.ibm.com/Automation/BPM‎) system upon the arrival of a new email into an AWS S3 bucket.

## Building

After cloning the repo

## Configuration

### Runtime

This lambda uses the Python 3.7 runtime.

### Trigger

You will need to set your lambda's trigger to be S3 ObjectCreated.

### Environment variables

| Variable name | Description |
| --------------|-------------|
| BPM_CSRF_URL  | REST endpoint URL for requesting a new CSRF token |
| BPM_EMAIL_URL | REST endpoint URL for creating a new task instance |
| BPM_USER      | Username for accessing BPM |
| BPM_PW        | Password for above |