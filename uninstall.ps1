#Requires -RunAsAdministrator

# Supress warnings
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param()

$RekcodInstallationPath = [System.Environment]::GetEnvironmentVariable('REKCOD')
$RekcodProfile = "${RekcodInstallationPath}\profile"

Write-Host 'We are sorry to see you go but allow us to leave your machine as clean as before rekcod.' -ForegroundColor Yellow

# Remove powershell module for docker
Uninstall-Module -Name dockeraccesshelper -Force

# Remove docker contexts
docker context rm win -f
docker context rm lin -f

# Stop docker before uninstall
Stop-Service docker

# Unregister dockerd service
dockerd --unregister-service

# Unregister WSL distribution
Write-Host 'Removing WSL...' -ForegroundColor Yellow
wsl --unregister rekcod-wsl

# Remove powershell profile
Write-Host "Removing rekcod from your profile..." -ForegroundColor Yellow
New-Item -Type File -Path $PROFILE -Force
Get-Content "${RekcodProfile}\old-profile.ps1" >> $PROFILE

# Get PATH variable
Write-Host 'Cleaning environment variables...' -ForegroundColor Yellow
$path = [System.Environment]::GetEnvironmentVariable(
    'PATH',
    'Machine'
)

# Remove unwanted elements
$path = ($path.Split(';') | Where-Object { $_ -ne "${RekcodInstallationPath}\docker" }) -join ';'

# Set it
[System.Environment]::SetEnvironmentVariable(
    'PATH',
    $path,
    'Machine'
)

# Remove REKCOD env variable
[Environment]::SetEnvironmentVariable("REKCOD", $null ,"Machine")

# Remove installation folder
Write-Host 'Removing rekcod folder...' -ForegroundColor Yellow
Start-Job -Name uninstalling-rekcod -ScriptBlock{Start-Sleep 5; Remove-Item (Get-Item $RekcodInstallationPath) -Recurse -Force}

Write-Host 'Rekcod has been uninstalled. See you soon :)' -ForegroundColor Yellow
