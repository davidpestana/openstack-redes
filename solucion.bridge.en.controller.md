## Configuración correcta del interfaz de red en OpenStack-Ansible

### Problema:
Al ejecutar `setup-hosts`, el nodo `controller` no asigna correctamente la interfaz de red a la red de virtualización. Como resultado, los contenedores no obtienen IPs y fallan.

### Causa:
El archivo `openstack_user_config.yml` no especifica de forma explícita el mapeo entre el bridge de contenedores (`br-vxlan`) y la interfaz física real (`eth2`), que se usará como red de virtualización.

### Solución:
Editar la sección `provider_networks` del archivo `openstack_user_config.yml` para incluir una única red con `bridge_mapping`, que vincule `br-vxlan` con la interfaz física deseada (`eth2`).

**Nota:** Si en ejecuciones anteriores se definieron otras redes o grupos de hosts, eliminar el archivo `/etc/openstack_deploy/openstack_inventory.json` y regenerar el inventario puede ser necesario para evitar errores por configuración antigua.

### Ejemplo corregido:
```yaml
global_overrides:
  internal_lb_vip_address: 192.168.56.254
  external_lb_vip_address: 192.168.56.254
  tunnel_bridge: br-vxlan
  management_bridge: br-mgmt
  provider_networks:
    - network:
        container_bridge: br-vxlan
        container_type: veth
        container_interface: eth2
        ip_from_q: container
        type: raw
        group_binds:
          - all_containers
          - hosts
        bridge_mapping: "br-vxlan:eth2"

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

### Requisitos en el nodo físico:
Antes de ejecutar `setup-hosts`, asegúrate de:
- Que `eth2` existe y está levantado (`ip link set eth2 up`).
- Que `eth2` está conectado a la red correcta (192.168.56.0/24 o la que se use para virtualización).

Esto permitirá que el script cree `br-vxlan`, lo vincule con `eth2`, y asigne correctamente las IPs a los contenedores.

