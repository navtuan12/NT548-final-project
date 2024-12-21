variable "master_ips" {
  type    = list(string)
  default = ["10.0.1.10", "10.0.2.10", "10.0.3.10"]
}

variable "worker_ips" {
  type    = list(string)
  default = ["10.0.1.11", "10.0.2.11", "10.0.3.11"]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.1.0/24", 
    "10.0.2.0/24", 
    "10.0.3.0/24"
  ]
}


variable "public_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.4.0/24", 
    "10.0.5.0/24", 
    "10.0.6.0/24"
  ]
}

variable "key_pair" {
  type = string
  default = "~/.ssh/anhtuan.pem"
}