param location string
// Nombres estándar, pero parametrizables
param hostPoolName string = 'hp-avd-lab-01'
param appGroupName string = 'dag-desktop-lab-01' // DAG = Desktop Application Group
param workspaceName string = 'ws-avd-lab-01'

// 1. Host Pool (El contenedor de las VMs)
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2021-07-12' = {
  name: hostPoolName
  location: location
  properties: {
    friendlyName: 'Laboratorio AVD - Bicep'
    hostPoolType: 'Pooled' // Clave para costos: Varios usuarios comparten la misma VM
    loadBalancerType: 'BreadthFirst' // Equilibrio de carga horizontal
    preferredAppGroupType: 'Desktop' // Entregamos escritorios, no apps sueltas
    // Configuración RDP personalizada (Vital para optimización y medios)
    customRdpProperty: 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:*;redirectclipboard:i:1;redirectprinters:i:1;screen mode id:i:2;'
  }
}

// 2. Application Group (Lo que publicamos)
resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2021-07-12' = {
  name: appGroupName
  location: location
  properties: {
    hostPoolArmPath: hostPool.id // Vinculamos al Host Pool de arriba
    applicationGroupType: 'Desktop' // Tipo escritorio
    friendlyName: 'Escritorio Completo'
  }
}

// 3. Workspace (Lo que ve el usuario)
resource workspace 'Microsoft.DesktopVirtualization/workspaces@2021-07-12' = {
  name: workspaceName
  location: location
  properties: {
    friendlyName: 'Mis Escritorios Corporativos'
    applicationGroupReferences: [
      applicationGroup.id // Vinculamos el Grupo de Aplicaciones
    ]
  }
}

// Outputs
output hostPoolId string = hostPool.id
output hostPoolName string = hostPool.name
