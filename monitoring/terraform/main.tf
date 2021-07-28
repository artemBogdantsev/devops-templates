provider "google" {
  project = "staticfilesserver"
  region = "europe-west1"
  credentials = file(var.account_file_path)
}