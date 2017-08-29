variable  "region"                          {}
variable  "admin_cidr_block"                {}
variable  "vpc_id"                          {}
variable  "httpport"                        { default = 8000 }
variable  "ami"                             {}
variable  "instance_user"                   {}
variable  "key_name"                        {}
variable  "instance_type_indexer"           {}
variable  "subnets"                         {}
variable  "count_indexer"                   { default = 2 }
variable  "instance_type_searchhead"           {}
# SearchHead Autoscaling
variable  "asg_searchhead_desired"          { default = 1 }
variable  "asg_searchhead_min"              { default = 1 }
variable  "asg_searchhead_max"              { default = 1 }

variable  "availability_zones"              {}

#master Autoscaling
variable  "asg_master_desired"          { default = 1 }
variable  "asg_master_min"              { default = 1 }
variable  "asg_master_max"              { default = 1 }

#indexer Autoscaling
variable  "asg_peer_desired"          { default = 2 }
variable  "asg_peer_min"              { default = 2 }
variable  "asg_peer_max"              { default = 6 }

variable "site1_az" {
  default = "us-east-1a"
}
variable "site1_subnet" {
  default = "subnet-ef096bc2"
}


variable "site2_az" {
  default = "us-east-1b"
}
variable "site2_subnet" {
  default = "subnet-d68cdf9f"
}

variable "replication_factor" {
  default = "2"
}

variable "search_factor" {
  default = "2"
}

variable "pass4SymmKey" {
  default = "udemy"
}

variable "mgmtHostPort" {
  default = "8089"
}

variable "replication_port" {
  default = "9887"
}

variable "iam_role_indexer" {
default = "S3accesstoEC2"
}
variable "iam_role_search" {
default = "S3accesstoEC2"
}
