# 📦 Vagrant Cheat Sheet

## 🧠 ¿Qué es Vagrant?

Vagrant es una herramienta que permite crear y configurar entornos de desarrollo virtualizados de manera fácil y reproducible mediante un simple archivo `Vagrantfile`.

---

## ⚙️ Instalación

**Debian/Ubuntu**
```bash
sudo apt install vagrant
```

**macOS (Homebrew)**
```bash
brew install --cask vagrant
```

**Requiere proveedor** como VirtualBox, VMware, Docker o Hyper-V.

---

## 📁 Comandos Básicos

| Acción                         | Comando                             |
|-------------------------------|-------------------------------------|
| Inicializar proyecto           | `vagrant init`                      |
| Crear e iniciar máquina        | `vagrant up`                        |
| Detener máquina                | `vagrant halt`                      |
| Destruir máquina               | `vagrant destroy`                   |
| Conectarse por SSH             | `vagrant ssh`                       |
| Ver estado                     | `vagrant status`                    |
| Recargar con cambios           | `vagrant reload`                    |
| Reprovisionar manualmente      | `vagrant provision`                 |

---

## 📄 Vagrantfile Básico

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.network "private_network", type: "dhcp"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt update
    apt install -y apache2
  SHELL
end
```

---

## 🌐 Redes

| Tipo               | Descripción                                       |
|--------------------|---------------------------------------------------|
| `forwarded_port`   | Redirecciona puertos entre host y VM             |
| `private_network`  | IP interna para host-VM                          |
| `public_network`   | IP pública (bridge a red local)                  |

Ejemplo:
```ruby
config.vm.network "forwarded_port", guest: 80, host: 8080
config.vm.network "private_network", ip: "192.168.33.10"
```

---

## 📦 Boxes

| Acción         | Comando                                 |
|----------------|------------------------------------------|
| Buscar         | `vagrant cloud search ubuntu`            |
| Añadir         | `vagrant box add ubuntu/bionic64`        |
| Listar         | `vagrant box list`                       |
| Eliminar       | `vagrant box remove ubuntu/bionic64`     |
| Actualizar     | `vagrant box update`                     |

---

## 🔧 Provisioning

**Inline Shell**
```ruby
config.vm.provision "shell", inline: "echo Hola Mundo"
```

**Script externo**
```ruby
config.vm.provision "shell", path: "scripts/setup.sh"
```

**Con Ansible**
```ruby
config.vm.provision "ansible" do |ansible|
  ansible.playbook = "provision/playbook.yml"
end
```

---

## 🗂️ Carpetas Compartidas

```ruby
config.vm.synced_folder "./app", "/var/www/html"
```

Por defecto, la raíz del proyecto se monta en `/vagrant`.

---

## 🔐 SSH

Obtener datos SSH:
```bash
vagrant ssh-config
```

Conexión manual:
```bash
ssh -i ~/.vagrant.d/insecure_private_key vagrant@192.168.33.10
```

---

## 🧹 Limpieza

| Acción             | Comando           |
|--------------------|-------------------|
| Detener VM         | `vagrant halt`    |
| Eliminar VM        | `vagrant destroy` |
| Borrar metadatos   | `rm -rf .vagrant` |

---

## 🧬 Multi-Máquina

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "web" do |web|
    web.vm.box = "ubuntu/bionic64"
  end

  config.vm.define "db" do |db|
    db.vm.box = "ubuntu/bionic64"
  end
end
```

Uso:
```bash
vagrant up web
vagrant ssh db
```

---

## 🧑‍💻 Tips

- El `Vagrantfile` es Ruby: puedes usar lógica.
- Ignora `.vagrant/` en tus repositorios (`.gitignore`).
- Usa `vagrant snapshot` si tu provider lo permite.
- Puedes usar Vagrant con Docker como backend (`config.vm.provider "docker"`).

---