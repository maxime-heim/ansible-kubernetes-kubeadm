all:
  vars:
    ansible_user: debian
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519
  children:
    # Only the first control plane: site.yml runs "kubeadm init" on this whole group.
    control_plane:
      hosts:
        ${control_planes[0].name}:
          ansible_host: ${control_planes[0].ip}
%{ if length(control_planes) > 1 ~}
    # Extra control planes, to be joined with "kubeadm join --control-plane".
    control_plane_secondary:
      hosts:
%{ for cp in slice(control_planes, 1, length(control_planes)) ~}
        ${cp.name}:
          ansible_host: ${cp.ip}
%{ endfor ~}
%{ endif ~}
    workers:
      hosts:
%{ for worker in workers ~}
        ${worker.name}:
          ansible_host: ${worker.ip}
%{ endfor ~}
