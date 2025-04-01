# 🛠️ Guía de Troubleshooting: Problemas de Permisos en Tareas Ansible

---

## 🧩 Contexto General

Cuando una tarea de Ansible falla con errores relacionados con permisos o acceso denegado, lo más común es que el usuario remoto no tenga privilegios adecuados, o que la clave pública no esté bien propagada.

---

## ✅ 1. Leer cuidadosamente el mensaje de error

Ejemplo:
```
"msg": "Destination /etc/haproxy/conf.d not writable"
```

Esto indica que el destino no es accesible para escritura. Requiere acción sobre permisos, privilegios `sudo` o acceso `root`.

---

## 🔍 2. Verificar si la tarea requiere privilegios

Muchos archivos del sistema (`/etc`, `/usr`, `/var`) necesitan `sudo` o `root`.

### ✔ ¿La tarea usa `become: true`?
Asegúrate de que las tareas que lo requieren lo tengan explícito:

```yaml
- name: Crear archivo de configuración
  template:
    src: ...
    dest: /etc/haproxy/conf.d/archivo.cfg
  become: true
```

Y que el `playbook` lo permita a nivel general:
```yaml
- hosts: all
  become: true
```

---

## 🔐 3. Comprobar que el usuario remoto tiene `sudo`

Revisa en el `inventory` o `group_vars`:
```ini
ansible_user=vagrant
ansible_become=true
ansible_become_method=sudo
```

Y prueba desde bastion:
```bash
ssh vagrant@controller
sudo whoami  # Debe devolver "root"
```

Si pide contraseña, o no tiene acceso, puede que requieras configurar `NOPASSWD` en `/etc/sudoers`.

---

## 📁 4. Revisar permisos del directorio/archivo

Desde el nodo afectado:
```bash
ls -ld /etc/haproxy/conf.d
```

Corrige si es necesario:
```bash
sudo mkdir -p /etc/haproxy/conf.d
sudo chown root:root /etc/haproxy/conf.d
sudo chmod 755 /etc/haproxy/conf.d
```

---

## 🐳 5. Si el servicio está en contenedor

Valida con:
```bash
docker ps | grep haproxy
```

Si es así, puede que necesites:
- Usar `delegate_to`.
- Acceder al contenedor internamente.
- Verificar los volúmenes montados.

---

## 🔧 6. STAGE-BASTION-ROLES: Habilitación del acceso root desde bastion y preparación auxiliar

Esta etapa garantiza que todos los nodos (`compute`, `network`, etc.) estén accesibles como `root` desde `bastion`, para evitar fallos de permisos.

### 🎯 Objetivos
- Role reusable que inyecta la clave pública de `vagrant` en `/root/.ssh/authorized_keys`.
- Script auxiliar manual para inyectar claves si es necesario.

---

### 📁 Estructura de la role

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

### 📄 Playbook `enable-root-access.yml`

```yaml
---
- name: Habilitar acceso root por SSH desde bastion
  hosts: compute
  become: true
  roles:
    - ssh_root_key
```

> ✅ Este playbook asume que el rol `ssh_root_key` está en `roles/ssh_root_key`.

---

### ✅ Ejecución:

```bash
ansible-playbook -i inventory.ini playbooks/enable-root-access.yml
```

---

### 🛠️ Script auxiliar desde el host: `prepare_node.sh`

```bash
#!/bin/bash
NODE="$1"
echo "==> Inyectando clave pública al usuario root en $NODE"
vagrant ssh "$NODE" -c "sudo mkdir -p /root/.ssh && sudo bash -c 'cat /vagrant/id_rsa.pub >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys'"
echo "==> Nodo $NODE preparado para acceso root por SSH desde bastion"
```

Uso:
```bash
./prepare_node.sh compute
```

---

## 🔬 7. Probar la tarea de forma aislada

Puedes lanzar una tarea simple para verificar permisos:

```bash
ansible controller -m file -a "path=/etc/haproxy/test.cfg state=touch" -b -K
```

---

## 📜 8. Usar `-vvv` para depuración detallada

```bash
ansible-playbook playbooks/setup-infrastructure.yml -vvv
```

Muestra el usuario remoto, comandos ejecutados, y detalles útiles para el diagnóstico.

---

## ✅ Checklist rápida

| Revisión                                   | Resultado esperado       |
|-------------------------------------------|--------------------------|
| `become: true`                             | ✅ Presente               |
| Usuario remoto tiene `sudo` sin contraseña| ✅ Sin errores            |
| Directorio con permisos correctos         | ✅ 755, propietario root  |
| SSH como root desde bastion               | ✅ Funcional              |
| Validación con tarea simple               | ✅ Funciona correctamente |