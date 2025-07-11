variable "VPC_CIDR" {
  type    = string
  default = "10.1.0.0/16"
}
variable "SUBNET_CIDR" {
  type    = string
  default = "10.1.1.0/24"
}

variable "ALLOWED_PORTS" {
  type    = list(number)
  default = [22, 80]
}
variable "INSTANCE_TYPE" {
  type    = string
  default = "t3.micro"
}
variable "KEY_PATH" {
  type        = string
  default     = "~/.ssh/jenkins.pub"
  description = "This is the public key path that will be used by jenkins to deploy docker image via ssh agent"
}
