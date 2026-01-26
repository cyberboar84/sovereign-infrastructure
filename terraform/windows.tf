# 1. Storage Volume for the C: Drive
resource "libvirt_volume" "windows_dc_root" {
  name   = "windows-server-2022-dc.qcow2"
  pool   = "default"
  format = "qcow2"
  size   = 64424509440 # 60GB
}

# 2. The Virtual Machine
resource "libvirt_domain" "domain_controller" {
  name   = "dc-01-sovereign"
  memory = "8192"
  vcpu   = 4
  # ... existing config ...

  # Add this block at the bottom:
  xml {
    xslt = file("ovs-patch.xsl")
  }

  network_interface {
    network_id     = libvirt_network.ovs_mgmt.id
    addresses      = [var.new_infrastructure["windows_dc_ip"]]
    wait_for_lease = false
  }

  disk {
    volume_id = libvirt_volume.windows_dc_root.id
    # Default is 'virtio', so we just leave it unspecified to get high performance.
  }

  # ISO 1: Windows Installer
  disk {
    file = "/var/lib/libvirt/images/isos/Windows_Server_2022.iso"
  }

  # ISO 2: VirtIO Drivers (Required to see the hard drive!)
  disk {
    file = "/var/lib/libvirt/images/isos/virtio-win.iso"
  }

  boot_device {
    dev = ["hd", "cdrom"]
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
