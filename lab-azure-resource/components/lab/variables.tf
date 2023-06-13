/*
 * VNet Cidr address space ranges that can be used
 * In the case some else is running the labs as well
-----
1	10.10.0.0/25
2	10.10.0.128/25
3	10.10.1.0/25
4	10.10.1.128/25
5	10.10.2.0/25
6	10.10.2.128/25
7	10.10.3.0/25
8	10.10.3.128/25
9	10.10.4.0/25
10	10.10.4.128/25
11	10.10.5.0/25
12	10.10.5.128/25
13	10.10.6.0/25
14	10.10.6.128/25
15	10.10.7.0/25
16	10.10.7.128/25
-----
*/

variable "location" {
  default = "uksouth"
}

variable "address_space" {
  default = "10.10.2.128/25"
}

variable "environment" {
  default = "sandbox"
}
variable "product" {
  default = "sds-platform"
}
variable "builtFrom" {
  default = "labs"
}

variable "env" {
  default = "sbox"
}

variable "hub_sbox_subscription_id" {
  default = "ea3a8c1e-af9d-4108-bc86-a7e2d267f49c"
}

variable "subscription_id" {
  default = "a8140a9e-f1b0-481f-a4de-09e2ee23f7ab"
}