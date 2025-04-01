# 🧠 Ansible Cheat Sheet

## 📘 ¿Qué es Ansible?

- Herramienta de automatización *agentless*.
- Se conecta por **SSH** a hosts remotos.
- Usa archivos **YAML** para definir tareas y configuraciones (playbooks).
- Ideal para: gestión de configuración, orquestación, despliegues.

---

## ⚙️ Instalación

**Debian/Ubuntu**
```bash
sudo apt install ansible
```

**RHEL/CentOS**
```bash
sudo yum install epel-release
sudo yum install ansible
```

**Con pip**
```bash
pip install ansible
```

---

## 📁 Inventario de Hosts

Ejemplo `hosts`:
```ini
[web]
192.168.1.10
web1.local

[db]
db1 ansible_host=192.168.1.20 ansible_user=ubuntu
```

`ansible.cfg` personalizado:
```ini
[defaults]
inventory = ./hosts
host_key_checking = False
```

---

## 🛠️ Comandos Básicos

| Acción                        | Comando                                      |
|------------------------------|-----------------------------------------------|
| Ver versión                   | `ansible --version`                          |
| Ping a todos los hosts        | `ansible all -m ping`                        |
| Ejecutar comando remoto       | `ansible all -m shell -a "uptime"`           |
| Usar un grupo                 | `ansible web -m shell -a "df -h"`            |
| Elevar permisos (sudo)        | `ansible all -b -m shell -a "apt update"`    |
| Usar usuario específico       | `ansible all -u ubuntu -m ping`              |

---

## 📜 Playbook de ejemplo

```yaml
- name: Instalar Apache
  hosts: web
  become: yes

  tasks:
    - name: Instalar paquete apache2
      apt:
        name: apache2
        state: present
        update_cache: yes

    - name: Asegurar que Apache esté activo
      service:
        name: apache2
        state: started
        enabled: yes
```

Ejecutar:
```bash
ansible-playbook playbook.yml
```

---

## 📦 Módulos Comunes

| Módulo     | Uso                                        |
|------------|---------------------------------------------|
| `ping`     | Verifica conectividad                       |
| `command`  | Ejecuta comandos (sin shell)                |
| `shell`    | Ejecuta comandos (con shell)                |
| `copy`     | Copia archivos                              |
| `template` | Genera archivos desde Jinja2                |
| `file`     | Crea, elimina, o cambia permisos            |
| `user`     | Crea o modifica usuarios                    |
| `service`  | Inicia/detiene/habilita servicios           |
| `apt/yum`  | Instala paquetes                            |
| `git`      | Clona repositorios                          |
| `debug`    | Muestra mensajes o variables en pantalla    |

---

## 🔁 Bucles

```yaml
- name: Crear varios usuarios
  user:
    name: "{{ item }}"
    state: present
  loop:
    - juan
    - maria
```

---

## 🔍 Condicionales

```yaml
- name: Solo en Debian
  apt:
    name: htop
    state: present
  when: ansible_os_family == "Debian"
```

---

## 🔔 Handlers

```yaml
tasks:
  - name: Actualizar config
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: Reiniciar NGINX

handlers:
  - name: Reiniciar NGINX
    service:
      name: nginx
      state: restarted
```

---

## 🔐 Ansible Vault

Crear archivo cifrado:
```bash
ansible-vault create secret.yml
```

Editar:
```bash
ansible-vault edit secret.yml
```

Ejecutar playbook protegido:
```bash
ansible-playbook playbook.yml --ask-vault-pass
```

---

## 🧬 Variables

Definir en el playbook:
```yaml
vars:
  puerto: 8080
```

Uso:
```yaml
msg: "La aplicación usa el puerto {{ puerto }}"
```

También puedes definir variables en:
- `group_vars/all.yml`
- `host_vars/hostname.yml`
- Línea de comandos con `--extra-vars "clave=valor"`

---

## 📁 Roles

Crear un rol:
```bash
ansible-galaxy init roles/nginx
```

Usar en un playbook:
```yaml
roles:
  - nginx
```

Estructura de rol:
```
roles/nginx/
├── tasks/
├── handlers/
├── templates/
├── files/
└── defaults/
```

---

## 🎯 Tags

```yaml
- name: Instalar NGINX
  apt:
    name: nginx
  tags: nginx
```

Ejecutar solo esa parte:
```bash
ansible-playbook playbook.yml --tags nginx
```

---

## 🧪 Depuración y Verbosidad

Más detalle en ejecución:
```bash
ansible-playbook playbook.yml -vvv
```

Mostrar variable:
```yaml
- debug:
    var: variable
```

---

## 🌐 Ansible Galaxy

Instalar rol:
```bash
ansible-galaxy install geerlingguy.nginx
```

Buscar roles:
```bash
ansible-galaxy search nginx
```

---