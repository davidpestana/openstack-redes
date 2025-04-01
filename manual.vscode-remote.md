Perfecto, aquí tienes el documento final limpio y listo para copiar:
# 🪟 Conexión de Visual Studio Code a una VM Vagrant `bastion` en Windows con Remote-SSH

## Requisitos

- Visual Studio Code  
- Extensión **Remote - SSH** instalada  
- Git for Windows (para disponer de `ssh.exe`)  
- Vagrant con una máquina llamada `bastion` levantada (`vagrant up bastion`)  
---

## 1. Obtener configuración SSH desde Vagrant

Ejecutar en PowerShell o CMD desde el directorio del `Vagrantfile`:

```bash
vagrant ssh-config bastion
```

Ejemplo de salida:

```
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  IdentityFile "C:/Users/TuUsuario/.vagrant.d/insecure_private_key"
```

---

## 2. Registrar el host en Visual Studio Code

1. Abrir Visual Studio Code  
2. Pulsar `Ctrl+Shift+P` para abrir la paleta de comandos  
3. Ejecutar `Remote-SSH: Add New SSH Host...`  
4. Edita la cadena con las variables obtenidas e introduce el comando SSH en la terminat gitbah ( donde esta disponible el ejecutable ssh ):

   ```bash
   ssh -i "C:/Users/TuUsuario/.vagrant.d/insecure_private_key" -p 2222 vagrant@127.0.0.1
   ```

5. Cuando te pregunte donde ... idealmente elegir guardar en `C:\Users\TuUsuario\.ssh\config`

---

## 3. Conectar a `bastion`

1. Abrir `Ctrl+Shift+P`  
2. Ejecutar `Remote-SSH: Connect to Host...`  
3. Seleccionar `vagrant@127.0.0.1`  
4. Aceptar la clave del host cuando se solicite  
5. Se abrirá una nueva ventana de VS Code conectada a la máquina remota

---

## 4. Abrir carpetas del entorno remoto

1. Una vez conectado, ejecutar `Remote-SSH: Open Folder...` desde la paleta de comandos  
2. Seleccionar una carpeta en la VM (por ejemplo, `/home/vagrant/proyecto`)  
3. La carpeta se abrirá como entorno de trabajo remoto

---

## 5. Añadir más carpetas al workspace

1. Ir a `File → Add Folder to Workspace...`  
2. Elegir más carpetas del entorno remoto  
3. Aparecerán todas agrupadas en el workspace activo

---

## 6. Guardar el workspace en la máquina remota

1. Ir a `File → Save Workspace As...`  
2. Guardar el archivo en alguna carpeta del usuario vagrant en la propia VM, por ejemplo:

   ```
   /home/vagrant/code-workspace
   ```
---

## 7. Reabrir el workspace remoto en futuras sesiones

1. Abrir VsCode o Reconectarse a `bastion` desde VS ode ahora es posible, VScode recordara la conexión y estara disponible a no ser que se elimine.
2. El entorno se restaurará con carpetas, configuración y terminales anteriores.