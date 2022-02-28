# Supress warnings
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param()

# Switch context

$currentContextObject = $(docker context inspect) | ConvertFrom-Json

if ( $currentContextObject.Name -eq "lin" ){
    Write-Host 'Switching to Windows containers...' -ForegroundColor Yellow
    docker context use win
    Write-Host 'Docker is set to use Windows containers by default!' -ForegroundColor Green
}

if ( $currentContextObject.Name -eq "win" ){
    Write-Host 'Switching to Linux containers...' -ForegroundColor Yellow
    docker context use lin
    Write-Host 'Docker is set to use Linux containers by default!' -ForegroundColor Green
}