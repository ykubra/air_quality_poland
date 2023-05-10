# terraform init 
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

terraform init

# applying changes
terraform plan
terraform apply

# Removing resources
terraform destroy


# Docker for dependencies
docker pull public.ecr.aws/sam/build-python3.9
docker images 
docker run -it <image ID> bash 
pip3 install setuptools numpy pymysql requests pyjstat pandas sqlalchemy -t /layer_dir/python
# From /layer_dir
zip -r lambda_dependencies_docker.zip .
# From terraform directory
docker ps
docker cp <container ID>:/layer_dir/lambda_dependencies_docker.zip ./