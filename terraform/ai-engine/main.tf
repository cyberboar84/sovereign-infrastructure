terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# 1. The Boot Image
resource "libvirt_volume" "os_image" {
  name   = "ubuntu-jammy-ai-base.qcow2"
  pool   = "default"
  source = "/tmp/ubuntu-jammy.qcow2"
  format = "qcow2"
}

# 2. The Main Disk
resource "libvirt_volume" "ai_disk" {
  name           = "ai-engine-disk.qcow2"
  base_volume_id = libvirt_volume.os_image.id
  pool           = "default"
  size           = 107374182400 # 100GB
}

# 3. Cloud-Init Prep (The Chef)
data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
hostname: deepseek-r1
users:
  - name: ml-boar
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    shell: /bin/bash
    ssh_authorized_keys:
      - ${file("/home/ml-boar/.ssh/id_rsa.pub")}
runcmd:
  - [ mkdir, -p, /mnt/models ]
  - [ sh, -c, "echo 'model_library /mnt/models 9p trans=virtio,version=9p2000.L,rw 0 0' >> /etc/fstab" ]
  - [ mount, -a ]
EOF
  }
}

# 3.1 The ISO Disk (The Oven)
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  pool      = "default"
  user_data = data.cloudinit_config.config.rendered
  meta_data = <<EOF
instance-id: deepseek-r1-engine
local-hostname: deepseek-r1
EOF
}

# 4. The Virtual Machine
resource "libvirt_domain" "ai_engine" {
  name      = "deepseek-r1-engine"
  memory    = "32768"
  vcpu      = 8
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  cpu {
    mode = "host-passthrough"
  }
  
  network_interface {
    network_name = "ai_lan"
    mac          = "52:54:00:00:A1:01" # <--- The Magic Tag
  }

  disk {
    volume_id = libvirt_volume.ai_disk.id
  }

  filesystem {
    source     = "/home/ml-boar/sovereign-ai/models"
    target     = "model_library"
    readonly   = true
    accessmode = "passthrough"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

output "ip" {
  value = libvirt_domain.ai_engine.network_interface[0].addresses
}
