# 🚀 STAGE-3: Expansión del Inventario y Ejecución de los primeros playbooks

En esta etapa se amplía el inventario para incluir nuevos nodos y contenedores, y se inicia la ejecución efectiva de los playbooks de OpenStack-Ansible. Esta fase da comienzo al proceso de instalación de paquetes, configuración de contenedores y preparación de los nodos según el inventario definido.

---

## ✨ Objetivos

- 🧱 Ampliar el inventario con nuevos grupos: `repo-infra_hosts`, `keystone_hosts`, `compute_hosts`, `infra_hosts`...
- ⚙️ Ejecutar `setup-hosts.yml` para configurar los hosts y bridges necesarios.
- 🚧 Crear contenedores LXC en el nodo `controller`.
- 🔍 Validar que los bridges de red y contenedores han sido creados correctamente.
- 📒 Observar logs y gestionar errores frecuentes durante la ejecución.
- 🧪 Introducir validaciones previas antes de ampliar completamente el inventario, para aislar errores tempranos.

---

## 📂 1. Inventario Mínimo Inicial

Antes de desplegar todos los servicios, es conveniente comenzar con una versión mínima de inventario que incluya solo `shared-infra_hosts` y un único nodo (`controller`).

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

## 🧪 5. Validaciones si los contenedores LXC fallan al arrancar

Si obtienes errores del tipo:
```
lxc-start: Received container state "ABORTING" instead of "RUNNING"
lxc-attach: Failed to get init pid / attach context
```
Sigue estos pasos en el nodo `controller`:

### Verifica que los módulos del kernel están cargados
```bash
lsmod | grep -E 'veth|bridge|overlay|cgroup'
```
Si faltan:
```bash
sudo modprobe veth
sudo modprobe bridge
sudo modprobe overlay
```

### Asegura que los servicios LXC están activos
```bash
sudo systemctl enable --now lxc
sudo systemctl enable --now lxc-net
```

### Arregla los bridges manualmente si `setup-hosts` falló parcialmente
Si el primer `setup-hosts.yml` se interrumpió, es **posible que los bridges de red como `br-mgmt` no se hayan creado correctamente**. Verifica con:
```bash
brctl show
```
Si faltan, reejecuta `setup-hosts.yml` tras asegurarte de que los dispositivos de red están en buen estado o crea los bridges manualmente según el inventario.

### Consulta logs de error
```bash
sudo cat /var/log/lxc/lxc-controller-*.log
journalctl -xe | grep lxc
```

---

## 📦 6. Ampliación del inventario (`openstack_user_config.yml`)

La necesidad de esta ampliación fue identificada a partir del error:
```
FAILED! => {... "url": "http://192.168.56.254:8181/constraints/upper_constraints_cached.txt"}
```
que indicaba la ausencia del contenedor `repo`. Esto llevó a concluir que debían definirse los grupos mínimos adicionales necesarios para el despliegue básico.

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

🔎 **¿Por qué se añaden estos grupos?**

Cada grupo de inventario indica a OpenStack-Ansible qué servicios desplegar y dónde:

- `repo-infra_hosts`: indica que se debe crear un contenedor `repo` para alojar paquetes y constraints internos.
- `keystone_hosts`: habilita la creación del contenedor Keystone, responsable del servicio de identidad.
- `infra_hosts`: agrupa servicios de infraestructura como RabbitMQ, Galera y Memcached.
- `compute_hosts`: donde se desplegarán los servicios de cómputo (nova-compute, libvirt...).

⚠️ Si un grupo necesario no está presente o vacío, los playbooks correspondientes omitirán pasos o fallarán por falta de destino.

---

## 🔍 7. Validación y ejecución tras ampliar inventario

Tras añadir nuevos grupos, es necesario **repetir**:

```bash
openstack-ansible setup-hosts.yml
openstack-ansible setup-infrastructure.yml
```

Esto permite:
- Crear contenedores para los nuevos servicios.
- Reparar configuraciones previas si se ejecutaron parcialmente.

📊 Nota: En la primera ejecución de `setup-hosts.yml`, si el nodo `compute` está en el inventario pero no ha sido preparado (sin bridges de red, sin dependencias), fallará. Prepara la red antes o ejecuta con `--limit controller` si es necesario.

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

## ⚠️ Problemas comunes y soluciones

### 1. Contenedor no creado / error LXC
- Falta instalación de `lxc` en `controller`
```bash
sudo apt install -y lxc
```

### 2. Inventario vacío o erróneo
- Sintaxis YAML incorrecta
- El grupo no tiene nodos definidos

### 3. Permisos de logs o facts
```bash
sudo chmod -R 755 /etc/openstack_deploy/ansible_facts
sudo mkdir -p /openstack/log/ansible-logging
sudo chmod -R 777 /openstack/log
```

### 4. Clave SSH desincronizada tras `vagrant destroy`
```bash
ssh-keygen -f "/home/vagrant/.ssh/known_hosts" -R "controller"
```

---

## ✅ Conclusión

Al finalizar esta etapa:
- El inventario ha sido validado por fases.
- El nodo `controller` está correctamente preparado.
- Se han generado los primeros contenedores LXC.
- Los logs y puentes de red están verificados.
- Se ha aprendido a **resolver fallos de red tras crashes**.
- Se ha definido el conjunto mínimo de grupos para permitir el despliegue de los servicios base.
- Se ha establecido el flujo de idempotencia: editar inventario y repetir `setup-hosts.yml` y `setup-infrastructure.yml`.
- Se reconfirma que no se deben lanzar contenedores manualmente con `lxc-start -F`.

👈 En `STAGE-4` se desplegarán los servicios base (Galera, RabbitMQ, Keystone...).

