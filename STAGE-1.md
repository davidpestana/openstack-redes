# 🚀 STAGE-1: Preparación del nodo bastion y configuración inicial de Ansible

Este documento recoge todos los pasos realizados para la configuración inicial del nodo `bastion`, la verificación del entorno y la comprobación estructural del stack `openstack-ansible`. No se ejecuta aún ningún playbook de despliegue: esta etapa cierra con el clonado, organización y verificación básica del entorno.

---

## 🌟 Objetivos de esta etapa

- ⚙️ Configurar correctamente el nodo `bastion` como nodo de control.
- 🔐 Verificar el acceso por SSH desde `bastion` a todos los nodos del laboratorio.
- 📦 Clonar y comprobar el repositorio `openstack-ansible`.
- 🛡️ Instalar dependencias necesarias no incluidas en la provisión de Vagrant.
- 📁 Organizar la estructura del stack en los directorios adecuados (`/etc/`, `/opt/`).

---

## 💪 1. Configuración del nodo bastion

### 🔑 1.1 Generación de claves SSH

Se creó un par de claves `id_rsa` / `id_rsa.pub` en la carpeta del proyecto `vagrant/`, que se usaron para:

- Inyectar la clave privada en `bastion`
- Inyectar la clave pública en los nodos `controller`, `network`, `compute`, `storage`

Esta configuración se automatizó mediante provisioners en el `Vagrantfile`, garantizando acceso por SSH sin contraseña desde `bastion` a los nodos tras `vagrant up`.

### 🌐 1.2 Red de gestión

Todos los nodos están conectados a la red `openstack-mgmt` con direcciones IP en `192.168.56.0/24`. En concreto:

| 🧐 Nodo      | 🌍 IP de gestión |
| ------------ | ---------------- |
| `bastion`    | `192.168.56.8`   |
| `controller` | `192.168.56.10`  |
| `compute`    | `192.168.56.11`  |
| `network`    | `192.168.56.12`  |
| `storage`    | `192.168.56.13`  |

### 🗈️ 1.3 Configuración de /etc/hosts

En el nodo `bastion`, se editaron las entradas del archivo `/etc/hosts` para asociar los nombres de los nodos con sus direcciones IP. Esto permite referirse a los nodos por nombre en vez de IP.

```bash
192.168.56.8 bastion
192.168.56.10 controller
192.168.56.11 compute
192.168.56.12 network
192.168.56.13 storage
```

### 📂 1.4 Configuración de acceso remoto VS Code (Remote SSH)

Se utilizó el archivo `id_rsa` creado en el directorio `vagrant/` para configurar el acceso remoto desde VS Code al nodo `bastion`.

1. Crear o verificar archivo `~/.ssh/config`:

```ssh-config
Host bastion
  HostName 192.168.56.8
  User vagrant
  IdentityFile ~/Projects/openstack/vagrant/id_rsa
```

2. Desde VS Code: `Remote-SSH: Connect to Host...` → seleccionar `bastion`

3. Confirmar que se puede navegar en `/opt/` y `/etc/` desde el explorador remoto.

💡 También puede obtenerse la clave privada directamente con:

```bash
vagrant ssh bastion -- cat /home/vagrant/.ssh/id_rsa > ~/.ssh/id_rsa_bastion
chmod 600 ~/.ssh/id_rsa_bastion
```

Y configurarla en VS Code como `IdentityFile`.

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

❌ No se utilizó `ping` como método de verificación para evitar problemas con ICMP o firewalls. La validación de red se basó exclusivamente en la disponibilidad de SSH funcional.

---

## ⚙️ 3. Preparación del entorno `openstack-ansible`

### 🛠️ 3.1 Instalación de dependencias necesarias en bastion

```bash
sudo apt update && sudo apt install -y python3-pip git python3-venv sshpass
```

### 🗓️ 3.2 Clonado del repositorio y organización del stack

```bash
cd ~
git clone -b stable/2024.2 https://opendev.org/openstack/openstack-ansible.git
sudo mv ~/openstack-ansible /opt/
sudo mkdir -p /etc/openstack_deploy
sudo chown -R vagrant:vagrant /opt/openstack-ansible /etc/openstack_deploy
```

