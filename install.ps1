# Installs the latest cosci release for x86_64 Windows.
#
#   irm https://raw.githubusercontent.com/harrysyz99/cosci/main/install.ps1 | iex
#
# COSCI_INSTALL_DIR (default %LOCALAPPDATA%\cosci) holds cosci.exe and its
# sandbox helpers; the folder is added to your user PATH.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$repo = 'harrysyz99/cosci'
$installDir = if ($env:COSCI_INSTALL_DIR) { $env:COSCI_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'cosci' }

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw "cosci for Windows supports x86_64 only (this machine: $env:PROCESSOR_ARCHITECTURE)."
}

$release = Invoke-RestMethod -UseBasicParsing "https://api.github.com/repos/$repo/releases/latest"
$asset = $release.assets | Where-Object { $_.name -like '*-x86_64-windows.zip' } | Select-Object -First 1
if (-not $asset) {
    throw "Could not find a cosci release for x86_64 Windows at https://github.com/$repo/releases."
}
$checksumAsset = $release.assets | Where-Object { $_.name -eq "$($asset.name).sha256" } | Select-Object -First 1

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cosci-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $zip = Join-Path $tmp $asset.name
    Write-Host "Downloading $($asset.name)"
    Invoke-WebRequest -UseBasicParsing $asset.browser_download_url -OutFile $zip
    Invoke-WebRequest -UseBasicParsing $checksumAsset.browser_download_url -OutFile "$zip.sha256"
    $expected = ((Get-Content "$zip.sha256" -Raw).Trim() -split '\s+')[0]
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $expected) {
        throw 'Checksum verification failed; nothing was installed.'
    }
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    $package = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like 'cosci-*' } | Select-Object -First 1
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    Copy-Item -Path (Join-Path $package.FullName '*') -Destination $installDir -Recurse -Force
} finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not (($userPath -split ';') -contains $installDir)) {
    $newPath = if ($userPath) { "$userPath;$installDir" } else { $installDir }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "Added $installDir to your user PATH. Open a new terminal to use cosci."
}
$version = & (Join-Path $installDir 'cosci.exe') --version
Write-Host "Installed $version in $installDir"
Write-Host 'Next: cosci login'
