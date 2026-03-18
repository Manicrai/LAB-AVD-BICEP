param location string
param vnetName string = 'vnet-avd-lab-01'
param subnetName string = 'snet-avd-hosts'
param vmName string = 'vm-avd-0' // Nombre de la máquina
param adminUsername string = 'adminUser' // Usuario local de emergencia
@secure()
param adminPassword string // ¡Contraseña segura!
@secure()
param hostPoolToken string
param fileSharePath string
param currentTime string = utcNow('u')

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
  identity: {
    type: 'SystemAssigned'
  }
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

// 5. Instalar Agente y Configurar FSLogix
resource installAgentScript 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: vm
  name: 'InstallAVDAgentCSE'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    forceUpdateTag: currentTime
    protectedSettings: {
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -Command "$Token = \'${hostPoolToken}\'; $FileSharePath = \'${fileSharePath}\'; [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(\'${base64(loadTextContent('../install-agent.ps1'))}\')) | Invoke-Expression"'
    }
  }
  dependsOn: [
    aadLoginExtension
  ]
}

// 6. ¡Bonus Low-Cost! Auto-Apagado diario
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '19:00' // Hora a la que se apaga sola (formato 24h)
    }
    timeZoneId: 'SA Pacific Standard Time' // Zona horaria (Ajusta según tu país)
    targetResourceId: vm.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}
