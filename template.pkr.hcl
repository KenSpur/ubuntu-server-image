source "proxmox" "ubuntu-server-22-04-lts" {
  proxmox_url              = "${var.proxmox_api_url}"
  username                 = "${var.proxmox_api_token_id}"
  token                    = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = true

  node                 = "${var.proxmox_node}"
  vm_id                = "${var.proxmox_vm_id}"
  vm_name              = "ubuntu-server-22-04-lts"
  template_description = "Ubuntu Server 22.04.1"

  iso_file         = "local:iso/ubuntu-22.04.1-live-server-amd64.iso"
  iso_storage_pool = "local"
  unmount_iso      = true

  qemu_agent = true

  cores  = "1"
  memory = "2048"

  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  scsi_controller = "virtio-scsi-single"

  disks {
    type              = "scsi"
    disk_size         = "32G"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm"
    format            = "raw"
  }

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"
  http_directory          = "http"

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot      = "c"
  boot_wait = "5s"

  ssh_username = "${var.ssh_username}"
  ssh_password = "${var.ssh_password}"

  ssh_timeout = "15m"
}

build {
  sources = ["source.proxmox.ubuntu-server-22-04-lts"]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }

  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }
}