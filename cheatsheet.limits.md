## 🧠 Cheatsheet — Ejecución limitada en OpenStack-Ansible

### 🟢 **RECOMENDADO (seguro)**

| Objetivo | Comando | Comentario |
|---------|---------|------------|
| Ejecutar solo una parte específica del playbook | `--tags <tag>` | Ejemplo: `--tags haproxy` o `--tags galera` |
| Limitar a un nodo o grupo concreto | `--limit <host>` | Ejemplo: `--limit=controller` |
| Relanzar desde una tarea específica | `--start-at-task "<nombre exacto>"` | Útil si un fallo cortó la ejecución |
| Ver solo cambios sin ejecutar | `--check` + `--diff` | Ideal para dry-run: `openstack-ansible setup-hosts.yml --check --diff` |
| Lanzar tareas de un rol sin tocar el resto | `openstack-ansible <playbook> --tags <rol>` | Solo si sabes que el rol es independiente |

---

### 🟡 **ÚTIL PARA DEBUG (bajo riesgo, pero cuidado)**

| Objetivo | Comando | Comentario |
|---------|---------|------------|
| Ejecutar en un nodo de infraestructura específico | `--limit=<host>` | Si sabes que solo afecta a un contenedor |
| Usar `--start-at-task` para repetir desde el punto de fallo |  | Ahorra tiempo si sabes lo que haces |
| Ver qué tasks están incluidas por un tag | `ansible-playbook --list-tasks --tags <tag>` | Te ayuda a decidir si lanzar ese tag aislado |

---

### 🔴 **NO RECOMENDADO (riesgoso)**

| Acción | Por qué evitarla |
|--------|------------------|
| Usar `--skip-tags` en playbooks críticos | Puedes saltarte handlers o tareas necesarias |
| Ejecutar `setup-infrastructure.yml` parcial sin conocimiento del orden | Puedes dejar contenedores a medio configurar |
| Modificar `serial`, `max_fail_percentage`, o `strategy` sin entender sus efectos | Puede ocultar errores o dejar tareas incompletas |

---

### 🧪 Ejemplos rápidos

```bash
# Solo regenerar HAProxy
openstack-ansible setup-hosts.yml --tags haproxy

# Solo infra del nodo controller
openstack-ansible setup-infrastructure.yml --limit=controller

# Reintentar desde la tarea que falló
openstack-ansible setup-infrastructure.yml --start-at-task="Regenerate haproxy configuration"

# Ver qué tareas ejecutaría el tag galera
ansible-playbook setup-infrastructure.yml --tags galera --list-tasks
```

