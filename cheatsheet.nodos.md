# 🗒️ **OpenStack-Ansible Cheat Sheet**

Esta guía incluye nodos, componentes, contenedores y procesos clave de OpenStack-Ansible (OSA), con explicaciones precisas y breves:

---

## 🖥️ **Bastion (Deployment Host)**

Nodo central desde donde se gestionan los despliegues con Ansible.

### Componentes Principales:
- **Ansible**: *[Motor de automatización para ejecutar configuraciones en otros nodos vía SSH.]*
- **Dynamic Inventory**: *[Inventario generado automáticamente para conocer el estado actual de todos los hosts y contenedores.]*
- **Playbooks**: *[Scripts YAML ejecutados por Ansible para configurar OpenStack.]*
- **openstack-ansible CLI**: *[Herramienta para ejecutar playbooks específicos de OSA.]*

---

## 🎛️ **Controller Node**

Proporciona servicios centrales de OpenStack.

### Componentes Principales:
- **Keystone**: *[Autenticación y autorización.]*
- **Glance**: *[Servicio de almacenamiento y gestión de imágenes.]*
- **Nova API/Scheduler/Conductor**: *[Gestionan y coordinan máquinas virtuales.]*
- **Neutron Server**: *[Gestiona redes virtuales.]*
- **Placement API**: *[Gestiona inventario de recursos de cómputo.]*
- **Horizon**: *[Panel web de gestión.]*
- **RabbitMQ**: *[Broker de mensajes entre servicios.]*
- **MariaDB/Galera Cluster**: *[Base de datos distribuida y tolerante a fallos.]*
- **Memcached**: *[Cacheo para rendimiento de APIs.]*

### Contenedores LXC clave:
- **keystone_container**: *[Contenedor que ejecuta el proceso Keystone (`keystone-wsgi`).]*
- **glance_container**: *[Contenedor del servicio Glance (`glance-api`).]*
- **nova_api_container**: *[Contenedor que ejecuta APIs de Nova (`nova-api`, `nova-scheduler`, `nova-conductor`).]*
- **neutron_server_container**: *[Contenedor del servidor Neutron (`neutron-server`).]*
- **placement_container**: *[Contenedor Placement (`placement-api`).]*
- **horizon_container**: *[Ejecuta Horizon (`apache2/nginx`).]*
- **rabbitmq_container**: *[RabbitMQ (`rabbitmq-server`).]*
- **galera_container**: *[Cluster MariaDB Galera (`mysqld`).]*
- **memcached_container**: *[Servicio Memcached (`memcached`).]*

---

## 🌐 **Network Node**

Nodo dedicado al tráfico y gestión de redes virtuales.

### Componentes Principales:
- **Neutron Agents**:
  - **Open vSwitch (OVS) o LinuxBridge Agent**: *[Conecta redes virtuales a físicas.]*
  - **DHCP Agent**: *[Provee direcciones IP dinámicas.]*
  - **Metadata Agent**: *[Proporciona metadatos e información contextual a instancias.]*
  - **L3 Agent**: *[Encaminamiento, NAT y Floating IPs.]*
- **Open vSwitch/LinuxBridge**: *[Conexión redes virtuales y físicas.]*
- **HAProxy (opcional)**: *[Balanceador de carga para servicios internos.]*

### Contenedores LXC clave:
- **neutron_agents_container**: *[Ejecuta agentes (`neutron-dhcp-agent`, `neutron-metadata-agent`, `neutron-l3-agent`, `neutron-openvswitch-agent` o `neutron-linuxbridge-agent`).]*

---

## 🚀 **Compute Node**

Nodo que ejecuta instancias (máquinas virtuales).

### Componentes Principales:
- **Nova Compute**: *[Gestiona directamente instancias (`nova-compute`).]*
- **Neutron OVS/LinuxBridge Agent**: *[Conecta instancias a redes.]*
- **Libvirt/QEMU-KVM**: *[Gestiona hipervisor para virtualización.]*

### Procesos clave (sin contenedor):
- **nova-compute**: *[Interfaz entre Nova y el hipervisor.]*
- **neutron-openvswitch-agent/neutron-linuxbridge-agent**: *[Implementación local de red virtual.]*
- **libvirtd**: *[Daemon para administrar el hipervisor (KVM/QEMU).]*

> **Nota**: Nova Compute corre directamente en el host (no en LXC).

---

## 📦 **Storage Node**

Proporciona almacenamiento persistente (bloques u objetos).

### Componentes Principales:
- **Cinder Volume**: *[Servicio de bloques para instancias.]*
- **Swift Proxy/Storage (opcional)**: *[Almacenamiento distribuido de objetos.]*
- **Ceph (opcional)**: *[Sistema distribuido de almacenamiento robusto para bloques y objetos.]*

### Contenedores LXC clave:
- **cinder_volume_container**: *[Ejecuta servicio `cinder-volume`.]*
- **swift_proxy_container**: *[Servicio proxy Swift (`swift-proxy-server`).]*
- **swift_storage_container**: *[Almacenamiento físico de objetos (`swift-object-server`).]*

---

## 🧰 **Utility Container**

Contenedor especial presente en el nodo Controller para tareas operativas.

### Descripción y función:
- **utility_container**: *[Contenedor de propósito general para ejecutar comandos administrativos frecuentes como CLI de OpenStack, backups de base de datos, pruebas funcionales, y tareas manuales de mantenimiento.]*
  - Incluye utilidades como clientes OpenStack (`openstack CLI`), herramientas de base de datos (`mysql-client`), Python SDK, scripts específicos del proyecto, etc.
  - No ejecuta servicios críticos de producción; está diseñado para tareas administrativas rutinarias.

---

## 📌 **Monitoring/Logging Node (opcional)**

Centraliza logs y métricas para facilitar monitoreo.

### Componentes Principales:
- **ELK Stack**:
  - **Elasticsearch**: *[Base de datos para logs.]*
  - **Logstash**: *[Procesa y envía logs.]*
  - **Kibana**: *[Visualización y análisis de logs.]*
- **Prometheus/Grafana**:
  - **Prometheus**: *[Recolecta métricas.]*
  - **Grafana**: *[Dashboard para métricas visuales.]*

### Contenedores LXC clave:
- **elasticsearch_container**: *[Almacena logs indexados.]*
- **logstash_container**: *[Agrega y procesa logs.]*
- **kibana_container**: *[Visualiza logs.]*
- **prometheus_container**: *[Almacenamiento y consultas de métricas.]*
- **grafana_container**: *[Visualiza métricas.]*
  
---

## 📑 **Dependencias Clave destacadas por roles OSA:**

- **keystone →** Galera, Memcached
- **glance →** Keystone, Galera
- **nova →** Keystone, RabbitMQ, Placement, Galera
- **neutron →** Keystone, RabbitMQ, Galera
- **placement →** Keystone, Galera
- **horizon →** Keystone, Memcached
- **cinder →** Keystone, RabbitMQ, Galera
- **swift →** Keystone, Memcached
- **utility_container →** Keystone, Galera (clientes DB/API), dependencias Python (openstacksdk)

---

🛠️ **Comandos útiles rápidos:**

- Ejecutar un playbook específico:
```shell
openstack-ansible setup-openstack.yml
```

- Conectarse al contenedor Utility:
```shell
lxc-attach -n utility_container
```

- Ejecutar comandos OpenStack desde Utility:
```shell
openstack server list
```