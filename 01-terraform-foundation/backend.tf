terraform {
  backend "s3" {
    bucket       = "robotshop-tfstate-almecc"
    key          = "robotshop/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
