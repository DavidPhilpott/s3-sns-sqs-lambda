variable "access_key" {
	type = "string"
}
variable "secret_key" {
	type = "string"
}

variable "region" {
  default = "eu-west-1"
}

variable "project-name" {
	type = "string"
}

locals {
  common_tags = "${map(
        "project_name", "${var.project_name}"
    )}"
}
