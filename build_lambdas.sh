#!/bin/bash
set -e
echo "Building deployment package for producer_lambda..."

mkdir -p producer_lambda/package
cd producer_lambda

pip install -r requirements.txt -t ./package

cp main.py ./package/

cd package
zip -r ../../infra/tf/producer_lambda.zip .

cd ../..
rm -rf producer_lambda/package

echo "producer_lambda.zip created successfully."

echo "Building deployment package for consumer_lambda..."

mkdir -p consumer_lambda/package
cd consumer_lambda

pip install -r requirements.txt -t ./package

cp main.py ./package/

cd package
zip -r ../../infra/tf/consumer_lambda.zip .

cd ../..
rm -rf consumer_lambda/package

echo "consumer_lambda.zip created successfully."

echo "All Lambda packages built."