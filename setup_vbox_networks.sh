#!/bin/bash

# Detectar el sistema operativo
OS=$(uname -s)

# Función para configurar redes en Linux/macOS
setup_unix() {
    echo "🔄 Eliminando redes Host-Only existentes en VirtualBox..."
    for net in $(VBoxManage list hostonlyifs | grep "Name" | awk '{print $2}'); do
        echo "❌ Eliminando $net ..."
        VBoxManage hostonlyif remove $net
    done

    echo "✅ Creando nueva red Host-Only para gestión..."
    VBoxManage hostonlyif create
    VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0

    echo "✅ Creando nueva red Host-Only para datos..."
    VBoxManage hostonlyif create
    VBoxManage hostonlyif ipconfig vboxnet1 --ip 10.0.0.1 --netmask 255.255.255.0

    echo "✅ Creando nueva red Host-Only para almacenamiento..."
    VBoxManage hostonlyif create
    VBoxManage hostonlyif ipconfig vboxnet2 --ip 172.16.0.1 --netmask 255.255.255.0

    echo "🚀 Redes configuradas correctamente. Reinicia VirtualBox si es necesario."
}

# Función para configurar redes en Windows (PowerShell)
setup_windows() {
    echo "🔄 Eliminando redes Host-Only existentes en VirtualBox..."
    powershell.exe -Command "& {
        \$vboxnets = VBoxManage list hostonlyifs | Select-String 'Name: ' | ForEach-Object { (\$_ -split ': ')[1] }
        foreach (\$net in \$vboxnets) {
            Write-Host '❌ Eliminando' \$net
            VBoxManage hostonlyif remove \$net
        }
        Write-Host '✅ Creando nueva red Host-Only para gestión...'
        VBoxManage hostonlyif create
        VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0

        Write-Host '✅ Creando nueva red Host-Only para datos...'
        VBoxManage hostonlyif create
        VBoxManage hostonlyif ipconfig vboxnet1 --ip 10.0.0.1 --netmask 255.255.255.0

        Write-Host '✅ Creando nueva red Host-Only para almacenamiento...'
        VBoxManage hostonlyif create
        VBoxManage hostonlyif ipconfig vboxnet2 --ip 172.16.0.1 --netmask 255.255.255.0

        Write-Host '🚀 Redes configuradas correctamente. Reinicia VirtualBox si es necesario.'
    }"
}

# Ejecutar según el sistema operativo
case "$OS" in
    "Linux"|"Darwin") setup_unix ;;
    "MINGW"*|"CYGWIN"*|"MSYS"*) setup_windows ;;
    *) echo "⚠️ Sistema operativo no soportado: $OS" ;;
esac
