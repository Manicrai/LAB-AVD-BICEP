param(
    [string]$Token
)

# 1. Configuración de seguridad
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Enlaces Directos (FWLinks) - Más estables que los anteriores
$urls = @{
    "Agent"      = "https://go.microsoft.com/fwlink/?linkid=2084815"
    "Bootloader" = "https://go.microsoft.com/fwlink/?linkid=2084820"
}

# Función de descarga con reintentos
function Download-WithRetry {
    param ($Url, $Output)
    $maxRetries = 3
    $retryCount = 0
    $downloaded = $false

    while (-not $downloaded -and $retryCount -lt $maxRetries) {
        try {
            $retryCount++
            Write-Host "Intento $retryCount de $maxRetries para: $Output"
            # Usamos UserAgent para simular ser un navegador Edge
            Invoke-WebRequest -Uri $Url -OutFile $Output -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36 Edg/91.0.864.59"
            $downloaded = $true
            Write-Host "¡Descarga exitosa!" -ForegroundColor Green
        }
        catch {
            Write-Host "Fallo en intento $retryCount. Error: $_" -ForegroundColor Yellow
            Start-Sleep -Seconds 5 # Esperar 5 segundos antes de reintentar
        }
    }
    
    if (-not $downloaded) {
        Write-Host "ERROR CRÍTICO: No se pudo descargar el archivo tras $maxRetries intentos." -ForegroundColor Red
        Exit 1
    }
}

# 3. Ejecutar descargas
Download-WithRetry -Url $urls["Agent"] -Output "C:\Windows\Temp\agent.msi"
Download-WithRetry -Url $urls["Bootloader"] -Output "C:\Windows\Temp\bootloader.msi"

# 4. Instalación
Write-Host "Instalando Agente..."
$agentArgs = "/i C:\Windows\Temp\agent.msi /quiet RDInfraAgentRegistrationToken=$Token"
Start-Process -FilePath "msiexec.exe" -ArgumentList $agentArgs -Wait

Write-Host "Instalando Bootloader..."
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\Windows\Temp\bootloader.msi /quiet" -Wait

Write-Host "¡Proceso finalizado correctamente!" -ForegroundColor Cyan