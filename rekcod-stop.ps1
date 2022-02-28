# Supress warnings
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param()

# Variable
$RekcodInstallationPath = [System.Environment]::GetEnvironmentVariable('REKCOD')

# Stop Docker
Write-Host "Stopping Docker..."

# Call script
powershell -File ${RekcodInstallationPath}\pwsh-scripts\pwsh-stop.ps1

# Information
Write-Host "Docker is stopped. See you soon!" -ForegroundColor Green
