## Configuración correcta del interfaz de red en OpenStack-Ansible

### Problema:
Al ejecutar `setup-hosts`, el nodo `controller` no asigna correctamente la interfaz de red a la red de virtualización. Como resultado, los contenedores no obtienen IPs y fallan.

### Causa:
El archivo `openstack_user_config.yml` no especifica de forma explícita el mapeo entre el bridge de contenedores (`br-mgmt`) y la interfaz física real (`eth1`).

### Solución:
Editar la sección `provider_networks` del archivo `openstack_user_config.yml` para incluir la clave `bridge_mapping`, que especifica qué interfaz física se asocia a qué bridge.

### Ejemplo corregido:
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
        bridge_mapping: "br-mgmt:eth1"

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

compute-hosts: {}
```

### Requisitos en el nodo físico:
Antes de ejecutar `setup-hosts`, asegúrate de:
- Que `eth1` existe y está levantado (`ip link set eth1 up`).
- Que `eth1` está conectado a la red correcta (192.168.56.0/24).

Esto permitirá que el script cree `br-mgmt`, lo vincule con `eth1`, y asigne correctamente las IPs a los contenedores.

