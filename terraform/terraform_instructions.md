


# terraform init 
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

terraform init

# applying changes
terraform plan
terraform apply

pip install ordereddict -t ./
pip install -r requirements.txt -t ./
rm -rf *dist-info

# Removing resources
terraform destroy

cd ../test-lambda/package && zip -r ../lambda_function3.zip . && cd .. && zip lambda_function3.zip test-lambda-func.py && cd ../terraform 