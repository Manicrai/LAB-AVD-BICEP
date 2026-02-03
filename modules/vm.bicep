param location string
param vnetName string = 'vnet-avd-lab-01'
param subnetName string = 'snet-avd-hosts'
param vmName string = 'vm-avd-0' // Nombre de la máquina
param adminUsername string = 'adminUser' // Usuario local de emergencia
@secure()
param adminPassword string // ¡Contraseña segura!

// 1. Referencia a la red existente (para saber dónde conectar la VM)
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  parent: vnet
  name: subnetName
}

// 2. Interfaz de Red (NIC)
resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}

// 3. La Máquina Virtual (Session Host)
resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s' // Económica (2 vCPU, 4GB RAM) ~ $0.04/hora. ¡Apágala cuando no la uses!
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-11'
        sku: 'win11-22h2-avd' // Versión especial Multi-sesión para AVD
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS' // Balance entre costo y rendimiento
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    licenseType: 'Windows_Client' // Importante para ahorrar costos de licencia (Hybrid Benefit)
  }
}

// 4. Extensión: Unir a Azure AD (Entra ID)
resource aadLoginExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: vm
  name: 'AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}
