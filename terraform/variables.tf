#######################################
#         PROVIDER INFORMATIONS       #
#                                     #
#######################################

variable "proxmox_endpoint" {
  description = "Proxmox API URL, ex: https://192.168.1.75:8006"
  type        = string
  default     = "https://192.168.1.76:8006"
}

variable "proxmox_credentials" {
  description = "Credentials Proxmox"
  type        = string
}

variable "ssh_public_key" {
  description = "Clé SSH publique injectée dans les VMs via cloud-init"
  type        = string
}

#######################################
#         PROXMOX INFORMATIONS        #
#                                     #
#######################################

variable "template_id" {
  description = "VM ID du template Debian 13 à cloner"
  type        = number
  default     = 9004
}

variable "proxmox_nodes" {
  description = "Liste des nœuds Proxmox (VMs réparties entre les nœuds)"
  type        = list(string)
  default     = ["pve1", "pve2", "pve3"]
}

variable "template_node" {
  description = "Nœud Proxmox où le template_id est stocké"
  type        = string
  default     = "pve2"
}

variable "datastore_id" {
  description = "Storage Proxmox pour les VMs (doit supporter les images VM)"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Bridge réseau des VMs"
  type        = string
  default     = "vmbr0"
}

#######################################
#         NETWORK INFORMATIONS        #
#                                     #
#######################################

# The node addresses must stay outside the DHCP pool, the MetalLB range
# and the API VIP (see ansible/group_vars/all.yml).

variable "node_cidr" {
  description = "LAN of the nodes (same value as node_cidr in group_vars)"
  type        = string
  default     = "192.168.1.0/24"
}

variable "gateway" {
  description = "Default gateway of the nodes"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "DNS servers of the nodes"
  type        = list(string)
  default     = ["192.168.1.1"]
}

variable "control_plane_first_host" {
  description = "Host number of cp-01 in node_cidr (221 => 192.168.1.221), then +1 per control plane"
  type        = number
  default     = 221
}

variable "worker_first_host" {
  description = "Host number of worker-01 in node_cidr (231 => 192.168.1.231), then +1 per worker"
  type        = number
  default     = 231
}

############################################
#         CONTROL PLAN INFORMATIONS        #
#                                          #
############################################

variable "control_plane_count" {
  description = "Number of control planes (odd number, for the etcd quorum)"
  type        = number
  default     = 3

  validation {
    condition     = contains([1, 3, 5, 7], var.control_plane_count)
    error_message = "control_plane_count must be 1, 3, 5 or 7."
  }
}

variable "control_plan_disk_size" {
  description = "Taille des disques des control plan"
  type        = number
  default     = 20
}

variable "control_plan_memory_size" {
  description = "Volume de RAM pour les control plan"
  type        = number
  default     = 7168
}

variable "control_plan__cpu_number" {
  description = "Nombre de coeur par VM pour les control plan"
  type        = number
  default     = 2
}

############################################
#           WORKER INFORMATIONS            #
#                                          #
############################################

variable "worker_count" {
  description = "Number of workers (9 max: VM IDs 201 to 209)"
  type        = number
  default     = 3

  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 9 && floor(var.worker_count) == var.worker_count
    error_message = "worker_count must be an integer between 1 and 9."
  }
}

variable "worker_memory_size" {
  description = "Volume de RAM pour les workers"
  type        = number
  default     = 6144
}

variable "worker_disk_size" {
  description = "Taille des disques des workers"
  type        = number
  default     = 20
}

variable "worker_cpu_number" {
  description = "Nombre de coeur par VM pour les worker"
  type        = number
  default     = 2
}
