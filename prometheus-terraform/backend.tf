terraform {
  backend "s3" {
    bucket = "prince-batra-bucket"  
    key    = "prometheus/terraform.tfstate" 
    region = "us-east-1"                    
    encrypt = true                        
  }
}

