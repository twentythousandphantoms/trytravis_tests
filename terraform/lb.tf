/* Setting Up HTTP Load Balancing
Overview Documentaion: https://cloud.google.com/compute/docs/load-balancing/http/#overview
*/

resource "google_compute_global_forwarding_rule" "puma_global_forwarding_rule" {
  name       = "puma-default-rule"
  description = "It's binds an ip and port to a target HTTP(s) proxy. Docs: https://cloud.google.com/compute/docs/load-balancing/http/global-forwarding-rules"
  target     = "${google_compute_target_http_proxy.puma_http_proxy.self_link}"
  port_range = "80"
}

resource "google_compute_target_http_proxy" "puma_http_proxy" {
  name        = "puma-http-proxy"
  description = "Target proxies terminate HTTP(S) connections from clients, and are referenced by one or more global forwarding rules and route the incoming requests to a URL map. Docs: https://cloud.google.com/compute/docs/load-balancing/http/target-proxies"
  url_map     = "${google_compute_url_map.puma_url_map.self_link}"
}

resource "google_compute_url_map" "puma_url_map" {
  name            = "puma-url-map"
  description     = "URL maps define matching patterns for URL-based routing of requests to the appropriate backend services. Docs: https://cloud.google.com/compute/docs/load-balancing/http/url-map"
  default_service = "${google_compute_backend_service.puma_backend_service.self_link}"
}

resource "google_compute_backend_service" "puma_backend_service" {
  name        = "puma-backend-service"
  description = "Backend services direct incoming traffic to one or more attached backends. Docs: https://cloud.google.com/compute/docs/load-balancing/http/backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = ["${google_compute_http_health_check.puma_health_check.self_link}"]

  backend {
    group = "${google_compute_instance_group.puma_group.self_link}"
  }
}

resource "google_compute_http_health_check" "puma_health_check" {
  name               = "puma-health-check"
  description        = "This resource defines a template for how individual VMs should be checked for health, via HTTP. Docs: https://cloud.google.com/compute/docs/load-balancing/health-checks"
  port               = "9292"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_instance_group" "puma_group" {
  name        = "puma-group"
  description = "'Unmanaged' group of puma instances. Docs: https://cloud.google.com/compute/docs/instance-groups/#unmanaged_instance_groups"

  instances = [
    "${google_compute_instance.puma.*.self_link}",
  ]

  named_port {
    name = "http"
    port = "9292"
  }

  zone = "${var.zone}"
}

