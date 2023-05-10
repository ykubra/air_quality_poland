output "data_load_endpoint" {
  value = "${aws_api_gateway_stage.api_gateway_stage_production.invoke_url}/${aws_api_gateway_resource.data_load_resource.path_part}"
}

output "get_all_data_endpoint" {
    value = "${aws_api_gateway_stage.api_gateway_stage_production.invoke_url}/${aws_api_gateway_resource.get_all_data_resource.path_part}"
}