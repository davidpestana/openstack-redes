## 🛠️ Troubleshooting de HAProxy en OpenStack-Ansible (OSA)

Este documento resume los problemas más comunes al desplegar HAProxy con OpenStack-Ansible y cómo solucionarlos.

---

### 🔍 Problema 1: `Destination /etc/haproxy/conf.d not writable`

**Síntomas:**

Durante el playbook `setup-hosts.yml` o `haproxy-install.yml`, aparece el error:

```
msg: "Destination /etc/haproxy/conf.d not writable"
```

**Causa:**

El directorio `/etc/haproxy/conf.d` no tiene los permisos adecuados o el rol `haproxy_server` no ejecuta las tareas con privilegios (`become: true`).

**Solución:**

1. Asegurarse de que el directorio tenga los permisos adecuados:

   ```bash
   sudo chown root:root /etc/haproxy/conf.d
   sudo chmod 755 /etc/haproxy/conf.d
   ```

2. Editar el rol `haproxy_server`, archivo:

   ```
   /etc/ansible/roles/haproxy_server/tasks/haproxy_service_config.yml
   ```

   Añadir `become: true` a la tarea:

   ```yaml
   - name: Create haproxy service config files
     become: true
     template:
       src: service.j2
       dest: "/etc/haproxy/conf.d/{{ service.haproxy_service_name }}"
       owner: root
       group: haproxy
       mode: "0640"
   ```

3. (Opcional) Añadir un `pre_task` al playbook para asegurar permisos futuros:

   ```yaml
   - name: Ensure haproxy conf.d has correct permissions
     file:
       path: /etc/haproxy/conf.d
       state: directory
       owner: root
       group: root
       mode: "0755"
     become: true
   ```

---

### 🔍 Problema 2: `unknown keyword 'prueba' in 'backend' section`

**Síntomas:**

El handler `Regenerate haproxy configuration` falla con:

```
[ALERT]: unknown keyword 'prueba' in 'backend' section
```

**Causa:**

Un archivo inválido (por ejemplo, `test.conf`) con contenido no compatible fue creado dentro de `/etc/haproxy/conf.d`, posiblemente como prueba.

**Solución:**

Eliminar el archivo inválido:

```bash
sudo rm /etc/haproxy/conf.d/test.conf
```

o desde Ansible:

```bash
ansible controller -b -m file -a "path=/etc/haproxy/conf.d/test.conf state=absent"
```

---

### 🔍 Problema 3: `Interactive authentication required` al recargar HAProxy

**Síntomas:**

El handler `Reload haproxy` falla con:

```
Failed to reload daemon: Interactive authentication required
```

**Causa:**

El handler intenta recargar `systemd` sin permisos `root`.

**Solución:**

Editar el handler en:

```
/etc/ansible/roles/haproxy_server/handlers/main.yml
```

Y añadir `become: true`:

```yaml
- name: Reload haproxy
  become: true
  systemd:
    name: haproxy
    state: reloaded
    daemon_reload: yes
```

---

### 🗓 Validaciones clave de HAProxy con IP flotante `192.168.56.254`

**Uso esperado:** acceden los contenedores LXC y a veces el host físico para descargar `upper_constraints_cached.txt` y paquetes Python cacheados.

**Validaciones esenciales:**

#### 🔹 Nivel 1: Red
- `ip a show br-mgmt` → ¿Tiene la IP `192.168.56.254/24`?
- `ping -c 3 192.168.56.254` desde un contenedor *(si está habilitado ICMP)*

#### 🔹 Nivel 2: HTTP
- `curl -I http://192.168.56.254:8181/...` desde host y contenedores
- `ss -tlnp | grep 8181` en host: ¿escucha en `192.168.56.254:8181`?

#### 🔹 Nivel 3: Inventario y variables
- `repo_server.host_address` en `openstack_user_config.yml` → debe ser `.254`
- `haproxy_hosts` en inventario → ¿está `controller` como `haproxy`?

#### 🔹 Nivel 4: Uso real
- Fases como `repo_build`, `pip_install`, `setup-hosts.yml` llaman a esa IP
- Fallos con `No route to host` indican que algo de los anteriores falla

---

### ✅ Conclusión validada

Una vez corregida la configuración de red y ruteo en el nodo `controller`, HAProxy puede escuchar correctamente en `192.168.56.254:8181`, y los contenedores pueden acceder al repo sin errores. La ejecución de `setup-hosts.yml` finaliza sin fallos, validando la funcionalidad de red esperada para HAProxy.

---

### ✅ Recomendación final

Después de aplicar las correcciones, relanzar el playbook:

```bash
openstack-ansible setup-infrastructure.yml --tags haproxy
```

o completo:

```bash
openstack-ansible setup-infrastructure.yml
```

