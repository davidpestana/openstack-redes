# 🚀 STAGE-4: Despliegue de Servicios Base

En este stage desplegamos la infraestructura central de OpenStack sobre los contenedores ya creados en `STAGE-3`. Esto incluye la base de datos Galera, la cola de mensajes RabbitMQ, el servicio de identidad Keystone, Horizon (dashboard web) y servicios auxiliares.

---

## ✨ Objetivos

- ⚖️ Desplegar servicios de infraestructura: Galera, RabbitMQ, Memcached
- ⛏️ Desplegar servicios de autenticación: Keystone
- 📊 Desplegar Horizon (interfaz web)
- ✅ Validar servicios activos y contenedores funcionales

---

## 📂 1. Requisitos previos

### ✉️ 1.1. Asegura que los contenedores estén creados:

Desde el nodo `controller`:

```bash
sudo /usr/bin/lxc-ls -f
```

Debe devolver al menos contenedores como:

```
controller-rabbit-mq-container-xxx
controller-galera-container-xxx
controller-keystone-container-xxx
controller-utility-container-xxx
```

> Si están vacíos, revisa que `setup-hosts.yml` se ejecutó correctamente (ver STAGE-3).

### 🔎 1.2. Revisa el inventario:

```bash
python3 /opt/openstack-ansible/inventory/dynamic_inventory.py --list | jq 'keys'
```

Asegúrate de que existen:

- `shared-infra_hosts`
- `keystone_hosts`
- `repo-infra_hosts`
- `os-infra_hosts`

> Si `os-infra_hosts` aparece como vacío (`hosts: []`), el sistema no está generando correctamente ese grupo desde `infra_hosts`, lo cual impide la creación de contenedores.

### ⚠️ 1.3. Validación clave: revisión precisa del inventario

> La causa del problema puede residir en un typo: `lcx_hosts` en lugar de `lxc_hosts` dentro de `group_binds`. Verifica y corrige esta línea en `openstack_user_config.yml`.

#### ✅ Ejemplo correcto:

```yaml
provider_networks:
  - network:
      container_bridge: "br-mgmt"
      container_type: "veth"
      container_interface: "eth1"
      ip_from_q: "container"
      type: "raw"
      group_binds:
        - all_containers
        - hosts
        - lxc_hosts  # ❗ NO debe estar mal escrito como "lcx_hosts"
      is_management_address: true
```

> Si `lxc_hosts` está mal escrito, el inventario dinámico no generará correctamente los grupos necesarios, y ningún contenedor será creado en `controller`.

### 🔄 1.4. Regenerar inventario tras corregir

```bash
cd /opt/openstack-ansible
scripts/inventory-manage.py --export > /tmp/inv.json
scripts/inventory-manage.py --clear-ips
```

Luego:

```bash
openstack-ansible playbooks/setup-hosts.yml
```

> Esta ejecución debería desplegar los contenedores esperados en `controller`. Verifica en ese nodo:

```bash
sudo /usr/bin/lxc-ls -f
```

---

## 📂 2. Ejecución de playbooks principales

### 2.1 setup-infrastructure.yml

Despliega RabbitMQ, Galera, Memcached y servicios comunes:

```bash
cd /opt/openstack-ansible
openstack-ansible playbooks/setup-infrastructure.yml
```

> ⚠️ Revisa los `warnings`. Si aparecen mensajes como `no hosts matched`, es síntoma de inventario mal generado.

### 2.2 setup-openstack.yml

Despliega Keystone, Horizon y servicios base:

```bash
# Evita errores de integración con Ceph si no se despliega:
echo 'ceph_rgws: []' >> /etc/openstack_deploy/user_variables.yml
openstack-ansible playbooks/setup-openstack.yml
```

> Si aparecen errores como `openrc_os_password undefined`, asegúrate de tener esa variable definida en `user_secrets.yml`.

---

## 🔎 2.3 Verificación post-playbooks

Antes de validar servicios, comprueba que los contenedores han sido creados correctamente. En el nodo `controller`, ejecuta:

```bash
sudo /usr/bin/lxc-ls -f
```

Deberías ver al menos:

- `controller-galera-container-*`
- `controller-rabbit-mq-container-*`
- `controller-keystone-container-*`
- `controller-horizon-container-*`

> ⚠️ Si no aparecen contenedores, revisa cuidadosamente `openstack_user_config.yml`, los grupos `lxc_hosts`, y `group_binds`.

---

## 📊 3. Validación de servicios

### 3.1 Contenedores en `controller`

En `controller`, verifica:

```bash
sudo /usr/bin/lxc-ls -f
```

Debes ver contenedores ejecutándose (`RUNNING`) como:

- galera
- rabbitmq
- keystone
- horizon

### 3.2 Comprobación de Keystone:

Desde `bastion`:

```bash
source /opt/ansible-runtime/bin/activate
source /etc/openstack_deploy/openrc
openstack project list
```

Debe devolver el proyecto `admin`.

> Si el archivo `openrc` no existe o el comando `openstack` no está instalado, es señal de que Keystone aún no se ha desplegado correctamente.

### 3.3 Acceso a Horizon:

Abre en el navegador:

```
http://192.168.56.10/horizon
```

Credenciales:

- Usuario: `admin`
- Contraseña: (extraer de `/etc/openstack_deploy/user_secrets.yml`)

> Si la pantalla queda en negro o cargando, comprueba si el contenedor de Horizon existe y está activo.

---

## 📌 4. Validación final STAGE-4

- Inventario dinámico muestra los grupos esperados
- Contenedores corriendo en el nodo `controller`
- Keystone funcional
- Acceso al panel Horizon

---

## 📓 Referencias

- [setup-infrastructure.yml](https://docs.openstack.org/openstack-ansible/latest/user/deployment-infrastructure.html)
- [setup-openstack.yml](https://docs.openstack.org/openstack-ansible/latest/user/deployment-openstack.html)
- [Verificación de servicios](https://docs.openstack.org/openstack-ansible/latest/admin/service-verification.html)
- [Deployment Host (Docs)](https://docs.openstack.org/project-deploy-guide/openstack-ansible/latest/deploymenthost.html)
- [Provider Network Definitions](https://docs.openstack.org/openstack-ansible/latest/user/network/example.html#provider-network-definitions)

---

> En STAGE-5 se desplegará la capa de red (Neutron) y almacenamiento (Cinder).

