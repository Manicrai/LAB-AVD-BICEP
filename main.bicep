targetScope = 'resourceGroup'

// --- PARÁMETROS GLOBALES ---
param location string = resourceGroup().location

// Aquí declaramos la contraseña para que el script la pida al iniciar
@secure()
param vmPassword string 

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
  }
}

// 4. Virtual Machine
module vmModule 'modules/vm.bicep' = {
  name: 'deployVM'
  params: {
    location: location
    // Ahora sí, pasamos el parámetro global al módulo
    adminPassword: vmPassword 
  }
}
