# Save variable
$RekcodInstallationPath = [System.Environment]::GetEnvironmentVariable('REKCOD')

# Set 'rekcod-start' as an alias for the start.ps1 script
Set-Alias rekcod-start $RekcodInstallationPath\rekcod-start.ps1

# Set 'rekcod-off' as an alias for the stop.ps1 script
Set-Alias rekcod-shutdown $RekcodInstallationPath\rekcod-stop.ps1

# Set 'rekcod-off' as an alias for the stop.ps1 script
Set-Alias rekcod-switch $RekcodInstallationPath\rekcod-switch.ps1

# Set 'rekcod' as an alias for 'docker'
Set-Alias rekcod docker

# Set 'rekcod-compose' as and alias for 'docker-compose'
Set-Alias rekcod-compose docker-compose