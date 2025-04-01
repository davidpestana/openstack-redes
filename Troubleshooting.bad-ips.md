## 🧩 Troubleshooting: IPs incorrectas o cruzadas en contenedores de OpenStack-Ansible

### 📌 Contexto

En entornos OpenStack-Ansible, es común que tras modificar variables de red (ej. VIPs, IPs de bridges o contenedores) los contenedores ya existentes **mantengan configuraciones desactualizadas** en sus archivos internos, causando errores como:

- Falla de conexión a servicios internos (repo, galera, rabbit, etc.)
- Resolución de nombres incorrecta
- Configuraciones internas apuntando a IPs viejas

---

## 🛠️ Diagnóstico paso a paso

### 1. 🔍 Verifica la IP configurada en `user_variables.yml`

```bash
grep repo_server_host /etc/openstack_deploy/user_variables.yml
```

También revisa:

```bash
grep external_lb_vip_address /etc/openstack_deploy/user_variables.yml
```

---

### 2. 🧠 Confirma que Ansible la reconoce

```bash
ansible -m debug -a "var=repo_server_host" localhost
```

Si usas un inventario real:

```bash
ansible -i inventory/openstack controller -m debug -a "var=repo_server_host"
```

---

### 3. 🔎 Verifica qué contenedores están configurados con la IP incorrecta

Desde bastion:

```bash
ansible -i inventory/openstack controller-utility-container* -a "grep -r 192.168.56.254 /etc"
```

O entra directamente en el contenedor:

```bash
lxc-attach -n controller-utility-container-xxxx
cat /etc/pip.conf
```

---

## 🔄 Solución segura: regenerar los contenedores

### ✅ Paso 1: Destruir contenedores afectados

Puedes destruir todos los del host si es necesario:

```bash
openstack-ansible lxc-containers-destroy.yml --limit controller
```

Responde:

```
Destroy containers? yes
Destroy container data? no
```

> ⚠️ **"no" a los datos** para no perder configuración persistente.

---

### ✅ Paso 2: Recrear contenedores

```bash
openstack-ansible setup-hosts.yml --limit controller
```

---

### ✅ Paso 3: Reaplicar infraestructura (si procede)

```bash
openstack-ansible setup-infrastructure.yml --limit controller
```

---

## 🧪 Validación posterior

### Probar si la IP nueva está aplicada correctamente:

```bash
ansible -i inventory/openstack controller-utility-container-* \
  -m uri \
  -a "url=http://192.168.56.3:8181/constraints/upper_constraints_cached.txt return_content=yes"
```

### Verificar IPs internas del contenedor:

```bash
lxc-attach -n controller-utility-container-xxxx
ip a
```

---

## 🧼 Limpieza (cuando ya tengas el VIP activo)

1. Revertir el workaround en `user_variables.yml` (volver a usar `192.168.56.254`)
2. Volver a recrear contenedores
3. Verificar que HAProxy está funcionando:

```bash
curl -I http://192.168.56.254:8181/constraints/upper_constraints_cached.txt
```

---

## 🧷 Consejos finales

- No edites IPs manualmente dentro de los contenedores.
- Evita confiar en que Ansible “arreglará” las IPs en contenedores ya creados.
- Usa `lxc-containers-destroy.yml` sin destruir datos si el servicio ya estaba parcialmente desplegado.