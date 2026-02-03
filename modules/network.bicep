// Parámetros: Lo que este módulo necesita saber para funcionar
param location string
param vnetName string = 'vnet-avd-prod-01'
param vnetAddressPrefix string = '10.0.0.0/16'
param subnetName string = 'snet-avd-hosts'
param subnetPrefix string = '10.0.1.0/24'

// Recurso: La Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          // Nota: Aquí en el futuro agregaremos NSGs (Seguridad)
        }
      }
    ]
  }
}
// Outputs: Lo que este módulo "devuelve" al archivo principal
output vnetId string = vnet.id
output subnetId string = vnet.properties.subnets[0].id
