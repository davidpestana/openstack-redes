# 🧭 Plan de Stages: Laboratorio OpenStack-Ansible

---

## ✅ STAGE 0: Preparación del entorno anfitrión

**Descripción:**  
Configura el entorno Linux anfitrión con las herramientas necesarias para crear y gestionar el laboratorio OpenStack usando Vagrant y VirtualBox.

**Objetivos:**

- Instalar herramientas: Vagrant, VirtualBox, Python, Git.
- Clonar repositorio oficial `openstack-ansible`.
- Generar claves SSH para nodos.
- Validar el entorno de red y permisos en el host.

**Validaciones:**

- `vagrant --version`, `virtualbox --help`, `python3 --version`
- Acceso a GitHub y descarga de boxes.
- Red interna configurada correctamente (VirtualBox > Red interna).
- Acceso desde el host a bastion (`vagrant ssh bastion`).

---

## ✅ STAGE 1: Instanciación de nodos base

**Descripción:**  
Se lanza el entorno Vagrant con los nodos que participarán en el despliegue OpenStack: `bastion`, `controller`, `compute`, `network`, `storage`.

**Objetivos:**

- Crear VMs con redes internas: `mgmt`, `data`, `storage`, `provider`.
- Asignar IPs fijas por interfaz según rol.
- Inyectar clave pública desde bastion a cada nodo.

**Validaciones:**

- `vagrant status` muestra nodos en ejecución.
- `ip a` en cada VM muestra interfaces correctas.
- `/etc/hosts` actualizado o resuelto desde bastion.
- Conectividad ping entre nodos.
- `ssh vagrant@<ip>` válido desde bastion.

---

## ✅ STAGE 2: Preparación de `bastion` y OpenStack-Ansible

**Descripción:**  
Configuración del nodo `bastion` para ejecutar OpenStack-Ansible, instalación de dependencias y entorno Python virtual.

**Objetivos:**

- Ejecutar `bootstrap-ansible.sh`
- Activar entorno virtual Python (`/opt/ansible-runtime`)
- Crear estructura `/etc/openstack_deploy`

**Validaciones:**

- `source /opt/ansible-runtime/bin/activate`
- `ansible --version` detecta entorno
- Estructura `/etc/openstack_deploy` creada
- Scripts accesibles en `/opt/openstack-ansible`

---

## ✅ STAGE 3: Inventario mínimo y configuración básica

**Descripción:**  
Se configura un inventario mínimo con `controller` para pruebas iniciales. Se habilita conexión root entre `bastion` y nodos y se ejecuta `setup-hosts.yml`.

**Objetivos:**

- Crear archivo `openstack_user_config.yml` básico.
- Habilitar acceso root desde bastion (rol `ssh_root_key`).
- Ejecutar `setup-hosts.yml --limit controller`
- Añadir nodo `compute` y ejecutarlo por separado.
- Corregir problemas de claves y facts.

**Validaciones:**

- `ansible controller -u root -m ping` y `ansible compute -u root -m ping`
- `setup-hosts.yml` finaliza correctamente.
- Bridges (`br-mgmt`, `br-vxlan`) creados.
- `lxc-ls -f` muestra contenedores solo en controller.
- Inventario dinámico detecta ambos nodos (`dynamic_inventory.py`).

---

## ✅ STAGE 4: Despliegue de infraestructura base

**Descripción:**  
Se despliegan los contenedores base y servicios fundamentales: Galera, RabbitMQ, Memcached, Repo, Utility, HAProxy.

**Objetivos:**

- Corregir variable `repo_server_host` en `user_variables.yml`.
- Ejecutar `setup-hosts.yml` completo para aplicar configuración.
- Ejecutar `setup-infrastructure.yml`.

**Validaciones:**

- Contenedores `*-container-*` corriendo (`lxc-ls -f`)
- `netstat` en controller muestra puertos de servicios abiertos.
- Logs `/var/log` no muestran fallos.
- Ping y curl desde containers hacia `repo_server_host` exitoso.
- `controller-utility-container` puede acceder a `repo` sin errores HTTP 113.

---

## 🧪 STAGE 5: Despliegue de servicios de red (Neutron)

**Descripción:**  
Configuración del nodo `network`, Open vSwitch y servicios de red para OpenStack. Se habilita conectividad entre redes virtuales y externas.

**Objetivos:**

- Añadir `network_hosts` al inventario.
- Configurar variables de red, bridges y namespaces.
- Ejecutar `setup-openstack.yml --tags neutron`

**Validaciones:**

- `ovs-vsctl show` lista bridges correctamente.
- `ip netns` lista namespaces de Neutron.
- DHCP agent y L3 agent activos (`neutron agent-list`).
- Conectividad entre VMs cuando se creen redes.

---

## 🧪 STAGE 6: Despliegue de `nova` y compute

**Descripción:**  
Se despliega el hipervisor en el nodo `compute` con `nova-compute` y se conecta al resto del control plane.

**Objetivos:**

- Habilitar `compute_hosts` en el inventario.
- Ejecutar `setup-openstack.yml --tags nova`
- Validar acceso libvirt, kvm y dispositivos.

**Validaciones:**

- `nova-compute` activo (`systemctl`, `ps`)
- Nodo compute registrado (`openstack compute service list`)
- Puede crear VMs (`nova boot ...`)

---

## 🚀 STAGE 7: Horizon y servicios adicionales

**Descripción:**  
Se despliega el panel web y otros servicios como Heat, Cinder, Swift si se requiere. Se permite interacción visual y pruebas completas.

**Objetivos:**

- Habilitar `horizon`, `heat`, `cinder` en variables.
- Ejecutar `setup-openstack.yml --tags horizon`
- Abrir puerto para acceso web desde el anfitrión.

**Validaciones:**

- Acceso a Horizon en `http://<controller-ip>`
- Login funcional como `admin`.
- Panel muestra servicios activos y nodos disponibles.

---

## 🧪 STAGE 8: Validaciones finales y laboratorio

**Descripción:**  
Última fase para practicar operaciones OpenStack: creación de redes, VMs, volúmenes, floating IPs, etc.

**Objetivos:**

- Crear red privada y router.
- Cargar imagen `cirros` o `ubuntu cloud`.
- Lanzar instancias.
- Conectar con floating IP desde bastion o el host.

**Validaciones:**

- VMs arrancan correctamente.
- Acceso SSH funcional a VMs.
- Consola web (Horizon) operativa.
- Volúmenes adjuntos si Cinder está activo.