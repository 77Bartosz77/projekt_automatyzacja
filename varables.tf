variable "account_id" {
    sensitive = true
}

variable "region" {
    description = "aws region"
    type = string
    default = "eu-north-1"
}