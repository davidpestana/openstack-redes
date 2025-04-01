## 🔧 STAGE-BASTION-ROLES: Habilitación del acceso root desde bastion y preparación auxiliar

Esta etapa busca garantizar que los nodos nuevos (como `compute`, `network`, etc.) estén completamente accesibles vía SSH desde `bastion`, incluso como `root`, para evitar fallos por clave pública denegada en el despliegue de Ansible.

### 🎯 Objetivos
- Incluir una **role** reutilizable desde bastion para insertar la clave pública directamente en `/root/.ssh/authorized_keys` de los nodos.
- Añadir un mecanismo alternativo y **manual** (script host-side) que permita reinyectar claves desde el host anfitrión.

---

### 📁 Estructura de la nueva role en bastion

Dar permisos al usuario vagrant para editar el entorno ansible (solo en laboratorios controlados)
```bash
sudo chown -R 1000:1000 /etc/ansible
```
```bash
/etc/ansible/roles/ssh_root_key/
├── tasks/
│   └── main.yml
```

**Contenido `main.yml`:**
```yaml
- name: Asegurar que el directorio .ssh de root existe
  file:
    path: /root/.ssh
    state: directory
    owner: root
    group: root
    mode: '0700'

- name: Leer clave pública desde usuario vagrant
  slurp:
    src: /home/vagrant/.ssh/authorized_keys
  register: vagrant_auth_keys    

- name: Añadir clave pública al root si no existe
  lineinfile:
    path: /root/.ssh/authorized_keys
    line: "{{ vagrant_auth_keys.content | b64decode | regex_replace('\\n', '') }}"
    create: yes
    owner: root
    group: root
    mode: '0600'
    state: present
```


---

## 📄 Crear el playbook `enable-root-access.yml`

Ubícalo en una ruta como:  
`~/playbooks/enable-root-access.yml`

### Contenido del playbook:

```yaml
---
- name: Habilitar acceso root por SSH desde bastion
  hosts: compute
  become: true
  roles:
    - enable_root_access
```

> ✅ Este playbook asume que el rol `enable_root_access` ya está ubicado en `roles/enable_root_access` y correctamente estructurado.

---

### ✅ Ejecución:

```bash
cd ~/playbooks
ansible-playbook -i inventory.ini enable-root-access.yml
```

> Asegúrate de que `inventory.ini` contenga la IP de `compute` y esté accesible como `root` vía clave desde bastion.

¿Quieres que te genere también un `inventory.ini` mínimo para esto por si no usas el dinámico?


> ⚠️ Ejecutar con:  
```bash
ansible-playbook -i inventory.ini playbooks/enable-root-access.yml
```

---

### 🛠️ Script auxiliar: `prepare_node.sh` (para anfitrión)

```bash
#!/bin/bash
NODE="$1"
echo "==> Inyectando clave pública al usuario root en $NODE"
vagrant ssh "$NODE" -c "sudo mkdir -p /root/.ssh && sudo bash -c 'cat /vagrant/id_rsa.pub >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys'"
echo "==> Nodo $NODE preparado para acceso root por SSH desde bastion"
```

> 📦 Este script debe vivir en el directorio del host donde está el `Vagrantfile`, y se invoca así:

```bash
./prepare_node.sh compute
```
