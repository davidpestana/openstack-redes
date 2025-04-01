# 🚀 STAGE-3: Expansión del Inventario y Ejecución de los primeros playbooks

En esta etapa se amplía el inventario para incluir nuevos nodos y contenedores, y se inicia la ejecución efectiva de los playbooks de OpenStack-Ansible. Esta fase da comienzo al proceso de instalación de paquetes, configuración de contenedores y preparación de los nodos según el inventario definido.

---

## ✨ Objetivos

- 🧱 Ampliar el inventario con nuevos grupos: `repo-infra_hosts`, `keystone_hosts`, `compute_hosts`, `infra_hosts`...
- ⚙️ Ejecutar `setup-hosts.yml` para configurar los hosts y bridges necesarios.
- 🚧 Crear contenedores LXC en el nodo `controller`.
- 🔍 Validar que los bridges de red y contenedores han sido creados correctamente.
- ⚙️ Desplegar HAProxy tempranamente para evitar problemas de conectividad al repositorio interno.
- 📒 Observar logs y gestionar errores frecuentes durante la ejecución.
- 🧪 Introducir validaciones previas antes de ampliar completamente el inventario, para aislar errores tempranos.

---

## 📂 1. Inventario Mínimo Inicial

Antes de desplegar todos los servicios, comienza con una versión mínima de inventario que incluya solo `shared-infra_hosts` y un único nodo (`controller`).

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

Valida con:
```bash
python3 /opt/openstack-ansible/inventory/dynamic_inventory.py --list | jq 'keys'
```

✅ Esto permite validar la ejecución de `setup-hosts.yml` sin errores de grupos vacíos.

---

## ⚖️ 2. Activar entorno Ansible

Antes de ejecutar cualquier playbook:
```bash
source /opt/ansible-runtime/bin/activate
```

---

## 🟡 3. Ejecutar playbook con inventario mínimo

```bash
cd /opt/openstack-ansible/playbooks
openstack-ansible setup-hosts.yml
```

🔍 Observa que:
- Se creen directorios PKI.
- Se generen claves SSH.
- El nodo `controller` sea accesible vía Ansible.

---

## 📈 4. Validaciones post `setup-hosts.yml`

### Verificación de bridges en `controller`
```bash
ansible controller -m command -a "brctl show"
```

### Verificación de contenedores LXC
```bash
ansible controller -m command -a "lxc-ls -f"
```

### Inventario resultante (resumen con IPs)
```bash
python3 /opt/openstack-ansible/inventory/dynamic_inventory.py --list | \
  jq 'to_entries[] | select(.value.ip != null) | {host: .key, ip: .value.ip}'
```

📌 Si no aparece nada, algo falló en la ejecución anterior.

---

## 🛠️ 5. Activación temprana de HAProxy (solución a problemas de red hacia repositorio)

Al detectar problemas con la IP del repositorio (`192.168.56.254`), activa explícitamente HAProxy en este punto para solucionar definitivamente el problema:

```bash
cd /opt/openstack-ansible/playbooks
openstack-ansible haproxy-install.yml
```

✅ Verifica la activación del VIP:
```bash
curl http://192.168.56.254:8181/constraints/upper_constraints_cached.txt
```

Debe responder correctamente, indicando que HAProxy ya está operativo.

---

## 📦 6. Ampliación del inventario (`openstack_user_config.yml`)

Tras validar la infraestructura mínima y HAProxy, amplía claramente el inventario con nuevos grupos necesarios:

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

🔎 Cada grupo indica los servicios y contenedores que serán desplegados en cada nodo.

---

## 🔍 7. Validación y ejecución tras ampliar inventario

Tras añadir nuevos grupos, ejecuta nuevamente los playbooks necesarios:

```bash
openstack-ansible setup-hosts.yml
openstack-ansible setup-infrastructure.yml
```

Esto:
- Crea los nuevos contenedores.
- Configura servicios internos.
- Prepara infraestructura para OpenStack.

📊 Nota: Asegúrate que el nodo `compute` esté correctamente preparado antes de lanzar estos pasos para evitar errores.

---

## 🔎 8. Exploración y troubleshooting post-playbook

- Verifica bridges:
```bash
ansible controller -m command -a "ip link show type bridge"
```
- Revisa logs:
```bash
cat /openstack/log/ansible-logging/ansible.log
```
- Lista contenedores con:
```bash
ssh controller
sudo lxc-ls -f
```

---

## ✅ Conclusión

Al finalizar esta etapa:
- El inventario está validado por fases.
- HAProxy está activo tempranamente, resolviendo problemas de red.
- El nodo `controller` y sus contenedores están correctamente preparados.
- Logs, contenedores y puentes de red verificados.
- El despliegue queda listo para ejecutar servicios base (Galera, RabbitMQ, Keystone...) en `STAGE-4`.

