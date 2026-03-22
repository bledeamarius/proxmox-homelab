#!/bin/bash
set -e

VM_ID=$1
VM_NAME=$2
CPUS=$3
MEMORY=$4
DISK_SIZE=$5


echo "Args: VM_ID=$1 VM_NAME=$2 MEMORY=$3 CPUS=$4 DISK_SIZE=$5"

if qm status $VM_ID &>/dev/null; then
  echo "Template $VM_ID exists, destroying..."
  qm stop $VM_ID --skiplock 2>/dev/null || true
  qm destroy $VM_ID --skiplock --purge 2>/dev/null || true
  echo "Waiting for cleanup..."
  sleep 5
fi

# Download cloud image
wget -q -O /tmp/debian-12-cloud.qcow2 https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

apt-get install -y libguestfs-tools

# Customize image
virt-customize -a /tmp/debian-12-cloud.qcow2 --run-command 'echo -n > /etc/machine-id'
virt-customize -a /tmp/debian-12-cloud.qcow2 --install qemu-guest-agent --network
virt-customize -a /tmp/debian-12-cloud.qcow2 --run-command 'systemctl enable qemu-guest-agent'
virt-customize -a /tmp/debian-12-cloud.qcow2 --run-command 'systemctl unmask qemu-guest-agent'
# Create base VM
qm create $VM_ID --name $VM_NAME --memory $MEMORY --cores $CPUS --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk $VM_ID /tmp/debian-12-cloud.qcow2 local-zfs

DISK=$(qm config $VM_ID | grep '^unused0' | awk '{print $2}')

# Configure
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $DISK
qm set $VM_ID --ide2 local-zfs:cloudinit
qm set $VM_ID --boot order=scsi0
qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --agent enabled=1
qm set $VM_ID --ostype l26

# Convert to template
qm template $VM_ID

# Cleanup
rm /tmp/debian-12-cloud.qcow2

echo "Template $VM_ID created successfully"
sleep 7
