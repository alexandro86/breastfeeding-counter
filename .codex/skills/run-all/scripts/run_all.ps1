#requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Plan,
    [switch]$SkipInstall,
    [ValidateRange(10, 300)]
    [int]$DatabaseTimeoutSeconds = 60,
    [ValidateRange(10, 300)]
    [int]$ServiceTimeoutSeconds = 45
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Stage {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-DockerCommand {
    $command = Get-Command docker.exe -ErrorAction SilentlyContinue
    if (-not $command) {
        $command = Get-Command docker -ErrorAction SilentlyContinue
    }
    if ($command) {
        return $command
    }

    $candidatePaths = [System.Collections.Generic.List[string]]::new()
    if ($env:LOCALAPPDATA) {
        $candidatePaths.Add(
            (Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\resources\bin\docker.exe")
        )
    }
    if ($env:ProgramFiles) {
        $candidatePaths.Add(
            (Join-Path $env:ProgramFiles "Docker\Docker\resources\bin\docker.exe")
        )
    }

    foreach ($candidatePath in $candidatePaths) {
        if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
            return [pscustomobject]@{ Source = $candidatePath }
        }
    }

    return $null
}

function Get-NodeRuntime {
    param([Parameter(Mandatory)][string]$RepoRoot)

    $requiredVersion = (Get-Content -Raw -LiteralPath (Join-Path $RepoRoot ".nvmrc")).Trim()
    $candidatePaths = [System.Collections.Generic.List[string]]::new()

    if ($env:NVM_HOME) {
        $candidatePaths.Add((Join-Path $env:NVM_HOME "v$requiredVersion\node.exe"))
    }

    $nvmCommand = Get-Command nvm.exe -ErrorAction SilentlyContinue
    if ($nvmCommand) {
        $candidatePaths.Add(
            (Join-Path (Split-Path -Parent $nvmCommand.Source) "v$requiredVersion\node.exe")
        )
    }

    if ($env:LOCALAPPDATA) {
        $candidatePaths.Add((Join-Path $env:LOCALAPPDATA "nvm\v$requiredVersion\node.exe"))
    }

    $currentNode = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $currentNode) {
        $currentNode = Get-Command node -ErrorAction SilentlyContinue
    }
    if ($currentNode) {
        $candidatePaths.Add($currentNode.Source)
    }

    $usableFallback = $null
    foreach ($nodePath in ($candidatePaths | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $nodePath -PathType Leaf)) {
            continue
        }

        $actualText = (& $nodePath --version).Trim().TrimStart("v")
        $actualVersion = [version]$actualText
        $nodeDirectory = Split-Path -Parent $nodePath
        $npmCli = Join-Path $nodeDirectory "node_modules\npm\bin\npm-cli.js"

        if (-not (Test-Path -LiteralPath $npmCli -PathType Leaf)) {
            continue
        }

        $runtime = [pscustomobject]@{
            Node = $nodePath
            NpmCli = $npmCli
            Version = $actualText
        }

        if ($actualText -eq $requiredVersion) {
            return $runtime
        }

        if ($actualVersion.Major -eq 22 -and $actualVersion -ge [version]"22.12.0") {
            $usableFallback = $runtime
        }
    }

    if ($usableFallback) {
        Write-Warning (
            "No se encontro Node $requiredVersion exacto; se usara Node " +
            "$($usableFallback.Version), compatible con el proyecto."
        )
        return $usableFallback
    }

    throw (
        "Se requiere Node 22.12 o posterior de la rama 22. " +
        "Instala la version indicada en .nvmrc antes de continuar."
    )
}

function Get-Fingerprint {
    param([Parameter(Mandatory)][string[]]$Paths)

    return (($Paths | ForEach-Object {
        (Get-FileHash -Algorithm SHA256 -LiteralPath $_).Hash
    }) -join ":")
}

function Test-Endpoint {
    param([Parameter(Mandatory)][string]$Url)

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 300
    }
    catch {
        return $false
    }
}

