terraform {
  backend "s3" {
    bucket = "djphilpott-terraform-states"
    key    = "s3-sns-sqs-lambda/terraform_state"
    region = "eu-west-1"
  }
}
