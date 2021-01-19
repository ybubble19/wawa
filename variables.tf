variable "region" {
  type = string
}

variable "availability_zones" {
  type = list
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "cidr_block" {
  type        = string
  description = "VPC cidr block. Example: 10.0.0.0/16"
}

variable "tags" {
  type = map(string)
  default = {
      environment   = "dev" 
      terraform     = "yes"
  }
}