function Wait-Database {
    param(
        [Parameter(Mandatory)][string]$DockerPath,
        [Parameter(Mandatory)][string]$ComposePath,
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][int]$TimeoutSeconds
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    $attempt = 0
    while ([DateTime]::UtcNow -lt $deadline) {
        $attempt++
        & $DockerPath compose --project-directory $RepoRoot -f $ComposePath `
            exec -T db pg_isready -U breastfeeding -d breastfeeding *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "PostgreSQL esta listo."
            return
        }

        if ($attempt % 5 -eq 0) {
            Write-Host "Esperando PostgreSQL..."
        }
        Start-Sleep -Seconds 2
    }

    throw "PostgreSQL no estuvo listo despues de $TimeoutSeconds segundos."
}

function ConvertTo-CommandLineArgument {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)

    if ($Value -notmatch '[\s"]') {
        return $Value
    }

    return '"' + $Value.Replace('"', '\"') + '"'
}

function Get-ManagedProcess {
    param(
        [Parameter(Mandatory)][string]$MetadataPath,
        [Parameter(Mandatory)][string]$ExpectedExecutable
    )

    if (-not (Test-Path -LiteralPath $MetadataPath -PathType Leaf)) {
        return $null
    }

    try {
        $metadata = Get-Content -Raw -LiteralPath $MetadataPath | ConvertFrom-Json
        $process = Get-Process -Id ([int]$metadata.pid) -ErrorAction Stop
        $sameExecutable = $process.Path -eq $ExpectedExecutable
        $recordedStart = [DateTime]::Parse($metadata.started_at).ToUniversalTime()
        $actualStart = $process.StartTime.ToUniversalTime()
        $sameStart = [Math]::Abs(($actualStart - $recordedStart).TotalSeconds) -lt 5

        if ($sameExecutable -and $sameStart) {
            return $process
        }
    }
    catch {
        # Los metadatos obsoletos se retiran debajo.
    }

    Remove-Item -LiteralPath $MetadataPath -Force
    return $null
}

function Start-ManagedProcess {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$RunDirectory
    )

    $metadataPath = Join-Path $RunDirectory "$Name.process.json"
    $existing = Get-ManagedProcess `
        -MetadataPath $metadataPath `
        -ExpectedExecutable $Executable
    if ($existing) {
        Write-Host "$Name ya esta ejecutandose con PID $($existing.Id)."
        return $existing
    }

    $stdoutPath = Join-Path $RunDirectory "$Name.out.log"
    $stderrPath = Join-Path $RunDirectory "$Name.err.log"
    $argumentLine = ($Arguments | ForEach-Object {
        ConvertTo-CommandLineArgument -Value $_
    }) -join " "

    $process = Start-Process `
        -FilePath $Executable `
        -ArgumentList $argumentLine `
        -WorkingDirectory $WorkingDirectory `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath `
        -PassThru

    [pscustomobject]@{
        pid = $process.Id
        executable = $process.Path
        started_at = $process.StartTime.ToUniversalTime().ToString("o")
    } | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath $metadataPath

    Write-Host "$Name iniciado con PID $($process.Id)."
    return $process
}

function Wait-Service {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][int]$TimeoutSeconds,
        [Parameter(Mandatory)][string]$RunDirectory
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        $Process.Refresh()
        if ($Process.HasExited) {
            throw (
                "$Name termino antes de estar listo. Revisa " +
                "$(Join-Path $RunDirectory "$Name.err.log")."
            )
        }

        if (Test-Endpoint -Url $Url) {
            Write-Host "$Name esta disponible en $Url"
            return
        }
        Start-Sleep -Seconds 1
    }

    throw "$Name no respondio en $Url despues de $TimeoutSeconds segundos."
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\..\.."))
$clientRoot = Join-Path $repoRoot "client"
$serverRoot = Join-Path $repoRoot "server"
$composePath = Join-Path $repoRoot "compose.yaml"
$requiredFiles = @(
    (Join-Path $clientRoot "package-lock.json"),
    (Join-Path $serverRoot "pyproject.toml"),
    (Join-Path $serverRoot "requirements-dev.lock"),
    $composePath
)

foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "No se encontro el archivo requerido: $requiredFile"
    }
}

$nodeRuntime = Get-NodeRuntime -RepoRoot $repoRoot
$venvPython = Join-Path $serverRoot ".venv\Scripts\python.exe"
$dockerCommand = Get-DockerCommand

