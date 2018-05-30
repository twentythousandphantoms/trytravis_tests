output "app_external_ip" {
  value = "${google_compute_instance.puma.*.network_interface.0.access_config.0.assigned_nat_ip}"
}
output "lb_external_ip" {
  value = "${google_compute_global_forwarding_rule.puma_global_forwarding_rule.ip_address}"
}
