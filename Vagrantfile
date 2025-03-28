Vagrant.configure("2") do |config|

    # Configurar clave SSH de bastion
    bastion_ssh_pub_key = File.read(File.expand_path("id_rsa.pub")).strip
    bastion_ssh_priv_key = File.read(File.expand_path("id_rsa")).strip

    # Imagen base (Ubuntu Server 22.04)
    config.vm.box = "ubuntu/jammy64"

    # Máquina Bastión (Solo para administración)
    config.vm.define "bastion" do |bastion|
      bastion.vm.hostname = "bastion"
      bastion.vm.network "private_network", ip: "192.168.56.8" , virtualbox__intnet: "openstack-mgmt"
      bastion.vm.network "public_network", type: "dhcp"  # Conectado a NAT para Internet
      bastion.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = 2
        # Configuración manual del modo promiscuo en NIC2 (Red Interna) y NIC3 (Adaptador Puente)
        vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-vms"]
        vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-vms"]
      end

      bastion.vm.provision "shell", inline: <<-SHELL
        mkdir -p /home/vagrant/.ssh
        echo "#{bastion_ssh_priv_key}" > /home/vagrant/.ssh/id_rsa
        echo "#{bastion_ssh_pub_key}" >> /home/vagrant/.ssh/authorized_keys
        chmod 600 /home/vagrant/.ssh/id_rsa /home/vagrant/.ssh/authorized_keys
        chown -R vagrant:vagrant /home/vagrant/.ssh
      SHELL

    end
  
    # Máquina Controlador
    config.vm.define "controller" do |controller|
      controller.vm.hostname = "controller"  
      # Evitar que VirtualBox agregue una interfaz NAT por defecto
      controller.vm.network "private_network", ip: "192.168.56.10", virtualbox__intnet: "openstack-mgmt"
      controller.vm.network "private_network", ip: "10.0.0.10", virtualbox__intnet: "openstack-data"
      controller.vm.network "private_network", ip: "172.16.0.10", virtualbox__intnet: "openstack-storage"
      controller.vm.provider "virtualbox" do |vb|
        vb.memory = "8192"
        vb.cpus = 4
        # Configuración manual del modo promiscuo en NIC2, NIC3, NIC4 (Red Interna)
        vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-vms"]
        vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-vms"]
        vb.customize ["modifyvm", :id, "--nicpromisc4", "allow-vms"]
      end
      # Inyectar la clave pública de bastion en authorized_keys
      controller.vm.provision "shell", inline: <<-SHELL
        mkdir -p /home/vagrant/.ssh
        echo "#{bastion_ssh_pub_key}" >> /home/vagrant/.ssh/authorized_keys
        chmod 600 /home/vagrant/.ssh/authorized_keys
        chown -R vagrant:vagrant /home/vagrant/.ssh
      SHELL
    end
  
    # Máquina Nodo de Red (Neutron)
    config.vm.define "network" do |network|
      network.vm.hostname = "network"
      network.vm.network "private_network", ip: "192.168.56.12", virtualbox__intnet: "openstack-mgmt"
      network.vm.network "private_network", ip: "10.0.0.12", virtualbox__intnet: "openstack-data"
      network.vm.network "private_network", ip: "172.16.0.12", virtualbox__intnet: "openstack-storage"
      network.vm.network "public_network", type: "dhcp"  # Acceso a Internet solo desde este nodo
      network.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = 2
        # Configuración manual del modo promiscuo en NIC2, NIC3, NIC4 (Red Interna)
        vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-vms"]
        vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-vms"]
        vb.customize ["modifyvm", :id, "--nicpromisc4", "allow-vms"]
      end
      # Inyectar la clave pública de bastion en authorized_keys
      network.vm.provision "shell", inline: <<-SHELL
        mkdir -p /home/vagrant/.ssh
        echo "#{bastion_ssh_pub_key}" >> /home/vagrant/.ssh/authorized_keys
        chmod 600 /home/vagrant/.ssh/authorized_keys
        chown -R vagrant:vagrant /home/vagrant/.ssh
      SHELL
    end
  
    # Máquina Compute (Hypervisor)
    config.vm.define "compute" do |compute|
      compute.vm.hostname = "compute"
      compute.vm.network "private_network", ip: "192.168.56.11", virtualbox__intnet: "openstack-mgmt"
      compute.vm.network "private_network", ip: "10.0.0.11", virtualbox__intnet: "openstack-data"
      compute.vm.provider "virtualbox" do |vb|
        vb.memory = "8192"
        vb.cpus = 4
        # Configuración manual del modo promiscuo en NIC2, NIC3 (Red Interna)
        vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-vms"]
        vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-vms"]
      end
      # Inyectar la clave pública de bastion en authorized_keys
      compute.vm.provision "shell", inline: <<-SHELL
        mkdir -p /home/vagrant/.ssh
        echo "#{bastion_ssh_pub_key}" >> /home/vagrant/.ssh/authorized_keys
        chmod 600 /home/vagrant/.ssh/authorized_keys
        chown -R vagrant:vagrant /home/vagrant/.ssh
      SHELL
    end
  
    # Máquina Almacenamiento (Opcional)
    config.vm.define "storage" do |storage|
      storage.vm.hostname = "storage"
      storage.vm.network "private_network", ip: "192.168.56.13", virtualbox__intnet: "openstack-mgmt"
      storage.vm.network "private_network", ip: "172.16.0.13", virtualbox__intnet: "openstack-storage"
      storage.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = 2
        # Configuración manual del modo promiscuo en NIC2, NIC3 (Red Interna)
        vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-vms"]
        vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-vms"]
      end
      # Inyectar la clave pública de bastion en authorized_keys
      storage.vm.provision "shell", inline: <<-SHELL
        mkdir -p /home/vagrant/.ssh
        echo "#{bastion_ssh_pub_key}" >> /home/vagrant/.ssh/authorized_keys
        chmod 600 /home/vagrant/.ssh/authorized_keys
        chown -R vagrant:vagrant /home/vagrant/.ssh
      SHELL
    end
  end
