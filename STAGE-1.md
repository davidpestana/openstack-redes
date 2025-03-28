# 🚀 STAGE-1: Preparación del nodo bastion y configuración inicial de Ansible

Este documento recoge todos los pasos realizados para la configuración inicial del nodo `bastion`, la verificación del entorno y la comprobación estructural del stack `openstack-ansible`. No se ejecuta aún ningún playbook de despliegue: esta etapa cierra con el clonado, organización y verificación básica del entorno.

---

## 🎯 Objetivos de esta etapa

- ⚙️ Configurar correctamente el nodo `bastion` como nodo de control.
- 🔐 Verificar el acceso por SSH desde `bastion` a todos los nodos del laboratorio.
- 📦 Clonar y comprobar el repositorio `openstack-ansible`.
- 🧱 Instalar dependencias necesarias no incluidas en la provisión de Vagrant.
- 📁 Organizar la estructura del stack en los directorios adecuados (`/etc/`, `/opt/`).

---

## 🖥️ 1. Configuración del nodo bastion

### 🔑 1.1 Generación de claves SSH

Se creó un par de claves `id_rsa` / `id_rsa.pub` en la carpeta del proyecto `vagrant/`, que se usaron para:

- Inyectar la clave privada en `bastion`
- Inyectar la clave pública en los nodos `controller`, `network`, `compute`, `storage`

Esta configuración se automatizó mediante provisioners en el `Vagrantfile`, garantizando acceso por SSH sin contraseña desde `bastion` a los nodos tras `vagrant up`.

### 🌐 1.2 Red de gestión

Todos los nodos están conectados a la red `openstack-mgmt` con direcciones IP en `192.168.56.0/24`. En concreto:

| 🧩 Nodo      | 🌍 IP de gestión |
| ------------ | ---------------- |
| `bastion`    | `192.168.56.8`   |
| `controller` | `192.168.56.10`  |
| `compute`    | `192.168.56.11`  |
| `network`    | `192.168.56.12`  |
| `storage`    | `192.168.56.13`  |

### 📝 1.3 Configuración de /etc/hosts

En el nodo `bastion`, se editaron las entradas del archivo `/etc/hosts` para asociar los nombres de los nodos con sus direcciones IP. Esto permite referirse a los nodos por nombre en vez de IP.

```
192.168.56.8 bastion
192.168.56.10 controller
192.168.56.11 compute
192.168.56.12 network
192.168.56.13 storage
```

---

## 🔗 2. Verificación de conectividad y acceso

Desde `bastion`, se verificó acceso por SSH a cada nodo usando su nombre:

```bash
ssh -o StrictHostKeyChecking=no vagrant@controller
ssh -o StrictHostKeyChecking=no vagrant@compute
ssh -o StrictHostKeyChecking=no vagrant@network
ssh -o StrictHostKeyChecking=no vagrant@storage
```

✅ Este acceso es posible sin contraseña debido a la inyección de la clave pública de `bastion` en cada nodo.

🚫 No se utilizó `ping` como método de verificación para evitar problemas con ICMP o firewalls. La validación de red se basó exclusivamente en la disponibilidad de SSH funcional, como requiere Ansible.

---

## ⚙️ 3. Preparación del entorno `openstack-ansible`

### 🛠️ 3.1 Instalación de dependencias necesarias en bastion

Aunque el `Vagrantfile` de `bastion` provee configuraciones básicas, fue necesario instalar manualmente algunos paquetes dentro de `bastion`:

```bash
sudo apt update && sudo apt install -y python3-pip git python3-venv sshpass
```

### 📥 3.2 Clonado del repositorio y organización del stack

Se clonó el repositorio oficial de `openstack-ansible` en la rama deseada (`stable/2024.2`) en el directorio de trabajo del usuario:

```bash
cd ~
git clone -b stable/2024.2 https://opendev.org/openstack/openstack-ansible.git
```

A continuación, se movieron los directorios relevantes a su ubicación convencional:

```bash
sudo mv ~/openstack-ansible /opt/
sudo mkdir -p /etc/openstack_deploy
sudo chown -R vagrant:vagrant /opt/openstack-ansible /etc/openstack_deploy
```

Esta estructura se ajusta a las rutas esperadas por los scripts y playbooks de OpenStack Ansible.

### 🔧 3.3 Bootstrap del entorno Ansible (verificación preliminar)

⚠️ **Este script debe ejecutarse con privilegios de superusuario.** Si se ejecuta como usuario `vagrant`, fallará con un mensaje indicando que debe ser ejecutado como root.

Para ejecutarlo correctamente:

```bash
cd /opt/openstack-ansible
sudo ./scripts/bootstrap-ansible.sh
```

Se ejecutó el script de bootstrap una única vez con `sudo` para instalar los componentes necesarios y generar la estructura de trabajo de Ansible. No es necesario volver a ejecutarlo como validación, ya que su éxito se valida automáticamente por la creación del entorno virtual y la disponibilidad de los comandos `openstack-ansible` y `ansible-playbook`.

```bash
cd /opt/openstack-ansible
sudo ./scripts/bootstrap-ansible.sh
```

Al finalizar, el entorno puede activarse con:

```bash
source /usr/local/bin/openstack-ansible.rc
```

✅ En este punto se comprueba que el stack se ha descargado correctamente, que sus scripts de entorno funcionan, y que las rutas necesarias (`/etc/openstack_deploy/`, `/opt/openstack-ansible/`) están accesibles y correctamente preparadas.

ℹ️ También existe el script `run_tests.sh`, que se utiliza para ejecutar pruebas automatizadas del propio proyecto `openstack-ansible`. Este script es útil para desarrolladores o integradores que quieran validar que una modificación del repositorio no ha roto su funcionalidad básica. No se ejecuta en esta etapa.

⛔ **Aún no se ejecutan playbooks ni se crean contenedores.**

---

## ✅ Conclusión

El nodo `bastion` está completamente preparado para iniciar el despliegue con Ansible. Está configurado como nodo de control, tiene conectividad funcional con el resto del entorno vía SSH, el stack `openstack-ansible` está organizado correctamente en `/opt/`, y se ha verificado su correcta instalación y carga de entorno.

👉 La siguiente etapa se documentará en `STAGE-2`, donde comenzaremos a editar el inventario `openstack_user_config.yml` y a lanzar los primeros playbooks de instalación (`setup-hosts.yml`).

