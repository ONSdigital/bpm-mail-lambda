# bpm-mail-lambda

**bpm-mail-lambda** is an AWS lambda function intended to create task instances in [IBM's BPM](https://www.ibm.com/Automation/BPM‎) system upon the arrival of a new email into an AWS S3 bucket.

## Building

After cloning the repo, you will need to create a virtualenv, as lambdas using any non-AWS, non-core modules, will need them vendorised.

```sh
git clone https://github.com/ONSdigital/bpm-mail-lambda.git
cd bpm-mail-lambda
python3 -m venv v-env
source v-env/bin/activate
pipenv install
deactivate
cd v-env/lib/python3.7/site-packages
zip -r9 $OLDPWD/function.zip .
```

After editing the `lambda_function.py` file, you will need to add it to the zip file created earlier.

```sh
zip -g function.zip lambda_function.py
```

You will need to re-run this last step after every edit to the lambda that you wish to deploy. You can deploy this using the `aws` CLI tool, or the management console on the web.

You will only need to re-create the zip file if you make changes to the modules.

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