if ($Plan) {
    Write-Stage "Plan de ejecucion"
    Write-Host "Repositorio: $repoRoot"
    Write-Host "Node: $($nodeRuntime.Node) (v$($nodeRuntime.Version))"
    Write-Host "Python virtual: $venvPython"
    Write-Host "Docker: $(if ($dockerCommand) { $dockerCommand.Source } else { 'NO DISPONIBLE' })"
    Write-Host "1. Verificar/instalar dependencias."
    Write-Host "2. Ejecutar docker compose up -d db."
    Write-Host "3. Esperar PostgreSQL y aplicar Flask-Migrate."
    Write-Host "4. Iniciar API en http://127.0.0.1:5000."
    Write-Host "5. Iniciar cliente en http://127.0.0.1:5173."
    return
}

if (-not $dockerCommand) {
    throw "Docker no esta disponible. Instala o inicia Docker Desktop y vuelve a ejecutar la skill."
}

$dockerDirectory = Split-Path -Parent $dockerCommand.Source
$env:Path = "$dockerDirectory$([IO.Path]::PathSeparator)$env:Path"

& $dockerCommand.Source compose version *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Docker Compose no esta disponible."
}

$nodeDirectory = Split-Path -Parent $nodeRuntime.Node
$env:Path = "$nodeDirectory$([IO.Path]::PathSeparator)$env:Path"
$runDirectory = Join-Path $repoRoot ".run"
New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null

if (-not (Test-Path -LiteralPath (Join-Path $clientRoot ".env"))) {
    Copy-Item `
        -LiteralPath (Join-Path $clientRoot ".env.example") `
        -Destination (Join-Path $clientRoot ".env")
}
if (-not (Test-Path -LiteralPath (Join-Path $serverRoot ".env"))) {
    Copy-Item `
        -LiteralPath (Join-Path $serverRoot ".env.example") `
        -Destination (Join-Path $serverRoot ".env")
}

