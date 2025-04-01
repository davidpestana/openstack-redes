### 🎯 Objetivo
Crear un **rol de Ansible** llamado `network-bridges` que:
- Cree los bridges `br-mgmt`, `br-vxlan`, y opcionalmente `br-storage` si el nodo lo necesita.
- Conecte la interfaz física correspondiente (`eth1`, `eth2`, etc.) al bridge.
- Establezca IP (solo en `br-mgmt` si el nodo lo necesita).
- Sea **idempotente** y compatible con Ubuntu 22.04 (`netplan` o `systemd-networkd`).

---

### 📁 Estructura de archivos

```
roles/
└── network-bridges/
    ├── tasks/
    │   └── main.yml
    └── templates/
        └── bridge-netplan.yaml.j2
playbooks/
└── configure-bridges.yml
```

---

### 🧠 Variables sugeridas por host (en `host_vars/<hostname>.yml` o en el `inventory`)

```yaml
bridges:
  - name: br-mgmt
    interface: eth1
    ip: 192.168.56.10
    cidr: 24
    gateway: 192.168.56.1
    set_ip: true
  - name: br-vxlan
    interface: eth2
    set_ip: false
  - name: br-storage
    interface: eth3
    ip: 172.16.0.10
    cidr: 24
    set_ip: true
```

---

### 📜 `tasks/main.yml` del rol `network-bridges`

```yaml
- name: Ensure netplan directory exists
  file:
    path: /etc/netplan
    state: directory

- name: Configure bridges via netplan
  template:
    src: bridge-netplan.yaml.j2
    dest: /etc/netplan/01-bridges.yaml
    mode: '0644'

- name: Apply netplan
  command: netplan apply
```

---

### 📄 `templates/bridge-netplan.yaml.j2`

```yaml
network:
  version: 2
  ethernets:
{% for bridge in bridges %}
    {{ bridge.interface }}:
      dhcp4: false
{% endfor %}
  bridges:
{% for bridge in bridges %}
    {{ bridge.name }}:
      interfaces: [{{ bridge.interface }}]
      parameters:
        stp: false
        forward-delay: 0
      dhcp4: false
      {% if bridge.set_ip %}
      addresses:
        - {{ bridge.ip }}/{{ bridge.cidr }}
      gateway4: {{ bridge.gateway | default('') }}
      {% endif %}
{% endfor %}
```

---

### ▶️ `playbooks/configure-bridges.yml`

```yaml
- name: Configurar bridges en los nodos
  hosts: all
  become: true
  roles:
    - network-bridges
```

---

### ✅ Cómo usarlo

1. Coloca las variables específicas por nodo (como `bridges`) en `host_vars/controller.yml`, `host_vars/compute.yml`, etc.
2. Ejecuta el playbook:

```bash
ansible-playbook playbooks/configure-bridges.yml -i inventory/openstack
```

Perfecto, aquí tienes los archivos `host_vars` adaptados a tu entorno actual, basado en el Vagrantfile y en tu configuración de OpenStack-Ansible.

---

### 📁 `host_vars/controller.yml`

```yaml
bridges:
  - name: br-mgmt
    interface: eth1
    ip: 192.168.56.10
    cidr: 24
    gateway: 192.168.56.1
    set_ip: true

  - name: br-vxlan
    interface: eth2
    set_ip: false

  - name: br-storage
    interface: eth3
    ip: 172.16.0.10
    cidr: 24
    set_ip: true
```

---

### 📁 `host_vars/compute.yml`

```yaml
bridges:
  - name: br-mgmt
    interface: eth1
    ip: 192.168.56.11
    cidr: 24
    gateway: 192.168.56.1
    set_ip: true

  - name: br-vxlan
    interface: eth2
    set_ip: false
```

---

### 📁 `host_vars/network.yml`

```yaml
bridges:
  - name: br-mgmt
    interface: eth1
    ip: 192.168.56.12
    cidr: 24
    gateway: 192.168.56.1
    set_ip: true

  - name: br-vxlan
    interface: eth2
    set_ip: false

  - name: br-storage
    interface: eth3
    ip: 172.16.0.12
    cidr: 24
    set_ip: true
```

---

### 📁 `host_vars/storage.yml`

```yaml
bridges:
  - name: br-mgmt
    interface: eth1
    ip: 192.168.56.13
    cidr: 24
    gateway: 192.168.56.1
    set_ip: true

  - name: br-storage
    interface: eth2
    ip: 172.16.0.13
    cidr: 24
    set_ip: true
```

---

> 💡 Nota:
> Si estás usando `eth0` para NAT (sólo en el nodo `bastion` o `network`), no lo toques en este rol.
> Este rol **solo configura los bridges y sus interfaces asociadas**, y deja el resto del sistema intacto.