#!/bin/bash
NODE="$1"
echo "==> Inyectando clave pública al usuario root en $NODE"
vagrant ssh "$NODE" -c "sudo mkdir -p /root/.ssh && sudo bash -c 'cat /vagrant/id_rsa.pub >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys'"
echo "==> Nodo $NODE preparado para acceso root por SSH desde bastion"