### 📦 3.3 Copia de archivos de configuración base

El bootstrap **no copia automáticamente** los archivos necesarios en `/etc/openstack_deploy`, por lo que es necesario hacerlo manualmente:

```bash
cp -r /opt/openstack-ansible/etc/openstack_deploy/* /etc/openstack_deploy/
```

Esto colocará en su sitio los archivos `openstack_user_config.yml`, `user_variables.yml`, `user_secrets.yml`, entre otros.

### 🔧 3.4 Bootstrap del entorno Ansible

Ejecutar el script como `root`:

```bash
cd /opt/openstack-ansible
sudo ./scripts/bootstrap-ansible.sh
```

El éxito del script genera el entorno virtual y deja disponible el comando `openstack-ansible`.

Para activar el entorno manualmente:

```bash
sudo su -
source /usr/local/bin/openstack-ansible.rc
```

⚠️ **Importante:** si no se ejecuta como `root`, puede aparecer un error como:

```bash
mkdir: cannot create directory ‘/openstack’: Permission denied
```

Esto es esperado: el archivo `.rc` intenta crear directorios de trabajo que requieren permisos elevados. Se recomienda usar `source` como `root`.

✅ A diferencia de los intentos previos, ahora funciona correctamente porque el entorno fue preparado desde cero con rutas consistentes y usando el script oficial `bootstrap-ansible.sh`, que configura todos los enlaces esperados en `/usr/local/bin`.

### 📃 3.5 Creación del directorio de logs para Ansible

El entorno `openstack-ansible` intenta registrar logs en `/openstack/log/ansible-logging/`, que requiere permisos elevados. Para evitar errores:

```bash
sudo mkdir -p /openstack/log/ansible-logging
sudo chown -R vagrant:vagrant /openstack
```

### 🔒 3.6 Permisos del archivo de log

En caso de que el archivo de log no se haya creado automáticamente o no tenga permisos adecuados, ejecutar:

```bash
sudo touch /openstack/log/ansible-logging/ansible.log
sudo chown vagrant:vagrant /openstack/log/ansible-logging/ansible.log
sudo chmod 664 /openstack/log/ansible-logging/ansible.log
```

Esto asegura que `openstack-ansible` pueda escribir los logs sin errores.

---

## 🧼 4. Validaciones del entorno bastion

Antes de continuar con la etapa 2, es recomendable verificar que `bastion` cumple con los siguientes checks:

### ✅ Directorios esperados

```bash
test -d /opt/openstack-ansible && echo OK: /opt/openstack-ansible existe
test -d /etc/openstack_deploy && echo OK: /etc/openstack_deploy existe
```

### ✅ Archivos de configuración mínimos

```bash
ls -l /etc/openstack_deploy/openstack_user_config.yml
ls -l /etc/openstack_deploy/user_variables.yml
ls -l /etc/openstack_deploy/user_secrets.yml
```

### ✅ Permisos correctos

```bash
ls -ld /opt/openstack-ansible /etc/openstack_deploy
```
> El propietario debe ser `vagrant` para ambas rutas.

### ✅ Entorno virtual y binarios disponibles

```bash
which openstack-ansible
openstack-ansible --version
```

Debe devolver una ruta como `/opt/ansible-runtime/bin/openstack-ansible`

### ✅ Comando de entorno `rc`

```bash
cat /usr/local/bin/openstack-ansible.rc
```
Debe contener variables de entorno como `ANSIBLE_INVENTORY`, `ANSIBLE_CONFIG`, `PYTHONPATH`, etc.

---

## ✅ Conclusión

El nodo `bastion` está completamente preparado para iniciar el despliegue con Ansible. Está configurado como nodo de control, tiene conectividad funcional con el resto del entorno vía SSH, el stack `openstack-ansible` está organizado correctamente en `/opt/`, los archivos de configuración han sido copiados a `/etc/openstack_deploy`, y se ha verificado su correcta instalación y carga de entorno.

👉 La siguiente etapa se documentará en `STAGE-2`, donde comenzaremos a editar el inventario `openstack_user_config.yml` y a lanzar los primeros playbooks de instalación (`setup-hosts.yml`).

