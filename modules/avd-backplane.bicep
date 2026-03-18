param location string
// Nombres estándar, pero parametrizables
param hostPoolName string = 'hp-avd-lab-01'
param appGroupName string = 'dag-desktop-lab-01' // DAG = Desktop Application Group
param workspaceName string = 'ws-avd-lab-01'
param avdGroupId string = 'be68021d-80a7-43c5-828d-cf37a7b49c11'

// 1. Host Pool (El contenedor de las VMs)
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' = {
  name: hostPoolName
  location: location
  properties: {
    friendlyName: 'Laboratorio AVD - Bicep'
    hostPoolType: 'Pooled' // Clave para costos: Varios usuarios comparten la misma VM
    loadBalancerType: 'BreadthFirst' // Equilibrio de carga horizontal
    preferredAppGroupType: 'Desktop' // Entregamos escritorios, no apps sueltas
    // Configuración RDP personalizada (Vital para optimización y Entra ID)
    customRdpProperty: 'audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:*;redirectclipboard:i:1;redirectprinters:i:1;screen mode id:i:2;targetisaadjoined:i:1;enablerdsaadauth:i:1;'
  }
}

// 2. Application Group (Lo que publicamos)
resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' = {
  name: appGroupName
  location: location
  properties: {
    hostPoolArmPath: hostPool.id // Vinculamos al Host Pool de arriba
    applicationGroupType: 'Desktop' // Tipo escritorio
    friendlyName: 'Escritorio Completo'
  }
}

// ASIGNACIÓN DE ROL: Desktop Virtualization User DIRECTAMENTE en el App Group
// Es indispensable hacerlo aquí y no en el RG para que AVD descubra el feed rápidamente
resource avdUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(applicationGroup.id, avdGroupId, 'DesktopVirtualizationUser')
  scope: applicationGroup
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
    principalId: avdGroupId
    principalType: 'Group'
  }
}

// 3. Workspace (Lo que ve el usuario)
resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' = {
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
