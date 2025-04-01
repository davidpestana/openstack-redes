# Guía de Troubleshooting: Problemas con Contenedor Utility en OpenStack-Ansible

Esta guía detalla pasos claros para diagnosticar y resolver problemas relacionados con contenedores, específicamente cuando quedan estados "hardcodeados" o inconsistentes, como ocurre con el contenedor `utility`.

---

## 🔎 Diagnóstico Inicial

### Problemas frecuentes:
- El contenedor no pertenece a ningún grupo (`null`).

**Comprobación rápida:**
```bash
ansible-inventory --host controller-utility-container-7e5b64c5 | jq '.groups'
# => null indica problema
```

- La creación falla por usar grupos incorrectos o inexistentes.

**Grupo correcto:** `utility_container`

```bash
ansible-inventory --list | grep utility_container
```

---

## 🚨 Acciones inmediatas (Reconstruir contenedor)

Ejecuta los comandos en orden, desde `/opt/openstack-ansible/playbooks`:

```bash
# 1. Crear contenedor correctamente
openstack-ansible lxc-containers-create.yml --limit utility_container

# 2. Aplicar configuración de hosts e infraestructura al controller
openstack-ansible setup-hosts.yml --limit controller
openstack-ansible setup-infrastructure.yml --limit controller
```

---

## 📝 Validar resultados

Confirma que el contenedor se ha creado correctamente:

```bash
sudo lxc-ls -f | grep utility
# Debe mostrarse RUNNING
```

---

## ✅ Comprobaciones adicionales (recomendadas)

### Verificar ausencia del IP incorrecto (192.168.56.254)

```bash
sudo lxc-attach -n controller-utility-container-7e5b64c5 -- grep -r '192.168.56.254' /etc /root /opt
# No debe salir resultado
```

### Confirmar presencia del nuevo IP correcto (192.168.56.3)

```bash
sudo lxc-attach -n controller-utility-container-7e5b64c5 -- grep -r '192.168.56.3' /etc /root /opt
# Debería mostrar referencias al nuevo IP
```

---

## 🧹 Limpiar Facts viejos

Para evitar errores posteriores:

```bash
cd /opt/openstack-ansible/playbooks
rm -f /etc/openstack_deploy/host_vars/controller*
openstack-ansible setup-hosts.yml --limit controller
```

Si sospechas cambios adicionales o problemas en otros nodos:

```bash
rm -f /etc/openstack_deploy/host_vars/*
openstack-ansible setup-hosts.yml
```

---

## 🚩 Continuar el despliegue normal

Finalmente, ejecuta los pasos restantes sin límites específicos:

```bash
cd /opt/openstack-ansible/playbooks
openstack-ansible setup-hosts.yml
openstack-ansible setup-infrastructure.yml
openstack-ansible setup-openstack.yml
```

---

## 🎯 Buenas Prácticas (Lecciones aprendidas)

- Validar grupos del inventario antes de lanzar comandos.
- Limpiar regularmente los facts para evitar estados inconsistentes.
- Siempre confirmar la configuración final del contenedor antes de proceder.