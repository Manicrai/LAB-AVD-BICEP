param(
    [string]$ResourceGroupName = "rg-avd-lab-01",
    [string]$Location = "eastus",
    [string]$AdminPassword = "TuSuperPasswordSeguro123!"
)

# 1. Asegurar el grupo de recursos
Write-Host "Verificando Grupo de Recursos..." -ForegroundColor Cyan
az group create --name $ResourceGroupName --location $Location | Out-Null

# 2. Desplegar solo la Infraestructura (Sin la VM)
Write-Host "Desplegando Infraestructura (Red, Storage y AVD Backplane)..." -ForegroundColor Cyan
az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file main.bicep `
    --parameters vmPassword=$AdminPassword deployVm=false

# 3. Generar y Obtener el Token válido por 24 horas usando CLI directamente (Para evadir el bug de ARM/Bicep)
Write-Host "Preparando herramientas de AVD en tu ordenador..." -ForegroundColor Cyan
az config set extension.use_dynamic_install=yes_without_prompt
az extension add --name desktopvirtualization --upgrade 2>$null

Write-Host "Generando Token para la Máquina Virtual..." -ForegroundColor Cyan
$expTime = (Get-Date).ToUniversalTime().AddHours(24).ToString("yyyy-MM-ddTHH:mm:ssZ")

# Capturamos la respuesta entera en JSON directamente a PowerShell para evitar bugs de formato
$jsonString = az desktopvirtualization hostpool update `
    --resource-group $ResourceGroupName `
    --name "hp-avd-lab-01" `
    --registration-info expiration-time=$expTime registration-token-operation="Update" `
    -o json 2>$null

$hostPoolObj = $jsonString | ConvertFrom-Json
$token = $hostPoolObj.registrationInfo.token

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "ERROR: No se pudo generar el token." -ForegroundColor Red
    exit 1
}

# 4. Desplegar la VM pasándole el token real
Write-Host "Desplegando Máquina Virtual e inyectando Token ($($token.Substring(0, 5))...)..." -ForegroundColor Cyan
az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file main.bicep `
    --parameters vmPassword=$AdminPassword deployVm=true hostPoolToken=$token

Write-Host "¡Despliegue Cero-Toques Finalizado con Éxito!" -ForegroundColor Green
