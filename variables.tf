variable "ami_key_pair_name_file" {
  default="/Users/johndohoneyjr/.ssh/dohoney-se-demos-west.pem"
} 

variable "ami_key_pair_name" {
  default="dohoney-se-demos-west"
}

variable "aws_region" {
  description = "AWS region"
  default = "us-west-2"
}

variable "instance_type" {
  description = "type of EC2 instance to provision."
  default = "t2.medium"
}

