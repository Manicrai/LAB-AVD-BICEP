# Zero-Touch Azure Virtual Desktop (AVD) Deployment with Bicep

Este repositorio contiene una infraestructura completa de **Azure Virtual Desktop (AVD)** diseñada para desplegarse mediante código (Infrastucture as Code - IaC) de principio a fin, utilizando la tecnología nativa de **Azure Bicep** combinada con envolturas de orquestación en **PowerShell**.

Este es un entorno de laboratorio (`lab`) optimizado para reducción de costos, agilidad y configuración automática para identidades puramente basadas en la nube (**Microsoft Entra ID / Azure AD**), erradicando por completo la necesidad de un Controlador de Dominio clásico on-premises.

## Características Técnicas Principales
- 🚀 **Despliegue Cero-Toques**: Un solo script PowerShell (`deploy.ps1`) se encarga del inicio de sesión, creación del grupo de recursos, orquestación Bicep e inyección segura de tokens.
- ☁️ **Native Microsoft Entra ID Join**: La máquina (Session Host) se une automáticamente a Entra ID utilizando la extensión `AADLoginForWindows` y *SystemAssigned Managed Identities*. No requiere Controladores de Dominio.
- 💾 **FSLogix Preconfigurado**: Integración directa con Azure Files a través del protocolo SMB y autenticación Entra Kerberos para contenedores de perfiles de usuario dinámicos. Reducción a 0% de tiempos muertos en inicio de sesión.
- ⚡ **Agente AVD "Bulletproof"**: Script minimizado y optimizado que limpia registros residuales y utiliza inyección directa por Base64 vía `CustomScriptExtension` (evitando límites de comandos nativos de Windows). Descarga el instalador directo del AVD Broker desde CDNs crudas para evadir falsos positivos de bloqueo.
- 💰 **Control Rígido de Costos**: Adopta máquinas serie `B2s` bajo un disco de estado sólido Standard, e integra la programación nativa de DevTestLabs (`Microsoft.DevTestLab/schedules`) para el **apagado automático diario**.

## Estructura del Código

```text
📦 LAB-AVD-BICEP
 ┣ 📂 modules
 ┃ ┣ 📜 network.bicep          # Redes Virtuales (VNET, Subnets)
 ┃ ┣ 📜 avd-backplane.bicep    # Broker AVD (Host Pools, App Groups, Workspaces)
 ┃ ┣ 📜 storage.bicep          # Azure Files para montar Perfiles FSLogix
 ┃ ┗ 📜 vm.bicep               # El Session Host, Identidades y Extensiones
 ┣ 📜 main.bicep               # Orquestador Principal Bicep
 ┣ 📜 deploy.ps1               # Entorno de inicio y disparador
 ┗ 📜 install-agent.ps1        # Receta infalible empaquetada en Base64 a la VM
```

## Requisitos Previos (Prerequisites)
1. **Azure CLI** instalado (`az login` será forzado en el script corto).
2. Permisos de **Propietario (Owner)** en la suscripción de Azure meta para aplicar correctamente el acceso de Roles RBAC en Múltiples Ambientes.
3. Un entorno Windows local (preferible PowerShell 7.x).

## Instalación y Despliegue

Simplemente, desde un terminal elevado, lanza:
```powershell
.\deploy.ps1 -AdminPassword "TuContraseñaSúperSegura123!"
```

El script tomará todo el paquete, inyectará tu contraseña temporal, validará que tu PC local se comunique con Entra ID de manera silenciosa y creará la infraestructura hasta montar por completo las granjas AVD bajo tu grupo de recursos `rg-avd-lab-01`.

Tras 10-15 minutos aproximadamente y de reportar éxito, los recursos aparecerán como *Available* en el Panel AVD. 

> [!WARNING]
> La primera vez que el host se añade al Host Pool puede mostrar un falso rojo de alerta bajo el rubro `DomainJoinedCheck`. Esto es deliberado porque el host corre netamente en nube `Entra ID`, por lo cual, siempre y cuando arroje que `AADJoinedHealthCheck` esté exitoso (Verde), podrás ignorar la primera advertencia.
> 
> Es mandatorio asignar **permisos NTFS a nivel Directorio** dentro de tu Azure File Share por primera vez vía *icacls* antes de que FSLogix comience a escribir exitosamente perfiles montados para tus usuarios sin privilegios administrativos.