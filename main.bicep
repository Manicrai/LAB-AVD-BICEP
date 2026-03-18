targetScope = 'resourceGroup'

// --- PARÁMETROS GLOBALES ---
param location string = resourceGroup().location
param avdGroupId string = 'be68021d-80a7-43c5-828d-cf37a7b49c11' // Object ID del grupo AVD en Entra ID

@secure()
param vmPassword string 
param deployVm bool = true
@secure()
param hostPoolToken string = '' // Será inyectado mediante script 

// --- MÓDULOS ---

// 1. Red
module networkModule 'modules/network.bicep' = {
  name: 'deployNetwork'
  params: {
    location: location
    vnetName: 'vnet-avd-lab-01'
  }
}

// 2. Almacenamiento
module storageModule 'modules/storage.bicep' = {
  name: 'deployStorage'
  params: {
    location: location
  }
}

// 3. AVD Backplane
module avdModule 'modules/avd-backplane.bicep' = {
  name: 'deployAvdBackplane'
  params: {
    location: location
    avdGroupId: avdGroupId
  }
}

// 4. Virtual Machine (Solo se despliega si deployVm es true)
module vmModule 'modules/vm.bicep' = if (deployVm) {
  name: 'deployVM'
  params: {
    location: location
    // Ahora sí, pasamos el parámetro global al módulo
    adminPassword: vmPassword
    hostPoolToken: hostPoolToken
    fileSharePath: storageModule.outputs.fileSharePath
  }
}

// --- ASIGNACIONES DE ROLES (RBAC) ---
// Aplicamos los roles a nivel de Resource Group por simplicidad en el laboratorio.

// 1. Rol: Virtual Machine User Login (Para entrar a la Máquina de Entra ID)
resource vmUserLoginRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, avdGroupId, 'VirtualMachineUserLogin')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')
    principalId: avdGroupId
    principalType: 'Group'
  }
}

// 3. Rol: Storage File Data SMB Share Contributor (Para que el grupo pueda leer/escribir perfiles FSLogix en el Storage)
resource smbContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, avdGroupId, 'StorageFileDataSmbShareContributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb')
    principalId: avdGroupId
    principalType: 'Group'
  }
}
