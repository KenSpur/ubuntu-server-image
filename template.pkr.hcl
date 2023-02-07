source "file" "meta_data" {
  source = "${path.root}/templates/meta-data.pkrtpl"
  target = "${path.root}/http/meta-data"
}

source "file" "user_data" {
  content = templatefile("${path.root}/templates/user-data.pkrtpl", {
    ssh_username            = var.ssh_username
    ssh_key                 = var.ssh_key
    cloud_init_apt_packages = var.cloud_init_apt_packages
  })
  target = "${path.root}/http/user-data"
}

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

  ssh_username         = "${var.ssh_username}"
  ssh_private_key_file = "~/.ssh/id_rsa_packer"

  ssh_timeout = "15m"
}

build {
  sources = [
    "source.file.meta_data",
    "source.file.user_data",
    "source.proxmox.ubuntu-server-22-04-lts"
  ]

  # wait for cloud-init to finish
  provisioner "shell" {
    inline_shebang = "/bin/sh -x"
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 5s; done"
    ]
  }

  # upgrade cloud-init
  provisioner "shell" {
    inline_shebang = "/bin/sh -x"
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade cloud-init -y"
    ]
  }

  # clean up
  provisioner "shell" {
    inline_shebang = "/bin/sh -x"
    inline = [
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt-get -y autoremove --purge",
      "sudo apt-get -y clean",
      "sudo apt-get -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }

  # update cloud-init config to use Proxmox VE
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -x"
    inline         = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }
}