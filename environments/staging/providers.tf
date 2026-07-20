provider "google" {
  region = var.region
  # Project is intentionally not set here so the provider operates at
  # org/folder scope for project creation; module resources set project explicitly.
}

provider "google-beta" {
  region = var.region
}
