# 🧪 Laboratorio de Redes con OpenStack y Ansible

Este laboratorio forma parte de un curso orientado a la comprensión profunda de **redes en entornos OpenStack**. El objetivo principal es desplegar una infraestructura distribuida, similar a un entorno de producción real, para estudiar el comportamiento de las redes, la conectividad entre nodos y la seguridad de los servicios en un ecosistema OpenStack.

---

## 🌐 Topología del entorno

El entorno se compone de varias máquinas virtuales orquestadas con **Vagrant + VirtualBox**. Desde un nodo `bastion`, se realiza el despliegue completo de OpenStack usando **Ansible**.

| Nodo        | Rol principal                   |
|-------------|----------------------------------|
| `bastion`   | Nodo operador (control Ansible) |
| `controller`| Controlador de servicios OpenStack |
| `network`   | Nodo de red (Neutron, router)    |
| `compute`   | Nodo de cómputo para instancias  |
| `storage`   | Nodo para servicios de almacenamiento |

Cada nodo está conectado a **cuatro redes** virtuales:

- `management` (control)
- `provider` (acceso externo)
- `overlay` (túneles VXLAN/GRE)
- `storage` (volúmenes y servicios de disco)

---

## 🖥️ Requisitos técnicos

### Sistema operativo compatible

- Linux (Ubuntu, Debian, Fedora, etc.)
- macOS
- Windows 10/11 con **WSL2** (recomendado)

### Requisitos hardware

| Recurso        | Mínimo       | Recomendado    |
|----------------|--------------|----------------|
| CPU            | 2 núcleos    | 4 núcleos      |
| RAM            | 8 GB         | 16 GB          |
| Almacenamiento | 30 GB libres | 50+ GB en SSD  |
| Virtualización | VT-x / AMD-V activado en BIOS/UEFI |

### Software necesario

- Vagrant `>= 2.3.x`
- VirtualBox `>= 6.1`
- Visual Studio Code (opcional)
- Extensiones recomendadas:
  - Remote - SSH
  - WSL (si aplica)

---

## 🚀 Estado del entorno actual

- ✅ Todas las VMs (`bastion`, `controller`, `network`, `compute`, `storage`) están encendidas (`vagrant status`)
- ✅ Configurada conexión Remote - SSH desde VS Code hacia `bastion`
- ✅ Repositorio `ansible-openstack` clonado y operativo
- ✅ Archivos de configuración localizados en `/etc/openstack_deploy/`
- ✅ Resolución de nombres configurada en `/etc/hosts` (dentro de `bastion`)
- ✅ Comunicación por SSH desde `bastion` hacia todos los nodos

---

## ✅ Checks de estado del proyecto desde `bastion`

### Conectividad validada por SSH (no se usa `ping`)

Para garantizar una configuración 100% gestionada por Ansible, se omite el uso de `ping` y se valida conectividad mediante acceso SSH sin contraseña.

```bash
ssh -o StrictHostKeyChecking=no vagrant@192.168.56.10  # controller
ssh -o StrictHostKeyChecking=no vagrant@192.168.56.11  # compute
ssh -o StrictHostKeyChecking=no vagrant@192.168.56.12  # network
ssh -o StrictHostKeyChecking=no vagrant@192.168.56.13  # storage
```

El acceso funciona porque `bastion` inyecta su clave pública en todos los nodos en tiempo de `vagrant up`.

### Script opcional: `check_ssh.sh`

```bash
#!/bin/bash
for host in 192.168.56.10 192.168.56.11 192.168.56.12 192.168.56.13; do
  echo "🔗 Probando SSH a $host ..."
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 vagrant@$host 'hostname'
  echo
done
```

Guardar en `bastion`, hacer ejecutable (`chmod +x check_ssh.sh`) y ejecutar.

---

### Verificar interfaces de red

```bash
ip a
```

Asegurarse de que `bastion` y el resto de nodos están conectados a la red `192.168.56.X` (management).

### Verificar inventario de Ansible

Editar el archivo:

```bash
sudo nano /etc/openstack_deploy/openstack_user_config.yml
```

y definir los grupos de hosts y sus IPs en cada red.

---

## 📌 Pendiente por validar

- [ ] Confirmar conectividad SSH completa con todos los nodos
- [ ] Inventario completo de Ansible (`openstack_user_config.yml`)
- [ ] Ejecución de `setup-hosts.yml`

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
        ├── openstack_user_config.yml
        ├── user_variables.yml
        └── ...
```

---

## 🧠 Notas adicionales

- El archivo `/etc/hosts` en `bastion` debe contener las IPs e identificadores de los nodos.
- Se recomienda definir alias en `~/.bashrc` para ejecutar playbooks de forma rápida:

```bash
alias oap='openstack-ansible'
alias oap-hosts='openstack-ansible setup-hosts.yml'
alias oap-infra='openstack-ansible setup-infrastructure.yml'
alias oap-openstack='openstack-ansible setup-openstack.yml'
```