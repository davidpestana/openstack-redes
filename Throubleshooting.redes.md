## 📝 Troubleshooting red y nodos físicos antes del despliegue de OpenStack-Ansible

Este documento recoge las validaciones mínimas y recomendaciones clave para asegurar que los nodos físicos y sus redes están correctamente configurados **antes de desplegar OpenStack-Ansible desde el nodo bastion**.

---

### 🔹 Validaciones generales por nodo

#### ✅ Interfaces
- Cada nodo debe tener:
  - Interfaz conectada a la red de mantenimiento (`br-mgmt`), con IP fija.
  - En lo posible, **evitar usar interfaces NAT o `enp0s8`/VirtualBox** para comunicación entre nodos.

#### ✅ Conectividad de red
Desde cada nodo:
- `ping <IP bastion>`
- `ping <IP controller>`
- `ping <IP de cada nodo relevante>`

Desde `bastion`:
- `ssh vagrant@<ip_nodo>` debe conectar sin timeout.

#### ✅ Rutas
- Ejecutar en cada nodo:
  ```bash
  ip route get <IP de otro nodo>
  ```
  La interfaz usada debe ser `br-mgmt`, **nunca `enp0s8` o interfaces residuales de VirtualBox**.

#### ✅ SSHD
- `ss -tlnp | grep :22` debe mostrar `0.0.0.0:22` o `192.168.x.x:22` como `LISTEN`
- SSH debe estar habilitado y permitir acceso sin contraseña si se usan llaves

#### ✅ Firewall
- `sudo iptables -L -n` debe mostrar `policy ACCEPT` o reglas que permitan SSH (puerto 22)

---

### 🔹 Validaciones específicas en `controller`

#### 🔹 HAProxy y br-mgmt
- `br-mgmt` debe tener IP `192.168.56.254`
- `ss -tlnp | grep 8181` debe mostrar que HAProxy escucha en `192.168.56.254:8181`
- `curl http://192.168.56.3:8181` desde `controller` debe devolver HTTP 200 (acceso al repo)

#### 🔹 Rutas de retorno correctas
- `ip route get <IP bastion>` debe indicar `dev br-mgmt`, no `enp0s8`
- Si no es así:
  ```bash
  sudo ip route add <IP bastion> dev br-mgmt
  ```

---

### 🔹 Recomendaciones clave

- **Asignar rutas estáticas por interfaz `br-mgmt`** para todos los nodos desde el principio.
- **Eliminar o ignorar interfaces como `enp0s8`** si no están en uso real.
- Documentar en `inventory` e `interfaces` de red todas las IPs asignadas y su función.
- Asegurar que todas las pruebas de red pasen **antes** de ejecutar `openstack-ansible`.

---

Este checklist evita errores difíciles de depurar y garantiza un despliegue reproducible y estable desde `bastion` usando OpenStack-Ansible.

