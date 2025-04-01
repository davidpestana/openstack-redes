# 🚪 Laboratorio de Redes con OpenStack y Ansible

Este laboratorio forma parte de un curso orientado a la comprensión profunda de **redes en entornos OpenStack**. El objetivo principal es desplegar una infraestructura distribuida, similar a un entorno de producción real, para estudiar el comportamiento de las redes, la conectividad entre nodos y la seguridad de los servicios en un ecosistema OpenStack.

---

## 🌐 Topología del entorno

El entorno se compone de varias máquinas virtuales orquestadas con **Vagrant + VirtualBox**. Desde un nodo `bastion`, se realiza el despliegue completo de OpenStack usando **Ansible**.

| Nodo         | Rol principal                         |
| ------------ | ------------------------------------- |
| `bastion`    | Nodo operador (control Ansible)       |
| `controller` | Controlador de servicios OpenStack    |
| `network`    | Nodo de red (Neutron, router)         |
| `compute`    | Nodo de cómputo para instancias       |
| `storage`    | Nodo para servicios de almacenamiento |

Cada nodo está conectado a **cuatro redes** virtuales:

- `management` (control)
- `provider` (acceso externo)
- `overlay` (túneles VXLAN/GRE)
- `storage` (volúmenes y servicios de disco)

---

## 📅 Requisitos técnicos

### Sistema operativo compatible

- Linux (Ubuntu, Debian, Fedora, etc.)
- macOS
- Windows 10/11 con **WSL2** (recomendado)

### Requisitos hardware

| Recurso        | Mínimo                             | Recomendado   |
| -------------- | ---------------------------------- | ------------- |
| CPU            | 2 núcleos                          | 4 núcleos     |
| RAM            | 8 GB                               | 16 GB         |
| Almacenamiento | 30 GB libres                       | 50+ GB en SSD |
| Virtualización | VT-x / AMD-V activado en BIOS/UEFI |               |

### Software necesario

- Vagrant `>= 2.3.x`
- VirtualBox `>= 6.1`
- Visual Studio Code (opcional)
- Extensiones recomendadas:
  - Remote - SSH
  - WSL (si aplica)

---

## 🚀 Estado del entorno antes del despliegue

Este documento cubre el estado del laboratorio **antes de lanzar cualquier playbook de Ansible**. Nos enfocamos exclusivamente en validar que el entorno de Vagrant y `bastion` estén correctamente configurados y conectados a los nodos.

### 🔌 Validación de conectividad SSH desde `bastion`

```bash
ssh -o StrictHostKeyChecking=no vagrant@192.168.56.10  # controller
ssh -o StrictHostKeyChecking=no vagrant@192.168.56.11  # compute
ssh -o StrictHostKeyChecking=no vagrant@192.168.56.12  # network
ssh -o StrictHostKeyChecking=no vagrant@192.168.56.13  # storage
```

✅ El acceso debe ser sin contraseña gracias a las claves inyectadas desde el `Vagrantfile`.

### 💡 Comprobación de red

```bash
ip a
```

- Asegurarse de que todos los nodos están conectados a la red `192.168.56.0/24`.
- Confirmar la presencia de interfaces de red internas `enpXsY`, `br-*`, etc.

### 📝 (Opcional) Añadir nombres al `/etc/hosts` en `bastion`

Para facilitar el uso de nombres en lugar de IPs, puedes editar `/etc/hosts` y añadir:

```
192.168.56.10 controller
192.168.56.11 compute
192.168.56.12 network
192.168.56.13 storage
```

Esto permite usar nombres como `ssh controller` directamente desde `bastion`.

---

## 🧰 Operaciones útiles con Vagrant

```bash
vagrant up          # Levanta todas las VMs definidas en el Vagrantfile
vagrant status      # Verifica el estado de las VMs
vagrant halt        # Detiene todas las VMs
vagrant destroy     # Elimina todas las VMs (confirmación requerida)
vagrant ssh bastion # Accede directamente al nodo bastion
```

💡 **Consejo:** Si deseas reiniciar completamente el entorno, realiza:

```bash
vagrant destroy -f && vagrant up
```

Esto asegura una provisión limpia desde cero.

---

## 🔐 Generación y uso de claves SSH para Vagrant y VS Code

### 1. Crear claves si no existen (modo manual)

```bash
cd vagrant
ssh-keygen -t rsa -b 4096 -f id_rsa -N ""
```

Esto genera `id_rsa` y `id_rsa.pub`, que serán utilizadas automáticamente por los scripts de provisión.

### 2. Extraer la clave SSH generada por Vagrant (modo automático)

Alternativamente, puedes reutilizar la clave que Vagrant genera automáticamente para `bastion`:

```bash
vagrant ssh-config bastion > ssh-bastion.conf
```

Luego extrae la ruta del `IdentityFile` que suele apuntar a algo como:

```bash
IdentityFile "/home/tu_usuario/.vagrant.d/insecure_private_key"
```

Puedes usar este archivo directamente en tu configuración de VS Code SSH.

### 3. Configurar acceso remoto en VS Code

Edita tu archivo `~/.ssh/config` en tu máquina local:

```ssh-config
Host bastion
  HostName 192.168.56.8
  User vagrant
  IdentityFile ~/Projects/openstack/vagrant/id_rsa
```

O bien usa el `IdentityFile` extraído de `ssh-config` generado por Vagrant.

### 4. Conectarte desde VS Code

Usa la paleta de comandos (`F1` o `Ctrl+Shift+P`) y selecciona:

```
Remote-SSH: Connect to Host...
```

Luego elige `bastion`. Una vez conectado, podrás abrir directorios como `/opt/openstack-ansible` o `/etc/openstack_deploy` desde el explorador.

---

## 🔍 Validaciones sugeridas

### Script opcional `check_ssh.sh`

```bash
#!/bin/bash
for host in controller compute network storage; do
  echo "🔗 SSH a $host ..."
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 vagrant@$host 'hostname'
  echo
done
```

Guardar en `bastion`, hacer ejecutable y lanzar:

```bash
chmod +x check_ssh.sh
./check_ssh.sh
```

---

## 📂 Estructura esperada del proyecto

```text
~/Projects/openstack/
│
├── vagrant/
│   ├── Vagrantfile
│   ├── setup_vbox_networks.sh
│   └── id_rsa.pub / id_rsa
│
└── [En bastion]
    └── /etc/openstack_deploy/
        ├── (aún sin configurar)

    └── /opt/openstack-ansible/
        ├── scripts/
        └── playbooks/
```

---

## ✅ Resultado esperado de esta etapa

Al finalizar esta etapa:

- El nodo `bastion` debe estar accesible por SSH y VS Code.
- Todos los nodos deben ser accesibles desde `bastion` por SSH.
- El entorno de red debe estar correctamente definido.
- La estructura base de archivos (`/opt/`, `/etc/`) debe existir.

⛔️ **No se ejecutan playbooks ni configuraciones OpenStack todavía.**

