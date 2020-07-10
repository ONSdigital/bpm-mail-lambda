# bpm-mail-lambda
​
**bpm-mail-lambda** is an AWS lambda function intended to create task instances in [IBM's BPM](https://www.ibm.com/Automation/BPM‎) system upon the arrival of a new email into an AWS S3 bucket.
​
## Building
​
After cloning the repo, you will need to create a virtualenv, as lambdas using any non-AWS, non-core modules, will need them vendorised.
​
```sh
git clone https://github.com/ONSdigital/bpm-mail-lambda.git
​
apt-get update
apt-get -y install zip
​
mkdir generated
​
pushd bpm-mail-lambda
python3 -m venv v-env
source v-env/bin/activate
pip install pipenv
pipenv install
deactivate
popd
​
mkdir zipit
​
mv bpm-mail-lambda/v-env/lib/python3.7/site-packages/* zipit/
mv bpm-mail-lambda/lambdas/lambda_function.py zipit/
​
pushd zipit
zip -r9 ../generated/function.zip .
popd
```
​
After editing the `lambda_function.py` file, you will need to add it to the zip file created earlier.
​
```sh
zip -g function.zip lambda_function.py
```
​
You will need to re-run this last step after every edit to the lambda that you wish to deploy. You can deploy this using the `aws` CLI tool, or the management console on the web.
​
When (not if) you need to update the python dependencies, run `pipenv update` in the base directory, then freshen the deployment zip file with
​
```sh
cd ./v-env/lib/python3.7/site-packages/
zip -fr ../../../../function.zip ./*
```
​
### Runtime
​
This lambda uses the Python 3.7 runtime.
​
### Trigger
​
You will need to set your lambda's trigger to be S3 ObjectCreated.
​
### Environment variables
​
| Variable name     | Description                                        |
| ----------------- | -------------------------------------------------- |
| BPM_CSRF_URL      | REST endpoint URL for requesting a new CSRF token  |
| BPM_EMAIL_URL     | REST endpoint URL for creating a new task instance |
| BPM_USER          | Username for accessing BPM                         |
| BPM_PW            | Password for above                                 |
| ATTACHMENT_BUCKET | S3 bucket name to store attachments in             |
​
When terraforming, you will need to set environment variables `TF_VAR_BPM_USER` and `TF_VAR_BPM_PW` to the values you have created for your service account in BAW.