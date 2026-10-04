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

# Follow the releases/latest redirect instead of calling the GitHub API, whose
# anonymous rate limit is easy to hit from shared campus or office networks.
$latest = Invoke-WebRequest -UseBasicParsing -Method Head "https://github.com/$repo/releases/latest"
$latestUri = if ($latest.BaseResponse.ResponseUri) {
    $latest.BaseResponse.ResponseUri.AbsoluteUri          # Windows PowerShell 5.1
} else {
    $latest.BaseResponse.RequestMessage.RequestUri.AbsoluteUri  # PowerShell 7
}
$tag = $latestUri.TrimEnd('/').Split('/')[-1]
if (-not $tag.StartsWith('cosci-')) {
    throw "Could not find the latest cosci release at https://github.com/$repo/releases."
}
$version = $tag.Substring('cosci-'.Length).Replace('.', '')
$archiveName = "cosci-$version-x86_64-windows.zip"
$downloadBase = "https://github.com/$repo/releases/download/$tag"

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cosci-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $zip = Join-Path $tmp $archiveName
    Write-Host "Downloading $archiveName"
    try {
        Invoke-WebRequest -UseBasicParsing "$downloadBase/$archiveName" -OutFile $zip
    } catch {
        throw "Release $tag has no package for x86_64 Windows."
    }
    Invoke-WebRequest -UseBasicParsing "$downloadBase/$archiveName.sha256" -OutFile "$zip.sha256"
    $expected = ((Get-Content "$zip.sha256" -Raw).Trim() -split '\s+')[0]
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $expected) {
        throw 'Checksum verification failed; nothing was installed.'
    }
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    $package = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like 'cosci-*' } | Select-Object -First 1
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    # A running cosci.exe (for example during `cosci update`) cannot be
    # overwritten but can be renamed, so move existing programs aside first.
    Get-ChildItem $package.FullName -Recurse -Filter '*.exe' | ForEach-Object {
        $target = Join-Path $installDir $_.FullName.Substring($package.FullName.Length).TrimStart('\')
        if (Test-Path $target) {
            $old = "$target.old"
            Remove-Item $old -Force -ErrorAction SilentlyContinue
            if (Test-Path $old) {
                # An older copy is still running; set this one aside under a fresh name.
                $old = "$target.$([guid]::NewGuid()).old"
            }
            Rename-Item $target (Split-Path $old -Leaf)
        }
    }
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
Write-Host 'cosci mirrors conversations to the cosci lab WebDAV server. To turn this off, add'
Write-Host '  [transcript_cloud]'
Write-Host '  provider = "off"'
Write-Host "to $env:USERPROFILE\.cosci\config.toml."
