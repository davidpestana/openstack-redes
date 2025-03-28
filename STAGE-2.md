# 🚀 STAGE-2: Construcción progresiva del inventario OpenStack-Ansible

Esta etapa construye un archivo `openstack_user_config.yml` funcional **de menos a más**, basado en los templates oficiales de OpenStack-Ansible. Cada paso incorpora una validación progresiva para asegurar que el entorno es consistente antes de continuar.

---

## 🌟 Objetivos

- 🧱 Partir de una configuración mínima viable del inventario.
- ✅ Añadir capas funcionales una a una, validando cada paso.
- 🧪 Identificar errores frecuentes en tiempo real.
- 📚 Conectar con la documentación oficial como referencia.

---

## 🔰 1. Estructura mínima viable (`openstack_user_config.yml`)

Inspirado en el archivo oficial:\
🔗 [https://opendev.org/openstack/openstack-ansible/src/branch/master/etc/openstack\_deploy/openstack\_user\_config.yml.aio](https://opendev.org/openstack/openstack-ansible/src/branch/master/etc/openstack_deploy/openstack_user_config.yml.aio)

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

Ejemplo para ejecutar pings solo sobre el host físico:

```bash
ansible controller -i /opt/openstack-ansible/inventory/dynamic_inventory.py -m ping
```

Ejemplo de validación de todos los hosts definidos:

```bash
ansible all -i /opt/openstack-ansible/inventory/dynamic_inventory.py -m ping
```

Ejemplo para listar solo los grupos que tienen hosts definidos:

```bash
python3 /opt/openstack-ansible/inventory/dynamic_inventory.py --list | \
  jq 'to_entries[] | select(.value.hosts != []) | .key'
```

Esto ayuda a evitar errores como `lxc-attach: command not found` sobre contenedores aún no desplegados.

---

## 🔍 2. Validación de sintaxis YAML

```bash
python3 -c "import yaml; d=yaml.safe_load(open('/etc/openstack_deploy/openstack_user_config.yml')); print(type(d), list(d))"
```

🗵️ Resultado esperado:

```bash
<class 'dict'> ['global_overrides', 'cidr_networks', 'used_ips', 'shared-infra_hosts']
```

---

## ⚙️ 3. Instalación de dependencias necesarias

Si aún no se han instalado:

```bash
sudo /opt/ansible-runtime/bin/pip install -r /opt/openstack-ansible/requirements.txt
```

🧹 Incluye: `netaddr`, `osa_toolkit`, `pyyaml`, entre otros.

---

## 🧪 4. Prueba del inventario dinámico

```bash
source /opt/ansible-runtime/bin/activate
python3 /opt/openstack-ansible/inventory/dynamic_inventory.py --list
```

⚠️ Si aparece un error con `AttributeError: 'str' object has no attribute 'get'`, revisar que `provider_networks` tenga esta forma:

```yaml
provider_networks:
  - network:
      ip_from_q: container
      type: raw
      [...]
```

---

## 🚩 5. Limpieza de posibles conflictos previos

```bash
sudo rm -rf /etc/openstack_deploy/ansible_facts/*
sudo mv /etc/openstack_deploy/conf.d /etc/openstack_deploy/conf.d.back
```

✅ Esto limpia posibles datos de configuraciones rotas anteriores.

---

## 🛠️ 6. Instalación del entorno LXC (requerido)

```bash
sudo apt update && sudo apt install -y lxc lxc-templates lxc-utils lxcfs
```

Esto habilita comandos como `lxc-attach`, usados por Ansible para acceder a los contenedores.

---

## ⚡️ 7. Validación final con Ansible

### ✅ Validación controlada (recomendada)

```bash
ANSIBLE_LOG_PATH=/tmp/ansible.log ansible controller -i /opt/openstack-ansible/inventory/dynamic_inventory.py -m ping
```

- El host `controller` responde `pong`.
- Los contenedores pueden dar error si aún no han sido creados (**esperable**).
- Para evitar esos errores, **limita tus comandos Ansible a grupos o hosts definidos**, o consulta sólo `controller`, como se muestra arriba.

### ✅ Validación completa (experta)

```bash
ANSIBLE_LOG_PATH=/tmp/ansible.log ansible all -i /opt/openstack-ansible/inventory/dynamic_inventory.py -m ping
```

- Esto intentará contactar también con los contenedores.
- Si recibes errores como `lxc-attach: command not found`, **es normal** en esta etapa.
- Puedes usar este comando solo si sabes que los contenedores fueron creados anteriormente.

---

## 📅 8. Corrección de permisos del sistema de cacheo

Para evitar errores como:
```text
error in 'jsonfile' cache, configured path (/etc/openstack_deploy/ansible_facts) does not have necessary permissions (rwx)
```
Ejecuta:

```bash
sudo chmod -R 777 /etc/openstack_deploy/ansible_facts
```

---

## 📜 Referencias útiles

- [https://docs.openstack.org/openstack-ansible/latest/](https://docs.openstack.org/openstack-ansible/latest/)
- [https://docs.openstack.org/openstack-ansible/latest/user/configure.html](https://docs.openstack.org/openstack-ansible/latest/user/configure.html)
- [https://docs.openstack.org/openstack-ansible/latest/user/deployment-basics.html](https://docs.openstack.org/openstack-ansible/latest/user/deployment-basics.html)
- [https://opendev.org/openstack/openstack-ansible/src/branch/master/etc/openstack\_deploy/](https://opendev.org/openstack/openstack-ansible/src/branch/master/etc/openstack_deploy/)

---

> ✅ **Checkpoint superado:** El inventario se genera correctamente, el nodo `controller` responde y las herramientas están listas.
>
> ⏩ En STAGE-3 se comenzará la expansión del inventario con nuevos roles (`repo-infra_hosts`, `keystone_hosts`, `compute_hosts`, etc) y su despliegue con `setup-hosts.yml`.

