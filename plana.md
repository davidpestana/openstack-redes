# 🧭 Plan de Stages: OpenStack Ansible Deployment

---

### 🔹 STAGE-0: Preparación del entorno `bastion`

- Crear nodo bastion con Ansible, Python, Git y herramientas base.
- Clonar `openstack-ansible`.
- Ejecutar `scripts/bootstrap-ansible.sh`.
- Configurar `/etc/hosts` con los nodos internos (`controller`, `compute`, etc).
- Validar conexión SSH a cada nodo con llaves.

---

### 🔹 STAGE-1: Definición del inventario y configuración de red

- Configurar `openstack_user_config.yml` con nodos y redes:
  - management, provider, overlay, storage
- Configurar bridges en cada nodo (`/etc/network/interfaces` o Netplan).
- Validar conectividad entre nodos y correcta IP en cada red.

---

### 🔹 STAGE-2: Validaciones de red y bridges

- Ejecutar playbook de red: `openstack-ansible setup-hosts.yml` hasta validaciones.
- En `controller`, validar:
  - Bridges correctamente enlazados (`br-mgmt`, `br-vlan`, `br-storage`, etc).
  - Conectividad L2 entre nodos y red pública.

---

### 🔹 STAGE-3: Preparación de hosts y despliegue de contenedores LXC

- Ejecutar:
  ```bash
  openstack-ansible playbooks/setup-hosts.yml
  ```
- Verificar en `controller`:
  ```bash
  sudo lxc-ls -f
  ```
  Deben aparecer contenedores como `controller-galera-container-*`, etc.
- Revisar inventario dinámico para grupos:
  - `lxc_hosts`, `infra_hosts`, `shared-infra_hosts`

---

### 🔹 STAGE-4: Despliegue de servicios base

- Ejecutar:
  ```bash
  openstack-ansible playbooks/setup-infrastructure.yml
  openstack-ansible playbooks/setup-openstack.yml
  ```
- Verificar:
  - Keystone funcionando: `openstack project list`
  - Horizon accesible en navegador
  - Contenedores de servicios en `controller`

---

### 🔹 STAGE-5: Servicios de red y almacenamiento

- Activar Neutron, Cinder (y opcionalmente Swift o Ceph).
- Ejecutar:
  ```bash
  openstack-ansible playbooks/setup-neutron.yml
  openstack-ansible playbooks/setup-cinder.yml
  ```
- Validar:
  - Agentes de Neutron (`neutron agent-list`)
  - Disponibilidad de volúmenes (`cinder service-list`)

---

### 🔹 STAGE-6: Validación funcional de OpenStack

- Crear red pública y privada.
- Crear instancia desde Horizon o CLI.
- Asociar IP flotante.
- Validar conectividad y SSH.
- Probar asignación de volúmenes.

---

### 🔹 STAGE-7 (opcional): Seguridad y observabilidad

- Configurar SSL/TLS en servicios.
- Configurar Prometheus, Grafana, o herramientas externas.
- Activar Firewall-as-a-Service (FWaaS) o VPNaaS si aplica.
- Backup de estado de OpenStack.