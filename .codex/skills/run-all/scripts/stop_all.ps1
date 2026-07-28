#requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$KeepDatabase
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function Stop-ManagedProcess {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$MetadataPath
    )

    if (-not (Test-Path -LiteralPath $MetadataPath -PathType Leaf)) {
        Write-Host "$Name no tiene un proceso gestionado."
        return
    }

    try {
        $metadata = Get-Content -Raw -LiteralPath $MetadataPath | ConvertFrom-Json
        $process = Get-Process -Id ([int]$metadata.pid) -ErrorAction Stop
        $recordedStart = [DateTime]::Parse($metadata.started_at).ToUniversalTime()
        $actualStart = $process.StartTime.ToUniversalTime()
        $sameStart = [Math]::Abs(($actualStart - $recordedStart).TotalSeconds) -lt 5
        $sameExecutable = $process.Path -eq $metadata.executable

        if (-not ($sameStart -and $sameExecutable)) {
            Write-Warning "$Name tiene metadatos obsoletos; no se detendra otro proceso."
            return
        }

        Stop-Process -Id $process.Id -Force
        Write-Host "$Name detenido (PID $($process.Id))."
    }
    catch {
        Write-Host "$Name ya estaba detenido o sus metadatos no son validos."
    }
    finally {
        Remove-Item -LiteralPath $MetadataPath -Force -ErrorAction SilentlyContinue
    }
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\..\.."))
$runDirectory = Join-Path $repoRoot ".run"

Stop-ManagedProcess `
    -Name "client" `
    -MetadataPath (Join-Path $runDirectory "client.process.json")
Stop-ManagedProcess `
    -Name "server" `
    -MetadataPath (Join-Path $runDirectory "server.process.json")

if (-not $KeepDatabase) {
    $dockerCommand = Get-DockerCommand

    if ($dockerCommand) {
        $dockerDirectory = Split-Path -Parent $dockerCommand.Source
        $env:Path = "$dockerDirectory$([IO.Path]::PathSeparator)$env:Path"

        & $dockerCommand.Source compose `
            --project-directory $repoRoot `
            -f (Join-Path $repoRoot "compose.yaml") `
            stop db
        if ($LASTEXITCODE -ne 0) {
            throw "No se pudo detener PostgreSQL."
        }
        Write-Host "PostgreSQL detenido; el volumen de datos se conservo."
    }
    else {
        Write-Warning "Docker no esta disponible; no se pudo detener PostgreSQL."
    }
}
else {
    Write-Host "PostgreSQL continua ejecutandose por -KeepDatabase."
}

Write-Host "Los logs se conservan en $runDirectory."
