locals {
  prefix_length     = split("/", var.node_cidr)[1]
  control_plane_ips = [for i in range(var.control_plane_count) : cidrhost(var.node_cidr, var.control_plane_first_host + i)]
  worker_ips        = [for i in range(var.worker_count) : cidrhost(var.node_cidr, var.worker_first_host + i)]
}

# VMs are spread over the Proxmox nodes: 01 on the first one, 02 on the second one, etc.
# IDs go up by 10 (200, 210, 220...) to leave 201-209 to the workers.
resource "proxmox_virtual_environment_vm" "control_plane" {
  count     = var.control_plane_count
  name      = format("k8s-cp-%02d", count.index + 1)
  node_name = var.proxmox_nodes[count.index % length(var.proxmox_nodes)]
  vm_id     = 200 + count.index * 10
  on_boot   = true

  clone {
    vm_id     = var.template_id
    node_name = var.template_node
    full      = true
  }

  boot_order = ["scsi0"]

  cpu { cores = var.control_plan__cpu_number }
  memory { dedicated = var.control_plan_memory_size }

  agent { enabled = true }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.control_plan_disk_size
    discard      = "on"
  }

  initialization {
    datastore_id = var.datastore_id
    ip_config {
      ipv4 {
        address = "${local.control_plane_ips[count.index]}/${local.prefix_length}"
        gateway = var.gateway
      }
    }
    dns { servers = var.dns_servers }
    user_account {
      username = "debian"
      keys     = [var.ssh_public_key]
    }
  }
}

resource "proxmox_virtual_environment_vm" "workers" {
  count     = var.worker_count
  name      = format("k8s-worker-%02d", count.index + 1)
  node_name = var.proxmox_nodes[count.index % length(var.proxmox_nodes)]
  vm_id     = 201 + count.index
  on_boot   = true

  clone {
    vm_id     = var.template_id
    node_name = var.template_node
    full      = true
  }

  boot_order = ["scsi0"]

  cpu { cores = var.worker_cpu_number }
  memory { dedicated = var.worker_memory_size }

  agent { enabled = true }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.worker_disk_size
    discard      = "on"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${local.worker_ips[count.index]}/${local.prefix_length}"
        gateway = var.gateway
      }
    }
    dns { servers = var.dns_servers }
    user_account {
      username = "debian"
      keys     = [var.ssh_public_key]
    }
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    control_planes = [for i, vm in proxmox_virtual_environment_vm.control_plane : { name = vm.name, ip = local.control_plane_ips[i] }]
    workers        = [for i, vm in proxmox_virtual_environment_vm.workers : { name = vm.name, ip = local.worker_ips[i] }]
  })
  filename = "${path.module}/../ansible/inventory.yml"
}
