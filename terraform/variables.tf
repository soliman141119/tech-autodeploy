variable "region" {
  default = "eu-central-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami" {
  default = "ami-0669b163befffbdfc" # Ubuntu 22.04 LTS Frankfurt
}



variable "public_key" {
  description = "Public SSH key for EC2 access"
  type        = string
}

