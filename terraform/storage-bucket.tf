provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "storage-super-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name    = ["my-awesome-otus-bucket"]
}

output storage-bucket_url {
  value = "${module.storage-super-bucket.url}"
}
