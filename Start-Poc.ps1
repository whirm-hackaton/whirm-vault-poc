param(
    [string]$Ip = '172.20.10.2',
    [switch]$CloseSignups,
    [switch]$TrustWindows
)
$ErrorActionPreference = 'Stop'
$pocAddress = [System.Net.IPAddress]::Parse($Ip)
$pocBytes = $pocAddress.GetAddressBytes()
if ($pocAddress.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork -or
    -not ($pocBytes[0] -eq 10 -or
          ($pocBytes[0] -eq 172 -and $pocBytes[1] -ge 16 -and $pocBytes[1] -le 31) -or
          ($pocBytes[0] -eq 192 -and $pocBytes[1] -eq 168))) {
    throw 'Utiliser une adresse IPv4 privee du PC sur le reseau de demonstration.'
}
Push-Location $PSScriptRoot
try {
    & docker info --format '{{.ServerVersion}}'
    if ($LASTEXITCODE -ne 0) { throw 'Le moteur Docker doit etre demarre avant le lancement.' }
    $pocSignups = if ($CloseSignups) { 'false' } else { 'true' }
    @("POC_IP=$Ip", "SIGNUPS_ALLOWED=$pocSignups") | Set-Content -LiteralPath '.env' -Encoding utf8
    & docker compose config --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Configuration Compose invalide.' }
    & docker compose up -d
    if ($LASTEXITCODE -ne 0) { throw 'Le lancement a echoue. Consulter docker compose logs --tail 50.' }
    & docker compose exec -T https caddy validate --config /etc/caddy/Caddyfile
    if ($LASTEXITCODE -ne 0) { throw 'Configuration HTTPS invalide.' }
    & docker compose exec -T https caddy reload --config /etc/caddy/Caddyfile
    if ($LASTEXITCODE -ne 0) { throw 'Rechargement HTTPS impossible.' }
    $pocReady = $false
    for ($pocAttempt = 0; $pocAttempt -lt 30; $pocAttempt++) {
        try {
            # Temporary bootstrap probe only. Normal use must validate HTTPS.
            $pocResponse = Invoke-WebRequest -Uri "https://${Ip}:8443/alive" -SkipCertificateCheck -NoProxy -TimeoutSec 3
            if ($pocResponse.StatusCode -eq 200) { $pocReady = $true; break }
        } catch { }
        Start-Sleep -Seconds 1
    }
    if (-not $pocReady) { throw 'Le service ne repond pas encore. Consulter les journaux des deux conteneurs.' }
    New-Item -ItemType Directory -Path 'public-certificates' -Force | Out-Null
    $pocProxyId = (& docker compose ps -q https).Trim()
    & docker cp "${pocProxyId}:/data/caddy/pki/authorities/local/root.crt" 'public-certificates/root.crt'
    if ($LASTEXITCODE -ne 0) { throw 'Export du certificat public impossible.' }
    $pocCertificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
        (Join-Path $PSScriptRoot 'public-certificates/root.crt'))
    [System.IO.File]::WriteAllBytes(
        (Join-Path $PSScriptRoot 'public-certificates/bank-poc-root.cer'),
        $pocCertificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
    if ($TrustWindows) {
        Import-Certificate -FilePath 'public-certificates/bank-poc-root.cer' -CertStoreLocation 'Cert:\CurrentUser\Root' | Out-Null
        $pocVerified = Invoke-WebRequest -Uri "https://${Ip}:8443/alive" -NoProxy -TimeoutSec 5
        if ($pocVerified.StatusCode -ne 200) { throw 'La verification HTTPS Windows a echoue.' }
    }
    Write-Host "Coffre : https://${Ip}:8443"
    Write-Host "Certificat public iPhone : http://${Ip}:8081/bank-poc-root.cer"
    Write-Host "Empreinte SHA-256 du certificat : $((Get-FileHash -LiteralPath 'public-certificates/bank-poc-root.cer' -Algorithm SHA256).Hash)"
    Write-Host 'Chaque membre cree son compte et choisit son propre mot de passe maitre.'
} finally {
    Pop-Location
}
