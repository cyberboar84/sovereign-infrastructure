resource "libvirt_network" "ovs_mgmt" {
  name      = "ovs-mgmt-net"
  mode      = "bridge"
  bridge    = var.new_infrastructure["ovs_bridge_name"]
  autostart = true

  # We disable DHCP because pfSense manages IPs in this Sovereign Lab
  dhcp {
    enabled = false
  }
}
