FROM public.ecr.aws/sam/build-python3.9

RUN pip3 install 'urllib3<2' pymysql requests pyjstat pandas sqlalchemy -t /layer_dir/python
RUN cd /layer_dir && zip -r lambda_dependencies_docker.zip .