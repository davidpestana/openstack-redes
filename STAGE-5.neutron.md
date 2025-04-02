## 🧪 STAGE 5: Despliegue de servicios de red (Neutron)

### 🎯 Objetivo

- Incorporar el nodo `network` al inventario.
- Definir correctamente las tres redes físicas utilizadas:
  - Red de gestión (`br-mgmt`)
  - Red de túneles VXLAN (`br-vxlan`)
  - Red externa `provider` (`br-ex`)
- Declarar cada red en `provider_networks` usando `host_bind_override` para evitar reordenar interfaces.
- Asegurar que cada bridge se asocia a la interfaz física correcta (`ethX`) en cada nodo correspondiente.
- Ejecutar el playbook de Neutron sabiendo que los bridges ya estarán bien mapeados.
- Validar el estado de los agentes y bridges tras el despliegue.

---

### 🧱 Componentes implicados
- Nodo `network`
- Agentes de Neutron:
  - `neutron-openvswitch-agent`
  - `neutron-dhcp-agent`
  - `neutron-l3-agent`
  - `neutron-metadata-agent`
- Open vSwitch (`ovs`)
- Bridges: `br-mgmt`, `br-vxlan`, `br-ex` (provider)

---

### ⚙️ Acciones principales

#### Paso 1: Añadir nodo `network` al inventario
Editar `/etc/openstack_deploy/openstack_user_config.yml`:
```yaml
network_hosts:
  network:
    ip: 192.168.56.12
```
Esto informa a OpenStack-Ansible de que el nodo `network` existe y participará en el despliegue de Neutron.

#### Paso 2: Declarar redes físicas en `provider_networks`
En el archivo `/etc/openstack_deploy/user_variables.yml`, definimos cada red que participará en el despliegue:

##### 🔹 Red de gestión (`br-mgmt`)
Esta red permite la comunicación entre contenedores y servicios internos.

```yaml
- network:
    container_bridge: br-mgmt
    container_type: veth
    container_interface: eth1
    host_bind_override: eth1
    ip_from_q: container
    type: raw
    group_binds:
      - all_containers
      - hosts
    is_management_address: true
```

##### 🔹 Red de túneles VXLAN (`br-vxlan`)
Transporta tráfico de redes privadas entre nodos.

```yaml
- network:
    container_bridge: br-vxlan
    container_type: veth
    container_interface: eth2
    host_bind_override: eth2
    ip_from_q: tunnel
    type: vxlan
    group_binds:
      - neutron_linuxbridge_agent
      - compute_hosts
```

##### 🔹 Red externa `provider` (`br-ex`)
Permite a las VMs acceder a redes externas (Internet, floating IPs).

```yaml
- network:
    container_bridge: br-ex
    container_type: veth
    container_interface: eth3
    host_bind_override: eth3
    ip_from_q: neutron
    type: flat
    group_binds:
      - network_hosts
```

##### 🔸 Resultado final consolidado:
```yaml
provider_networks:
  - network:
      container_bridge: br-mgmt
      container_type: veth
      container_interface: eth1
      host_bind_override: eth1
      ip_from_q: container
      type: raw
      group_binds:
        - all_containers
        - hosts
      is_management_address: true

  - network:
      container_bridge: br-vxlan
      container_type: veth
      container_interface: eth2
      host_bind_override: eth2
      ip_from_q: tunnel
      type: vxlan
      group_binds:
        - neutron_linuxbridge_agent
        - compute_hosts

  - network:
      container_bridge: br-ex
      container_type: veth
      container_interface: eth3
      host_bind_override: eth3
      ip_from_q: neutron
      type: flat
      group_binds:
        - network_hosts
```

---

### ✅ Validaciones clave
- `ovs-vsctl show` en el nodo `network` muestra los bridges esperados.
- `ip netns` lista los namespaces `qrouter-*`, `qdhcp-*`, etc.
- `neutron agent-list` confirma que los agentes están activos.
- El nodo `controller` puede gestionar redes y routers desde Horizon o CLI.

---

### ⚠️ Posibles errores comunes
- El bridge `br-ex` no enlazado a interfaz física.
- Conflictos en `provider_networks`.
- `neutron-metadata-agent` sin conectividad con `nova-api-metadata`.
- Faltan rutas o DNS en los namespaces.


### ✅ Validaciones previas antes de ejecutar Neutron

Ejecutar desde `bastion` o conectándose por SSH a cada nodo:

#### 🔹 Verifica interfaces físicas en todos los nodos:
```bash
ssh <nodo> ip a
```
Asegúrate de que `eth1`, `eth2`, `eth3` existen y están asignadas según el plan.

#### 🔹 Valida conectividad entre nodos por la red de gestión:
```bash
ssh controller ping -c2 network
ssh network ping -c2 compute
```

#### 🔹 Verifica mapeo de bridges:
```bash
ssh network sudo ovs-vsctl show
```
Debe listar `br-mgmt`, `br-vxlan`, `br-ex` enlazados con `ethX`.

#### 🔹 Revisa que cada bridge tiene interfaz activa:
```bash
ssh network ip a show br-mgmt
ssh network ip a show br-vxlan
ssh network ip a show br-ex
```

#### 🔹 Comprueba si el contenedor `repo` es accesible:
```bash
ssh controller curl -I http://192.168.56.254:8181/constraints/upper_constraints_cached.txt
```

#### 🔹 Verifica que el nodo `network` tiene nombre resoluble desde bastion:
```bash
ping -c2 network
```
(Desde bastion)

---

### 🛠️ Aplicar los cambios

Una vez definidas las redes:
1. Asegúrate de que el nodo `network` está en ejecución y accesible por SSH desde `bastion`.
2. Ejecuta desde el nodo `bastion`:
```bash
cd /opt/openstack-ansible/playbooks
openstack-ansible setup-openstack.yml --tags neutron
```

Esto desplegará los servicios de red (Neutron) solo en los nodos definidos para ello.

---

### 🔍 Validaciones tras la ejecución

Desde el nodo `network`:

1. Verifica que los bridges se han creado:
```bash
sudo ovs-vsctl show
```
Debes ver los bridges `br-mgmt`, `br-vxlan`, `br-ex` listados y con sus puertos asociados.

2. Comprueba los namespaces:
```bash
ip netns
```
Deberían aparecer elementos como `qrouter-XXXX`, `qdhcp-XXXX`.

3. Verifica interfaces asociadas:
```bash
ip a show br-ex
ip a show br-vxlan
ip a show br-mgmt
```

Desde el nodo `controller` (o vía Horizon si ya está desplegado):

1. Comprobar el estado de los agentes:
```bash
source /root/openrc  # si no se ha hecho
openstack network agent list
```
Todos los agentes deben aparecer como `alive`.

2. Verificar redes Neutron disponibles:
```bash
openstack network list
```

3. Comprobación desde Horizon:
- Acceder a Horizon: `http://<IP o dominio>`
- Ir a "Redes" > "Redes" y ver si se listan.
- Comprobar agentes desde Admin > System > Network Agents.

---
Si todo es correcto:
- Pasar al STAGE 6: Despliegue de `nova` y servicios de cómputo (`compute`).

