terraform {
  backend "gcs" {
    bucket = "my-awesome-otus-bucket"
    prefix = "terraform/state/stage"
  }
}
