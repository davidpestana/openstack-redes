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
- `ping <IP bastion>` *(nota: Ubuntu Server puede tener ICMP bloqueado por defecto, lo consideramos opcional)*
- `ping <IP controller>` *(idem)*
- `ping <IP de cada nodo relevante>` *(idem)*

Desde `bastion`:
- `ssh controller`, `ssh compute`, etc. deben funcionar directamente, resolviendo nombres por `/etc/hosts`.
- La conexión SSH debe establecerse vía interfaz de mantenimiento (`br-mgmt`), no por interfaces residuales.

#### ✅ Rutas
- Ejecutar en cada nodo:
  ```bash
  ip route get <IP de otro nodo>
  ```
  La interfaz usada debe ser `br-mgmt`, **nunca `enp0s8` o interfaces residuales de VirtualBox**.

- Validar también:
  ```bash
  ip route get <IP bastion>
  ```
  Y si fuera necesario:
  ```bash
  sudo ip route add <IP bastion> dev br-mgmt
  ```

#### ✅ SSHD
- `ss -tlnp | grep :22` debe mostrar `0.0.0.0:22` o `192.168.x.x:22` como `LISTEN`
- SSH debe estar habilitado y permitir acceso sin contraseña si se usan llaves

#### ✅ Firewall
- `sudo iptables -L -n` debe mostrar `policy ACCEPT` o reglas que permitan SSH (puerto 22)

---

### 🔹 Recomendaciones clave

- **Asignar rutas estáticas por interfaz `br-mgmt`** para todos los nodos desde el principio.
- **Eliminar o ignorar interfaces como `enp0s8`** si no están en uso real.
- Documentar en `inventory` e `interfaces` de red todas las IPs asignadas y su función.
- Asegurar que todas las pruebas de red pasen **antes** de ejecutar `openstack-ansible`.
- **Revisar el Vagrantfile cuidadosamente**: algunas configuraciones pueden generar interfaces residuales (`enp0s8`) que entran en conflicto con `br-mgmt`. Esto puede generar rutas incorrectas y errores de conectividad. Dejar este fallo intencionado puede ser útil como ejercicio formativo.
- **Verificar las rutas de retorno por red de mantenimiento (`br-mgmt`)** entre todos los nodos y hacia `bastion` como condición previa obligatoria.
- **Validar que `bastion` conecta por SSH a todos los nodos usando exclusivamente la interfaz `br-mgmt`**, para garantizar que los servicios y despliegues posteriores usarán las redes adecuadas (mantenimiento, datos, almacenamiento).

---

### 🔧 Reajuste del Vagrantfile tras validaciones manuales

Una vez detectado que los interfaces de red están mal mapeados, se recomienda **refactorizar el `Vagrantfile`** para automatizar los arreglos validados manualmente:

- Asignar correctamente las redes internas con `virtualbox__intnet` a cada interfaz, según su propósito (`mgmt`, `data`, `storage`).
- Eliminar o evitar la interfaz NAT predeterminada si no es necesaria.
- Usar `vb.customize` para asegurar modo promiscuo en interfaces necesarias.
- Verificar que las IPs estén en la interfaz correcta y sin superposición de rutas.
- Confirmar que la red de mantenimiento (`openstack-mgmt`) esté siempre asignada a la misma NIC.

Este reajuste garantiza reproducibilidad y evita repetir correcciones manuales en cada despliegue.

---

### 🧰 Cheat Sheet: bridge-utils

Herramientas útiles cuando se usan bridges en entornos con LXC o redes virtuales:

```bash
brctl show               # Ver bridges definidos y sus interfaces
brctl showmacs <bridge>  # Ver direcciones MAC aprendidas por el bridge
brctl addbr <bridge>     # Crear un bridge
brctl addif <bridge> <iface>  # Añadir interfaz a un bridge
brctl delif <bridge> <iface>  # Quitar interfaz de un bridge
brctl delbr <bridge>     # Eliminar un bridge (si está vacío)
```

> Nota: `bridge-utils` puede no venir instalado por defecto. Instalar con:
```bash
sudo apt install bridge-utils
```


---

Este checklist evita errores difíciles de depurar y garantiza un despliegue reproducible y estable desde `bastion` usando OpenStack-Ansible.

