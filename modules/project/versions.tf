terraform {
  required_version = ">= 1.5"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2, < 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.30, < 7.0"
    }
  }
}
