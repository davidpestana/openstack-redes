# 🚀 STAGE-3: Expansión del Inventario y Preparación de Hosts

Este stage amplía el inventario de forma progresiva para incluir nuevos nodos y contenedores. Además, ejecutaremos el primer playbook de despliegue: `setup-hosts.yml`.

> ⚠️ **Recuerda**: los contenedores LXC **se crearán dentro de los nodos definidos en el inventario**, como `controller`, y **no** en el nodo `bastion`. El nodo `bastion` se utiliza sólo como punto de orquestación.

---

## 🌟 Objetivos

- ➕ Ampliar el inventario con nuevos grupos: `repo-infra_hosts`, `keystone_hosts`, `compute_hosts`, `infra_hosts`...
- ⚙️ Ejecutar `setup-hosts.yml` para configurar los hosts y contenedores base.
- 📋 Validar contenedores LXC generados.
- 🔗 Reforzar el flujo: definir -> verificar -> desplegar.

---

## 📂 1. Ampliación del inventario (`openstack_user_config.yml`)

```yaml
repo-infra_hosts:
  controller:
    ip: 192.168.56.10

keystone_hosts:
  controller:
    ip: 192.168.56.10

infra_hosts:
  controller:
    ip: 192.168.56.10

compute_hosts:
  compute:
    ip: 192.168.56.11
```

> ✅ Asegúrate de que la IP `192.168.56.11` (nodo compute) esté creada por Vagrant.

Ejecuta:
```bash
vagrant up compute
```

Y valida conectividad:
```bash
ping 192.168.56.11
```

---

## 🔍 2. Verificación del inventario extendido

```bash
source /opt/ansible-runtime/bin/activate
python3 /opt/openstack-ansible/inventory/dynamic_inventory.py --list | jq 'keys'
```

Confirma que aparecen nuevos grupos: `repo-infra_hosts`, `keystone_hosts`, `infra_hosts`, `compute_hosts`.

> ⚠️ Si no tienes instalado `jq`:
```bash
sudo apt install -y jq
```

---

## ⚖️ 3. Ejecución de `setup-hosts.yml`

Este playbook crea los contenedores base para los grupos definidos.

> ⚠️ **Importante**: El archivo `setup-hosts.yml` se encuentra en el subdirectorio `playbooks/`. Debes **especificar la ruta completa** si no estás dentro del subdirectorio correspondiente.

Ubicación esperada del archivo:
```text
/opt/openstack-ansible/playbooks/setup-hosts.yml
```

Comando:
```bash
cd /opt/openstack-ansible
openstack-ansible playbooks/setup-hosts.yml
```

### 🔎 Requisitos previos para evitar errores comunes

Asegúrate de tener estas variables definidas en `/etc/openstack_deploy/user_variables.yml`:

```yaml
openstack_pki_dir: "/etc/openstack_deploy/pki"
openstack_ssh_keypairs_dir: "/etc/openstack_deploy/ssh"
openstack_ssh_keypairs_authorities: []
```

Ejecuta:
```bash
sudo mkdir -p /etc/openstack_deploy/pki /etc/openstack_deploy/ssh
sudo chown -R vagrant:vagrant /etc/openstack_deploy/{pki,ssh}
```

Valida que el directorio de logs tenga permisos adecuados:
```bash
sudo mkdir -p /openstack/log/ansible-logging
sudo touch /openstack/log/ansible-logging/ansible.log
sudo chmod 666 /openstack/log/ansible-logging/ansible.log
```

Y los permisos del directorio de cache:
```bash
sudo chmod -R 755 /etc/openstack_deploy/ansible_facts
```

> 📂 Las dependencias necesarias (como `lxc`) deben instalarse en los nodos destino, como `controller`. En el nodo `controller` ejecuta:
```bash
sudo apt update && sudo apt install -y lxc jq
```

---

## 🔠 4. Validación de contenedores creados

> 🔗 **Importante**: los contenedores LXC serán visibles en los nodos como `controller`, **no en `bastion`**.

Lista contenedores LXC:
```bash
sudo lxc-ls -f
```

Ejecuta este comando directamente **en el nodo objetivo** (por ejemplo, en `controller`, accediendo vía `vagrant ssh controller`).

Resultado esperado (puede variar):
```
NAME                                      STATE   AUTOSTART GROUPS IPV4
controller-repo-container-xxx             RUNNING 1         -      192.168.56.X
controller-keystone-container-xxx         RUNNING 1         -      192.168.56.X
...
```

---

## ✅ 5. Validación con Ansible

Ejecuta:
```bash
ANSIBLE_LOG_PATH=/tmp/ansible.log ansible controller -i /opt/openstack-ansible/inventory/dynamic_inventory.py -m ping
```

Y si quieres validar todos los hosts definidos:
```bash
ansible all -i /opt/openstack-ansible/inventory/dynamic_inventory.py -m ping
```

> ⛰️ Puedes ignorar contenedores que aún no estén listos. Se irán creando en fases posteriores.

---

## 🗆️ Checkpoint final de STAGE-3

- [x] `dynamic_inventory.py --list` devuelve todos los grupos definidos.
- [x] `setup-hosts.yml` se ejecuta correctamente con su ruta `playbooks/setup-hosts.yml`.
- [x] Contenedores LXC son creados en los nodos del inventario.
- [x] El comando `ansible all -m ping` funciona sobre los hosts definidos.
- [x] Los directorios y variables necesarias están definidos para `pki` y `ssh_keypairs`.
- [x] El error `openstack_ssh_keypairs_authorities is undefined` ha sido resuelto con una definición vacía.
- [x] El paquete `lxc` está instalado en los nodos donde se crean los contenedores (ej. `controller`).

---

## 📜 Referencias

- [Inventory configuration](https://docs.openstack.org/openstack-ansible/latest/user/configure.html)
- [setup-hosts.yml](https://docs.openstack.org/openstack-ansible/latest/user/deployment-hosts.html)
- [Working with containers](https://docs.openstack.org/openstack-ansible/latest/admin/container-management.html)

---

> 🗄️ En STAGE-4 se desplegarán los servicios básicos como Keystone, RabbitMQ, Galera y Horizon.

