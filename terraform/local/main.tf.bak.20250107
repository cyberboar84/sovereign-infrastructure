terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# --- Configuration for Local Metal ---
provider "libvirt" {
  uri = "qemu:///system"
}

# --- Configuration for Cloud Bridge ---
provider "google" {
  project = "sovereign-ai-lab-01"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# --- Storage Pool (Fixed Warning) ---
resource "libvirt_pool" "default" {
  name = "default"
  type = "dir"
  # syntax changed from 'path' to 'target { path = ... }'
  target {
    path = "/var/lib/libvirt/images"
  }
}

# --- Networks ---
# 1. WAN Bridge (Connects to your physical br0)
resource "libvirt_network" "wan_bridge" {
  name      = "wan_bridge"
  mode      = "bridge"
  bridge    = "br0"
  autostart = true
}

# 2. AI LAN (The Sovereign Air-Gapped Network)
resource "libvirt_network" "ai_lan" {
  name      = "ai_lan"
  mode      = "nat"
  domain    = "ai.lab"
  addresses = ["10.10.10.0/24"]
  autostart = true
}

# --- Gateway: pfSense ---
resource "libvirt_volume" "pfsense_root" {
  name   = "pfsense_root.qcow2"
  pool   = libvirt_pool.default.name
  format = "qcow2"
  size   = 32212254720 # 30GB
}

resource "libvirt_domain" "pfsense" {
  name   = "pfsense-gateway"
  memory = "2048"
  vcpu   = 2

  network_interface {
    network_name = "wan_bridge"
  }

  network_interface {
    network_id = libvirt_network.ai_lan.id
  }

  disk {
    volume_id = libvirt_volume.pfsense_root.id
  }

  boot_device {
    dev = ["hd"]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}

# --- Management Node (Jump Box / Wazuh) ---

# 1. Cloud-Init (Fixed Error) ---
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = <<EOF
#cloud-config
users:
  - name: ml-boar
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${file("/home/ml-boar/.ssh/id_rsa.pub")}  # CHANGED: Full path, no '~'
ssh_pwauth: true
chpasswd:
  list: |
    ml-boar:sovereign
  expire: False
EOF
}

# 2. Storage: Base Image + Resized Volume (The 50GB Fix)
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-24.04-base.qcow2"
  pool   = libvirt_pool.default.name
  source = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "mgmt_root" {
  name           = "mgmt_root.qcow2"
  pool           = libvirt_pool.default.name
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = 53687091200 # 50GB
}

# 3. Compute Domain (With CPU Passthrough Fix)
resource "libvirt_domain" "mgmt_node" {
  name   = "mgmt-gateway"
  memory = "4096"
  vcpu   = 2

  # CRITICAL FIX: Passes Host CPU features (AVX, SSE4.2) to VM
  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "ai_lan"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.mgmt_root.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}
