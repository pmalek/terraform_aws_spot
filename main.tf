terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"

  validation {
    condition     = length(var.region) > 0
    error_message = "Region has to be specified."
  }
}

variable "ami" {
  type    = string
  default = "ami-0c582118883b46f4f"

  validation {
    condition     = length(var.ami) > 4 && substr(var.ami, 0, 4) == "ami-"
    error_message = "AMI has to be specified and has to have an 'ami-' prefix."
  }
}

variable "spot_price" {
  type    = number

  validation {
    condition     = var.spot_price > 0
    error_message = "Spot price has to be provided and be greater than 0."
  }
}

variable "key_name" {
  type    = string

  validation {
    condition     = length(var.key_name) > 0
    error_message = "Key name has to be specified."
  }
}

variable "capacity" {
  type    = number

  validation {
    condition     = var.capacity > 0
    error_message = "Capacity has to be specified and be greater than 0."
  }
}

// -----------------------------------------------------------------------------

# Configure the AWS Provider
provider "aws" {
  region = var.region
}
