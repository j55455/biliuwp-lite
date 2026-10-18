# 预构建脚本：检查并更新 ShakaPlayer WebPlayer 资源
param()

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $scriptDir) {
    $scriptDir = $PSScriptRoot
}

$assetsPath = Join-Path -Path $scriptDir -ChildPath "Assets/ShakaPlayer"
$versionFile = Join-Path -Path $assetsPath -ChildPath "version.json"

# 本地已存在资源，直接退出
if (Test-Path $versionFile) {
    Write-Host "WebPlayer assets already exist. Skipping download."
    exit 0
}

if (-not (Test-Path $assetsPath)) {
    New-Item -ItemType Directory -Path $assetsPath -Force | Out-Null
}

try {
    $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/ywmoyue/BiliLite-WebPlayer/releases/latest" -Headers @{ "Accept" = "application/vnd.github.v3+json" }
    $asset = $releaseInfo.assets | Where-Object { $_.name -like "WebPlayer-*.zip" } | Select-Object -First 1
    if ($asset) {
        $tempZip = Join-Path $env:TEMP "WebPlayer-latest.zip"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip -UseBasicParsing
        Expand-Archive -Path $tempZip -DestinationPath $assetsPath -Force
        $ver = @{ tag = $releaseInfo.tag_name; commit = $releaseInfo.target_commitish } | ConvertTo-Json
        $ver | Set-Content $versionFile
    }
} catch {
    Write-Warning "Failed to fetch WebPlayer: $_"
    exit 0
}