if (-not $SkipInstall) {
    Write-Stage "Verificando dependencias del cliente"
    $clientFingerprint = Get-Fingerprint -Paths @(
        (Join-Path $clientRoot "package.json"),
        (Join-Path $clientRoot "package-lock.json")
    )
    $clientSentinel = Join-Path $runDirectory "client-deps.sha256"
    $clientModules = Join-Path $clientRoot "node_modules"
    $clientCurrent = if (Test-Path -LiteralPath $clientSentinel) {
        (Get-Content -Raw -LiteralPath $clientSentinel).Trim()
    } else {
        ""
    }

    if (
        -not (Test-Path -LiteralPath $clientModules -PathType Container) -or
        $clientCurrent -ne $clientFingerprint
    ) {
        Push-Location $clientRoot
        try {
            & $nodeRuntime.Node $nodeRuntime.NpmCli ci
            if ($LASTEXITCODE -ne 0) {
                throw "npm ci fallo."
            }
        }
        finally {
            Pop-Location
        }
        Set-Content -Encoding ASCII -LiteralPath $clientSentinel -Value $clientFingerprint
    }
    else {
        Write-Host "Las dependencias del cliente estan actualizadas."
    }

    Write-Stage "Verificando dependencias del servidor"
    $serverFingerprint = Get-Fingerprint -Paths @(
        (Join-Path $serverRoot "pyproject.toml"),
        (Join-Path $serverRoot "requirements-dev.lock")
    )
    $serverSentinel = Join-Path $runDirectory "server-deps.sha256"
    $serverCurrent = if (Test-Path -LiteralPath $serverSentinel) {
        (Get-Content -Raw -LiteralPath $serverSentinel).Trim()
    } else {
        ""
    }

    if (-not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
        $systemPython = Get-Command python.exe -ErrorAction SilentlyContinue
        if (-not $systemPython) {
            $systemPython = Get-Command python -ErrorAction SilentlyContinue
        }
        if (-not $systemPython) {
            throw "Python no esta disponible para crear server/.venv."
        }

        & $systemPython.Source -m venv (Join-Path $serverRoot ".venv")
        if ($LASTEXITCODE -ne 0) {
            throw "No se pudo crear server/.venv."
        }
        $serverCurrent = ""
    }

    if ($serverCurrent -ne $serverFingerprint) {
        & $venvPython -m pip install --requirement (Join-Path $serverRoot "requirements-dev.lock")
        if ($LASTEXITCODE -ne 0) {
            throw "La instalacion de dependencias Python fallo."
        }
        & $venvPython -m pip install `
            --no-build-isolation `
            --no-deps `
            --editable $serverRoot
        if ($LASTEXITCODE -ne 0) {
            throw "La instalacion editable del servidor fallo."
        }
        Set-Content -Encoding ASCII -LiteralPath $serverSentinel -Value $serverFingerprint
    }
    else {
        Write-Host "Las dependencias del servidor estan actualizadas."
    }
}
elseif (-not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
    throw "-SkipInstall requiere que server/.venv ya exista."
}

Write-Stage "Levantando PostgreSQL"
& $dockerCommand.Source compose `
    --project-directory $repoRoot `
    -f $composePath `
    up -d db
if ($LASTEXITCODE -ne 0) {
    throw "docker compose up fallo."
}
Wait-Database `
    -DockerPath $dockerCommand.Source `
    -ComposePath $composePath `
    -RepoRoot $repoRoot `
    -TimeoutSeconds $DatabaseTimeoutSeconds

Write-Stage "Aplicando migraciones"
Push-Location $serverRoot
try {
    & $venvPython -m flask --app wsgi db upgrade
    if ($LASTEXITCODE -ne 0) {
        throw "Flask-Migrate no pudo aplicar las migraciones."
    }
}
finally {
    Pop-Location
}

Write-Stage "Iniciando API"
$apiUrl = "http://127.0.0.1:5000/api/v1/health/live"
$serverMetadata = Join-Path $runDirectory "server.process.json"
$serverProcess = Get-ManagedProcess `
    -MetadataPath $serverMetadata `
    -ExpectedExecutable $venvPython
if (-not $serverProcess -and (Test-Endpoint -Url $apiUrl)) {
    Write-Warning "Ya existe una API no gestionada respondiendo en el puerto 5000."
}
else {
    $serverProcess = Start-ManagedProcess `
        -Name "server" `
        -Executable $venvPython `
        -Arguments @(
            "-m", "flask", "--app", "wsgi", "--debug",
            "run", "--no-reload", "--host", "127.0.0.1", "--port", "5000"
        ) `
        -WorkingDirectory $serverRoot `
        -RunDirectory $runDirectory
    Wait-Service `
        -Name "server" `
        -Process $serverProcess `
        -Url $apiUrl `
        -TimeoutSeconds $ServiceTimeoutSeconds `
        -RunDirectory $runDirectory
}

Write-Stage "Iniciando cliente"
$clientUrl = "http://127.0.0.1:5173"
$viteCli = Join-Path $clientRoot "node_modules\vite\bin\vite.js"
if (-not (Test-Path -LiteralPath $viteCli -PathType Leaf)) {
    throw "No se encontro Vite. Ejecuta nuevamente sin -SkipInstall."
}
$clientMetadata = Join-Path $runDirectory "client.process.json"
$clientProcess = Get-ManagedProcess `
    -MetadataPath $clientMetadata `
    -ExpectedExecutable $nodeRuntime.Node
if (-not $clientProcess -and (Test-Endpoint -Url $clientUrl)) {
    Write-Warning "Ya existe un cliente no gestionado respondiendo en el puerto 5173."
}
else {
    $clientProcess = Start-ManagedProcess `
        -Name "client" `
        -Executable $nodeRuntime.Node `
        -Arguments @(
            $viteCli, "--host", "127.0.0.1", "--port", "5173", "--strictPort"
        ) `
        -WorkingDirectory $clientRoot `
        -RunDirectory $runDirectory
    Wait-Service `
        -Name "client" `
        -Process $clientProcess `
        -Url $clientUrl `
        -TimeoutSeconds $ServiceTimeoutSeconds `
        -RunDirectory $runDirectory
}

Write-Stage "Entorno local listo"
Write-Host "Cliente: $clientUrl"
Write-Host "API: http://127.0.0.1:5000/api/v1"
Write-Host "PostgreSQL: localhost:5432"
Write-Host "Logs: $runDirectory"
Write-Host (
    "Para detenerlo: powershell -NoProfile -ExecutionPolicy Bypass -File " +
    ".codex/skills/run-all/scripts/stop_all.ps1"
)
