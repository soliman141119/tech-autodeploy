variable "region" {
  default = "eu-central-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami" {
  default = "ami-0669b163befffbdfc" # Ubuntu 22.04 LTS Frankfurt
}

variable "key_path" {
  default = "/home/soliman/.ssh/soly.pub"
}

variable "public_key" {
  description = "SSH public key for EC2 instances"
  type        = string
}
