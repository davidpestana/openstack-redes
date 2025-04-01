# 🚀 STAGE-2: Construcción progresiva del inventario OpenStack-Ansible

Esta etapa construye un archivo `openstack_user_config.yml` funcional **de menos a más**, basado en los templates oficiales de OpenStack-Ansible. Cada paso incorpora una validación progresiva para asegurar que el entorno es consistente antes de continuar.

---

## 🌟 Objetivos

- 🧱 Partir de una configuración mínima viable del inventario.
- ✅ Añadir capas funcionales una a una, validando cada paso.
- 🧪 Identificar errores frecuentes en tiempo real.
- 📚 Conectar con la documentación oficial como referencia.
- 🔍 Validar completamente el estado del nodo `controller` antes de ejecutar playbooks.
- 🧩 Asegurar que todas las herramientas necesarias estén instaladas en bastion.
- 🛡️ Confirmar que todos los nodos están correctamente preparados a nivel de red antes de proceder.

---

## 🔰 1. Estructura mínima viable (`openstack_user_config.yml`)

Inspirado en el archivo oficial:\
🔗 [https://opendev.org/openstack/openstack-ansible/src/branch/master/etc/openstack\_deploy/openstack_user_config.yml.aio](https://opendev.org/openstack/openstack-ansible/src/branch/master/etc/openstack_deploy/openstack_user_config.yml.aio)

```yaml
global_overrides:
  internal_lb_vip_address: 192.168.56.254
  external_lb_vip_address: 192.168.56.254
  tunnel_bridge: br-vxlan
  management_bridge: br-mgmt
  provider_networks:
    - network:
        container_bridge: br-mgmt
        container_type: veth
        container_interface: eth1
        ip_from_q: container
        type: raw
        group_binds:
          - all_containers
          - hosts
        is_management_address: true

cidr_networks:
  container: 192.168.56.0/24
  tunnel: 10.0.0.0/24
  storage: 172.16.0.0/24

used_ips:
  - 192.168.56.1
  - 192.168.56.2

shared-infra_hosts:
  controller:
    ip: 192.168.56.10
```

📌 **IMPORTANTE**:

- Solo se define el host `controller` inicialmente. Más nodos se añadirán en etapas posteriores.
- Para evitar que Ansible intente ejecutar roles no configurados o servicios aún no definidos (como contenedores que aún no existen), **puedes limitar la ejecución de Ansible a grupos o hosts concretos que están definidos**.

🔎 **Descripción de las capas del archivo `openstack_user_config.yml`**:

- `global_overrides`: define variables globales para el despliegue, como IPs del load balancer virtual, bridges utilizados por los contenedores y la configuración de redes de gestión.
- `cidr_networks`: define los rangos de red usados internamente por los distintos tipos de red de OpenStack (contenedores, túneles, almacenamiento).
- `used_ips`: reserva direcciones IP que no deben ser utilizadas por OpenStack Ansible para contenedores o servicios.
- `shared-infra_hosts`: define los nodos físicos del grupo de infraestructura compartida. En esta etapa, únicamente se configura el nodo `controller` con su IP de gestión.

✅ **Estado de red limpio esperado en un nodo tras provisión** (por ejemplo `controller`, sin manipulación):

```bash
ip a
```
Debe mostrar:
- `enp0s8` con `192.168.56.10/24`
- `enp0s9` con `10.0.0.10/24`
- `enp0s10` con `172.16.0.10/24`

```bash
brctl show
```
No mostrará aún `br-mgmt`, `br-vxlan` ni `br-storage` (esto es esperado antes de `setup-hosts.yml`).

👉 Si el nodo presenta errores de red, se puede reponer con:
```bash
vagrant destroy controller -f && vagrant up controller
```

---

## 🔍 2. Validaciones básicas del inventario

### 🧪 Validación de sintaxis YAML

```bash
python3 -c "import yaml; d=yaml.safe_load(open('/etc/openstack_deploy/openstack_user_config.yml')); print(type(d), list(d))"
```

🗵️ Resultado esperado:
```bash
<class 'dict'> ['global_overrides', 'cidr_networks', 'used_ips', 'shared-infra_hosts']
```

### 🧩 Instalación de herramientas necesarias (si no se hizo en STAGE-1)

```bash
sudo apt install -y lxc lxc-utils lxcfs lxc-templates
```

⚠️ **Instalación opcional de `jq` para validaciones JSON**:
```bash
sudo apt install -y jq
```

### 🛠️ Validar que el inventario dinámico reconoce al nodo `controller`

```bash
source /opt/ansible-runtime/bin/activate
python3 /opt/openstack-ansible/inventory/dynamic_inventory.py --list | jq 'to_entries[] | select(.key | test("controller"))'
```

📌 **¿Qué estamos validando?** Que el inventario generado dinámicamente ya contiene información sobre el nodo `controller`.

🧠 **Método:** El script `dynamic_inventory.py` genera una estructura JSON completa, y con `jq` filtramos entradas que contienen la palabra `controller` como clave.

✅ **Resultado esperado:** Deberías ver al menos un grupo llamado `controller-host_containers` con contenedores listados dentro. Esto indica que el inventario dinámico está funcionando y reconoce el nodo controller.

### 🧹 Limpieza de datos de inventarios previos (opcional)

```bash
sudo rm -rf /etc/openstack_deploy/ansible_facts/*
sudo mv /etc/openstack_deploy/conf.d /etc/openstack_deploy/conf.d.back
```

---

## 🧠 3. Validación avanzada del nodo `controller`

### 🔍 Verificar bridges y configuración de red desde `bastion`

```bash
ansible controller -m command -a "brctl show"
ansible controller -m command -a "ip a"
ansible controller -m command -a "ip r"
```

Validar que:

- Existe `br-mgmt` y tiene asignado `192.168.56.10/24`
- Interfaces como `enp0s8`, `enp0s9`, `enp0s10` están unidas a los bridges correctos:
  - `enp0s8` → `br-mgmt`
  - `enp0s9` → `br-vxlan`
  - `enp0s10` → `br-storage`
- Ninguna IP está asignada directamente sobre interfaces físicas como `enp0s8`.

### ⚠️ Si la red no está limpia o hay errores de asignación:

```bash
vagrant destroy controller
vagrant up controller
```

no olvides limpiar la huella en bastion
```bash
ssh-keygen -R controller
```

Y repetir la validación. 

✅ Esto asegura un nodo `controller` con red consistente, lo cual es **crítico** para los playbooks posteriores.

---

## 🧱 4. Preparación opcional de los nodos vía Ansible

Puedes crear un script desde bastion que prepare automáticamente los nodos (`controller`, `network`, `compute`, etc) si necesitas instalar herramientas o limpiar estado previo.

Ejemplo de comando para instalar `bridge-utils` desde bastion:

```bash
ansible all -m apt -a "name=bridge-utils state=present update_cache=true" -b
```

Este tipo de tareas puede incluirse en un playbook llamado `prepare-nodes.yml` que asegure que todos los nodos están listos para el despliegue.

---

## 🔍 5. Exploración del entorno, herramientas y posibilidades

### 🎯 Entorno virtual: `ansible-runtime`

Activar con:
```bash
source /opt/ansible-runtime/bin/activate
```
Te permite ejecutar directamente scripts Python del stack, como el inventario dinámico:
```bash
python3 /opt/openstack-ansible/inventory/dynamic_inventory.py --list | jq
```

### 🎯 Wrapper oficial: `openstack-ansible`

Lanza `ansible-playbook` con todos los parámetros y variables necesarias:
```bash
cd /opt/openstack-ansible/playbooks
openstack-ansible setup-hosts.yml
```

### 🎯 Uso de `ansible` o `ansible-playbook` a mano

Si quieres control total:
```bash
ansible controller -i /opt/openstack-ansible/inventory/dynamic_inventory.py -m ping
```
O con playbooks personalizados:
```bash
ansible-playbook -i inventory/dynamic_inventory.py my-playbook.yml -e @/etc/openstack_deploy/user_variables.yml -e @/etc/openstack_deploy/user_secrets.yml
```

✅ Utiliza `openstack-ansible` para simplificar, `ansible-playbook` si necesitas personalización total, y `python3` directamente para debug del inventario.

---

## 📜 Referencias útiles

- [https://docs.openstack.org/openstack-ansible/latest/](https://docs.openstack.org/openstack-ansible/latest/)
- [https://docs.openstack.org/openstack-ansible/latest/user/configure.html](https://docs.openstack.org/openstack-ansible/latest/user/configure.html)
- [https://docs.openstack.org/openstack-ansible/latest/user/deployment-basics.html](https://docs.openstack.org/openstack-ansible/latest/user/deployment-basics.html)
- [https://opendev.org/openstack/openstack-ansible/src/branch/master/etc/openstack\_deploy/](https://opendev.org/openstack/openstack-ansible/src/branch/master/etc/openstack_deploy/)

---

> ✅ **Checkpoint superado:** El inventario se genera correctamente, el nodo `controller` responde, y sus interfaces están correctamente configuradas.
>
> ⏩ En STAGE-3 se comenzará la expansión del inventario con nuevos roles (`repo-infra_hosts`, `keystone_hosts`, `compute_hosts`, etc) y su despliegue con `setup-hosts.yml`.

