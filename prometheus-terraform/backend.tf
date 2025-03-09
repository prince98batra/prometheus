terraform {
  backend "s3" {
    bucket = "prince-batra-bucket-2"  
    key    = "prometheus/terraform.tfstate" 
    region = "us-east-1"                    
    encrypt = true                        
  }
}

