param location string
param storageAccountName string = 'stavd${uniqueString(resourceGroup().id)}' 
param fileShareName string = 'fslogix-profiles'

// 1. La Cuenta de Almacenamiento
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS' // Mantenemos costos bajos. En Prod usaríamos Premium_LRS
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false // Seguridad: Nunca expongas perfiles a internet
  }
}

// 2. El Servicio de Archivos (Hijo de la cuenta)
resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2021-09-01' = {
  parent: storageAccount
  name: 'default'
}

// 3. El File Share (La carpeta compartida real)
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = {
  parent: fileService
  name: fileShareName
  properties: {
    shareQuota: 5 // Limitepara controlar costos
  }
}

// Outputs para usar después
output storageAccountName string = storageAccount.name
output fileSharePath string = '\\\\${storageAccount.name}.file.${environment().suffixes.storage}\\${fileShareName}'
