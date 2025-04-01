

# 🛠️ Guía de Troubleshooting de Permisos en OpenStack-Ansible (OSA)

## 🎯 Objetivo

Diagnosticar y corregir errores como:

- `"Permission denied"`  
- `"Destination not writable"`  
- `"Cannot open file: Read-only file system"`  
- `"Failed to write to /etc/xyz"`  

... sin modificar manualmente el sistema de archivos, sino **corrigiendo los orígenes a través de Ansible, configuración o infraestructuras declarativas**.

---

## ✅ 1. **Identifica dónde ocurre el error**

Los errores de permisos pueden ocurrir en:

| Contexto | Ejemplo típico |
|---------|----------------|
| **Contenedor LXC** | Archivos en `/etc`, `/var/log`, etc. |
| **Host físico** | Rutas bind-montadas como `/etc/hosts`, `/etc/haproxy/` |
| **Repositorio compartido (gluster/NFS)** | `/var/www/repo` |
| **Temporales de build** | `/openstack/venvs/...` |

Revisa el `msg:` exacto del error y su `path`.

---

## ✅ 2. **Verifica si el path está "bind-mounted"**

OSA utiliza bind mounts para exponer rutas del host dentro de los contenedores.  
Estos se definen vía `lxc_container_config` y son gestionados en:

- `/etc/openstack_deploy/env.d/*.yml`
- `openstack_user_config.yml`

Para verificar si el archivo problemático es parte de un bind mount:

```bash
grep bind /etc/openstack_deploy/env.d/*.yml
```

O revisa directamente la configuración del contenedor:

```bash
lxc-config -n <container-name> | grep mount
```

---

## 🧩 3. **Entiende de dónde vienen los permisos**

| Caso | Quién define los permisos |
|------|---------------------------|
| Bind mount | **El host físico**, no el contenedor |
| Dentro del contenedor | Las tasks de Ansible, `roles/*`, handlers |
| Archivo generado dinámicamente | Templates (Jinja2) + permisos en la tarea Ansible |
| Directorio temporal (`/openstack/...`) | El rol `python_venv_build` u otros |

---

## ⚙️ 4. **Solución reproducible (no parche): usa estas estrategias**

### 🧱 A) Para **directorios montados desde el host** (bind mounts)

🔄 **Estrategia**: asegura su existencia y permisos correctos **antes** de ejecutar `setup-infrastructure.yml`

📍 Usa una task previa en un playbook de bootstrap:

```yaml
- name: Ensure /etc/haproxy/conf.d exists on host
  hosts: hosts
  become: true
  tasks:
    - name: Create and set ownership
      file:
        path: /etc/haproxy/conf.d
        state: directory
        owner: root
        group: root
        mode: '0755'
```

➡️ Esto se puede insertar en `playbooks/bootstrap-hosts.yml` o uno personalizado (`custom-host-init.yml`).

---

### 🛠️ B) Para errores en archivos internos del contenedor

Verifica si el rol o tarea ya tiene `owner`, `group` y `mode`.

✅ Ejemplo correcto en un role de OSA:

```yaml
- name: Create config directory
  file:
    path: /etc/nova
    state: directory
    owner: root
    group: nova
    mode: '0750'
```

📌 Si no los tiene, **usa `set_fact` o `vars` para parametrizarlos**.

---

### 🧰 C) Para archivos generados por templates

✅ Usa el módulo `template` correctamente:

```yaml
- name: Deploy config
  template:
    src: nova.conf.j2
    dest: /etc/nova/nova.conf
    owner: nova
    group: nova
    mode: '0640'
```

Si estás usando un role externo (por ejemplo, el de HAProxy), **verifica si hay variables como**:

```yaml
haproxy_conf_dir_owner: root
haproxy_conf_dir_group: root
haproxy_conf_dir_mode: "0755"
```

Y sobreescríbelas en `user_variables.yml` si es necesario.

---

### 📂 D) Para rutas tipo `/var/www/repo` o `/openstack/...`

Revisa si están gestionadas por:

- `repo_server`
- `python_venv_build`
- `glusterfs`
- `bind mounts del host`

📌 Si son bind mounts → ver A)  
📌 Si son locales → revisa las tareas en los roles y asegúrate de que no estén con permisos restrictivos por defecto.

---

## 🧼 5. **En caso de duda, recrear el contenedor afectado**

Esto asegura que:

- Se rehacen los bind mounts
- Se rehacen los permisos esperados
- Se ejecutan los handlers de `lxc_container_create`

```bash
lxc-stop -n <container>
lxc-destroy -n <container>
openstack-ansible setup-infrastructure.yml
```

---

## 🔒 6. **Evita workarounds que rompen reproducibilidad**

🚫 Evita:

- `chmod` o `chown` manual fuera de Ansible
- `touch` de archivos sin declararlo como recurso gestionado
- Cambios persistentes dentro del contenedor sin playbook

✅ En su lugar, usa:

- `file:`
- `template:`
- `copy:`
- `blockinfile:` (si lo necesitas para configurar archivos complejos)

---

## 🧪 7. Check de verificación reproducible para futuros despliegues

Antes de lanzar `setup-infrastructure.yml`, puedes añadir un playbook como:

```yaml
- name: Pre-flight check: permisos de paths críticos
  hosts: hosts
  become: true
  tasks:
    - name: Check /etc/haproxy/conf.d
      stat:
        path: /etc/haproxy/conf.d
      register: haproxy_conf_check

    - name: Fail if wrong owner
      fail:
        msg: "El directorio /etc/haproxy/conf.d no tiene los permisos esperados"
      when: haproxy_conf_check.stat.exists and haproxy_conf_check.stat.pw_name != 'root'
```