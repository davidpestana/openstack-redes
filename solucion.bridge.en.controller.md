## Configuración correcta del interfaz de red en OpenStack-Ansible

### Problema:

Al ejecutar `setup-hosts`, el nodo `controller` no asigna correctamente la interfaz de red a la red de virtualización. Como resultado, los contenedores no obtienen IPs y fallan.

### Causa:

El archivo `openstack_user_config.yml` define solo la red de gestión (`br-mgmt`) con tipo `raw`, pero **no hay ninguna red definida como red de virtualización**. Al no existir una red mapeada a una interfaz física activa, **no se crea el bridge** y los contenedores carecen de conectividad.

### Solución:

Modificar la sección `provider_networks` para que defina una red de tipo `flat` con `bridge_mapping`, lo que permite a OpenStack-Ansible crear automáticamente el bridge (`br-vxlan`) y asociarlo a la interfaz física real (`enp0s8` en este caso).

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
        container_interface: enp0s8
        bridge_mapping: "br-vxlan:enp0s8"
        ip_from_q: container
        type: flat
        group_binds:
          - all_containers
          - hosts

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

- Que la interfaz física indicada (`enp0s8`) **existe y está levantada**.
- Que está conectada a la red `192.168.56.0/24`.

Con esta configuración, `setup-hosts.yml`:
- Crea automáticamente el bridge `br-vxlan`.
- Lo enlaza a `enp0s8`.
- Asigna IPs a los contenedores sin intervención manual.

Este enfoque permite un despliegue 100% automático y reproducible del nodo `controller` en entornos didácticos o de laboratorio.

