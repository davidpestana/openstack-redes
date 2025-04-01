# 🔧 Troubleshooting OpenStack-Ansible: Facts, Variables y Cachés

## 🔍 Problemas comunes abordados

Este documento cubre errores relacionados con:

- Variables definidas correctamente pero no aplicadas en los contenedores.
- Cambios en `user_variables.yml` que no tienen efecto.
- IPs desactualizadas o incorrectas dentro de contenedores.
- Contenedores que siguen intentando conectarse a IPs antiguas (ej: VIP).
- Persistencia de valores anteriores tras recrear contenedores.

---

## 🧹 Contexto: Facts y Variables en OpenStack-Ansible

- OpenStack-Ansible **genera y guarda facts** automáticamente en disco en:
  ```
  /etc/openstack_deploy/host_vars/<host>.yml
  ```
- Estos facts incluyen:
  - Interfaces de red, IPs, rutas.
  - Variables generadas por roles.
  - Resultado de los registros de tareas anteriores.

⚠️ Si modificas una variable (como `repo_server_host`) en `user_variables.yml`, **los contenedores y tareas pueden seguir usando el valor anterior si los facts no se han actualizado**.

---

## 🔢 Síntomas de problemas con facts/cache

- Contenedores usan IPs antiguas tras cambiar el inventario.
- Servicios como `pip`, `repo`, `keystone` o `galera` fallan al apuntar al VIP aunque se haya cambiado a una IP directa.
- El contenido de `/etc/pip.conf`, `/etc/hosts` o los ficheros de configuración siguen mostrando datos viejos.

---

## 🤖 Verificación de facts almacenados

```bash
grep repo_server_host /etc/openstack_deploy/host_vars/controller*.yml
```

Para buscar IPs antiguas (ej: `192.168.56.254`):

```bash
grep 192.168.56.254 /etc/openstack_deploy/host_vars/*
```

---

## 🚮 Solución: limpiar facts cacheados

### 🔄 Paso 1: Eliminar facts viejos

```bash
rm -f /etc/openstack_deploy/host_vars/<host>.yml
```

O todos:

```bash
rm -f /etc/openstack_deploy/host_vars/*
```

### 📂 Paso 2: Volver a recopilar facts

Ejecuta `setup-hosts.yml` para regenerarlos:

```bash
openstack-ansible setup-hosts.yml --limit <host>
```

---

## 🤔 Otros factores a considerar

- Verifica que tu variable esté correctamente definida en:
  - `/etc/openstack_deploy/user_variables.yml`
  - Y no sobrescrita en `group_vars/` o `host_vars/` manuales.

- Usa `ansible -m debug` para confirmar su valor en tiempo de ejecución:

```bash
ansible -i inventory/openstack controller -m debug -a "var=repo_server_host"
```

---

## 🔧 Recomendaciones

- Siempre limpia los facts al hacer cambios en IPs o configuraciones críticas.
- Evita confiar en que Ansible los reemplace automáticamente.
- Automatiza el borrado con scripts si haces despliegues iterativos.

---

## 🔍 Validación final

- Dentro del contenedor:

```bash
lxc-attach -n controller-utility-container-xxx
cat /etc/pip.conf | grep 192.168
```

- Desde bastion:

```bash
ansible -i inventory/openstack controller-utility-container-* -m setup -a "filter=ansible_all_ipv4_addresses"
```