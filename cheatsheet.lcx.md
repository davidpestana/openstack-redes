## 🐧 **Contenedores LXC – Manual de Referencia Rápida**

---

### 📌 ¿Qué es LXC?

LXC (Linux Containers) es una tecnología de virtualización a nivel de sistema operativo que permite ejecutar múltiples entornos Linux aislados (contenedores) en una sola máquina host usando un único kernel.

- A diferencia de Docker, LXC es más parecido a una VM ligera (soporta `systemd`, acceso root completo, etc.).
- Usa **namespaces** y **cgroups** para aislamiento.
- Administra entornos completos tipo sistema operativo (no solo procesos como Docker).

---

### ⚙️ Instalación de LXC

#### En Debian/Ubuntu:

```bash
sudo apt update
sudo apt install lxc lxc-templates uidmap
```

#### En CentOS/RHEL:

```bash
sudo yum install epel-release
sudo yum install lxc lxc-templates
```

#### Verifica versión:

```bash
lxc-info --version
```

---

### 📁 Archivos y Directorios Importantes

| Ruta                         | Descripción                                   |
|------------------------------|-----------------------------------------------|
| `/var/lib/lxc/`              | Contenedores y su configuración               |
| `/etc/lxc/`                  | Archivos de configuración global              |
| `/etc/lxc/lxc.conf`          | Configuración por defecto para todos          |
| `/etc/subuid`, `/etc/subgid`| Rango de UID/GID para contenedores sin root   |

---

### 🚀 Crear, Iniciar y Administrar Contenedores

#### Crear un contenedor:

```bash
sudo lxc-create -n contenedor1 -t download
```

- Puedes elegir distro, versión y arquitectura (ej: ubuntu, focal, amd64)

#### Listar contenedores:

```bash
lxc-ls -f
```

#### Iniciar / detener / reiniciar:

```bash
sudo lxc-start -n contenedor1
sudo lxc-stop -n contenedor1
sudo lxc-restart -n contenedor1
```

#### Acceder al contenedor:

```bash
sudo lxc-attach -n contenedor1
```

#### Ver estado e info:

```bash
sudo lxc-info -n contenedor1
```

---

### 🧠 Configuración del Contenedor

#### Fichero de configuración:

```bash
/var/lib/lxc/contenedor1/config
```

Algunas directivas clave:

```ini
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx
```

---

### 🌐 Red en LXC

#### Ver bridge por defecto (lxcbr0):

```bash
ip a show lxcbr0
```

#### Ver DHCP asignado al contenedor:

```bash
lxc-info -n contenedor1 | grep IP
```

#### Ejecutar comandos de red:

```bash
lxc-attach -n contenedor1 -- ip a
lxc-attach -n contenedor1 -- ping google.com
```

---

### 📤 Copiar archivos dentro/fuera del contenedor

```bash
sudo lxc-file push archivo.txt contenedor1/tmp/
sudo lxc-file pull contenedor1/tmp/archivo.txt .
```

---

### 🔐 Contenedores sin privilegios (Unprivileged Containers)

- Ejecutar como usuario no root.
- Necesita configuración en `/etc/subuid` y `/etc/subgid`.

Ejemplo:

```bash
echo "usuario:100000:65536" | sudo tee -a /etc/subuid /etc/subgid
```

Crear contenedor sin root:

```bash
lxc-create -n mi_cont_sin_root -t download -B dir -P ~/.local/share/lxc
```

---

### 🔄 Clonado, Snapshots y Backups

#### Clonar contenedor:

```bash
sudo lxc-copy -n contenedor1 -N contenedor2
```

#### Snapshot (si usa backend LVM o btrfs):

```bash
sudo lxc-snapshot -n contenedor1
```

#### Backup manual:

```bash
sudo tar -czf contenedor1-backup.tar.gz /var/lib/lxc/contenedor1
```

---

### 📦 Plantillas y Sistemas Disponibles

Ver plantillas disponibles (modo interactivo):

```bash
lxc-create -n test -t download
```

Ver imágenes disponibles:

```bash
lxc-create -t download --list
```

---

### 🧹 Borrar contenedores

```bash
sudo lxc-stop -n contenedor1
sudo lxc-destroy -n contenedor1
```

---

### 🛠️ Debugging y Logs

```bash
sudo lxc-start -n contenedor1 -l DEBUG -o /tmp/lxc-debug.log
```

Ver log de arranque:

```bash
cat /var/log/lxc/contenedor1.log
```

---

### 🧱 Comparación básica con Docker

| Característica         | LXC                             | Docker                          |
|------------------------|----------------------------------|----------------------------------|
| Tipo                   | Sistema completo                 | Aplicación/proceso              |
| Init System            | Soporta `systemd`, `init`        | No soporta                      |
| Root dentro del contenedor | Sí                          | No (por defecto)                |
| Aislamiento             | Alto, pero comparte kernel       | Muy alto, más encapsulado       |
| Uso                    | VMs ligeras, entornos completos  | Microservicios, CI/CD           |