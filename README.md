# Project Name
Energy Consumption in Europe

# Prerequisites

To use this project, you'll need to have access to the Eurostat website and their Energy Consumption API. You can find more information about the API and how to access it at the following URL:

[Eurostat API](https://ec.europa.eu/eurostat/api)

Once you have access, you can modify the project code to make requests to the API and retrieve the energy consumption data for different countries in Europe.

Also, you will need the following:
- An AWS account
- Terraform installed on your local machine
- Docker installed on your local machine

# Getting Started 
1. Docker Instructions: This process will generate a zip file containing the required dependencies that can be used in the AWS Lambda function.
    - Step 1 : In the terminal, run the `docker build -t <your image name> .` command to build the Docker image with the specified name.

    - Step 2 : After building the image, run `docker images` command to see the list of Docker images available.

    - Step 3 : Run the image using `docker run -dit <image ID> command` . This will start a container in detached mode and provide the container ID.

    - Step 4 : Check the running containers using `docker ps` command.

    - Step 5: Once the container is running, use `docker cp <container ID>:/layer_dir/lambda_dependencies_docker.zip terraform` command to copy the dependencies zip file from the container to the terraform directory. 


2. Terraform Instructions:
    - Step 1 : You need to configure your AWS credentials so that Terraform can access your account
        ```
        export aws_access_key_id = YOUR_ACCESS_KEY_ID
        export aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
        ```

    - Step 2: Navigate to the terraform directory
        `cd terraform`

    - Step 3: Run `terraform init` to initialize the Terraform working directory and download necessary plugins.

    - Step 4 : Run terraform apply to apply the Terraform configuration and creation of RDS instance, Lambda function, and API Gateway.
        `terraform apply --auto-approve`