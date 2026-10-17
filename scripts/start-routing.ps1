$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$routingData = Join-Path $projectRoot '.routing'
$routingImage = if ($env:OSRM_IMAGE) { $env:OSRM_IMAGE } else { 'ghcr.io/project-osrm/osrm-backend:26.10.0-debian' }
function Invoke-DockerChecked {
    param([string[]]$Arguments)
    & docker @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Docker falhou (codigo $LASTEXITCODE). A preparacao foi interrompida; nenhum banco foi alterado." }
}
Invoke-DockerChecked -Arguments @('info', '--format', '{{.OSType}}')
New-Item -ItemType Directory -Force -Path $routingData | Out-Null
$ready = Join-Path $routingData 'ready-v1'
if (!(Test-Path $ready)) {
    Write-Host 'Primeira preparacao: download regional e processamento das rotas. Pode levar varios minutos.'
    # Normalize line endings in case Git checked out the helper with CRLF.
    $helper = Join-Path $PSScriptRoot 'prepare-routing-windows.sh'
    $normalized = [IO.File]::ReadAllText($helper).Replace("`r`n", "`n")
    [IO.File]::WriteAllText((Join-Path $routingData 'prepare-helper.sh'), $normalized, [Text.UTF8Encoding]::new($false))
    Invoke-DockerChecked -Arguments @('run', '--rm', '--mount', "type=bind,source=$projectRoot,target=/project", 'debian:bookworm-slim', 'bash', '/project/.routing/prepare-helper.sh')
    $mount = "type=bind,source=$routingData,target=/data"
    Invoke-DockerChecked -Arguments @('run', '--rm', '--mount', $mount, $routingImage, 'osrm-extract', '-t', '2', '-p', '/opt/car.lua', '/data/porto.osm.pbf')
    Invoke-DockerChecked -Arguments @('run', '--rm', '--mount', $mount, $routingImage, 'osrm-partition', '-t', '2', '/data/porto.osrm')
    Invoke-DockerChecked -Arguments @('run', '--rm', '--mount', $mount, $routingImage, 'osrm-customize', '-t', '2', '/data/porto.osrm')
    [IO.File]::WriteAllText($ready, 'ready')
}
$existing = & docker ps -a --filter 'name=^/porto-prime-routing$' --format '{{.Names}}'
if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel consultar os containers.' }
if ($existing -contains 'porto-prime-routing') {
    Invoke-DockerChecked -Arguments @('start', 'porto-prime-routing')
} else {
    Invoke-DockerChecked -Arguments @('run', '-d', '--name', 'porto-prime-routing', '--restart', 'unless-stopped', '-p', '127.0.0.1:5000:5000', '--mount', "type=bind,source=$routingData,target=/data,readonly", $routingImage, 'osrm-routed', '--algorithm', 'mld', '/data/porto.osrm')
}
for ($attempt = 0; $attempt -lt 60; $attempt++) {
    try {
        $result = Invoke-RestMethod -TimeoutSec 2 -Uri 'http://127.0.0.1:5000/nearest/v1/driving/-39.064,-16.449?number=1'
        if ($result.code -eq 'Ok') {
            Write-Host 'Rotas prontas em http://127.0.0.1:5000. Dados OpenStreetMap contributors - ODbL.'
            Write-Host 'Indices de ruas e estabelecimentos preparados. Reinicie o Nest se ele ja estava aberto.'
            exit 0
        }
    } catch { }
    Start-Sleep -Seconds 1
}
throw 'OSRM nao respondeu. Consulte: docker logs porto-prime-routing'
