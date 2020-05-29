#!/bin/bash
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