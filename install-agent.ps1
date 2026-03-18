if ([string]::IsNullOrWhiteSpace($Token)) { throw "Missing Token" }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$p = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
Get-ItemProperty $p -EA Ignore | ?{ $_.DisplayName -match "Virtual Desktop Agent" -or $_.DisplayName -match "Remote Desktop Services Infrastructure" } | %{
    $u=$_.UninstallString -replace 'msiexec.exe /I','' -replace 'msiexec.exe /i',''
    if ($u) { Start-Process "msiexec.exe" -ArgumentList "/x $u /qn /norestart" -Wait -NoNewWindow }
}
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -Recurse -Force -EA Ignore
Start-Sleep -s 5

$urls = @{
    "A" = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
    "B" = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"
}
function DL($u, $o) {
    for ($i=1; $i -le 3; $i++) {
        try { Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing; return } catch { Start-Sleep -s 5 }
    }
}
DL $urls["A"] "C:\Windows\Temp\a.msi"
DL $urls["B"] "C:\Windows\Temp\b.msi"

function Inst($m, $a) {
    for ($i=1; $i -le 10; $i++) {
        $proc = Start-Process msiexec.exe -ArgumentList "/i `"$m`" $a" -Wait -PassThru
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) { return }
        Start-Sleep -s 10
    }
}
Inst "C:\Windows\Temp\a.msi" "/qn /norestart REGISTRATIONTOKEN=$Token"
Inst "C:\Windows\Temp\b.msi" "/qn /norestart"

$r="HKLM:\SOFTWARE\FSLogix\Profiles"
if (-not (Test-Path $r)) { New-Item -Path $r -Force | Out-Null }
Set-ItemProperty $r "Enabled" -Type DWord -Value 1
Set-ItemProperty $r "VHDLocations" -Type String -Value $FileSharePath

$k="HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
Set-ItemProperty $k "CloudKerberosTicketRetrievalEnabled" -Type DWord -Value 1