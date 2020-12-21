provider "google" {
  credentials = file("My First Project-69c21d565f57.json")
  project     = "uplifted-kit-294707"
  region      = "europe-west3"
}

variable "node_count" {
  default = "2"
 }
 variable "node_type" {
  default = "e2-micro"
 }

resource "google_compute_instance" "default" { 
  name         = "node-${var.node_type}-${count.index}"
  machine_type = "e2-micro"
  zone         = "europe-west3-a"
  count        = "${var.node_count}"

  boot_disk {
    initialize_params {
        image = "ubuntu-1804-bionic-v20201211a"
        type  = "pd-ssd"
        size  = "10"
    }
  }

  network_interface {
    network    = "default"
    subnetwork = "default"
    access_config {}
  }

  service_account {
  email = "775514505398-compute@developer.gserviceaccount.com"
  scopes = ["cloud-platform"]
  }
}