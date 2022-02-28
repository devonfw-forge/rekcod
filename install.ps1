#Requires -RunAsAdministrator

# Supress warnings
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param()

##############################
#          VARIABLES         #
##############################

#region variables

$script:rekcodInstallationPath = "C:\rekcod"
$script:rekcodProfile = ""
$script:rekcodDistroUrl = "https://github.com/GuilleAmutio/rekcod/releases/download/v0.1.1-alpha/rekcod-wsl.tar"
$script:answer = "N"
$script:tmpPath = ""
$script:restartRequired = $false
$script:dockerPackageUrl = "https://download.docker.com/win/static/stable/x86_64/docker-20.10.8.zip"
$script:dockerComposePackageUrl = "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Windows-x86_64.exe"

#endregion

##############################
#            MENU            #
##############################

#region usermenu

function Menu()
{
Write-Host @"
Welcome to rekcod installation wizard!
rekcod is a tool developed to guide the installation of docker for Windows and Linux container.
This tool uses a WSL distribution based on Ubuntu-20.04 and the binary of Docker for Windows.
"@ -ForegroundColor Blue
    do {
        Write-Host 'The default installation path is '$script:rekcodInstallationPath'' -ForegroundColor Magenta
        $script:answer = Read-Host -Prompt 'Would you like to change it? Default is no (Y/N)'

        if($script:answer -ne "Y" -and $script:answer -ne "N" ) {
            Write-Host 'Please, choose yes (Y) or no (N)' -ForegroundColor Yellow
        }
        elseif($script:answer -eq "Y") {
            do {
                Write-Host 'Write the absolute path for rekcod installation. The path MUST exists.' -ForegroundColor Magenta
                $script:tmpPath = Read-Host -Prompt 'Please, select where rekcod will be installed'

                Write-Host 'Rekcod will be installed in '$script:tmpPath'' -ForegroundColor Magenta
                $script:answer = Read-Host -Prompt 'Is this correct? (Y/N)'

                if($script:answer -ne "Y" -and $script:answer -ne "N" ) {
                    Write-Host 'Please, choose yes (Y) or no (N)'
                }
                elseif($script:answer -eq "Y") {
                    if (-not (Test-Path $script:tmpPath)) {
                        Write-Host 'The path indicated does not exist. Please, select a valid one.' -ForegroundColor Red
                        $script:answer = "N"
                    }
                    else {
                        $script:rekcodInstallationPath = $script:tmpPath + "/rekcod"
                        Write-Host 'Path is valid. Rekcod will be installed at '$script:rekcodInstallationPath'' -ForegroundColor Green
                    }
                }
            } while ($script:answer -ne "Y")
        }
    } while ($script:answer -ne "Y" -and $script:answer -ne "N")

    if (-not (Test-Path $script:rekcodInstallationPath)){
        mkdir $script:rekcodInstallationPath
    }

    # Set installation folder as an env variable
    [Environment]::SetEnvironmentVariable("REKCOD", "${script:rekcodInstallationPath}", [System.EnvironmentVariableTarget]::Machine)

    # Set the path to the profile
    $script:rekcodProfile = "${script:rekcodInstallationPath}\profile"
}

#endregion

##############################
#           WINDOWS          #
##############################

#region windows

function EnableContainerFeature
{
    $containerExists = Get-WindowsOptionalFeature -Online -FeatureName Containers
            
    if($containerExists.State -eq 'Enabled')
    {
        Write-Verbose "Containers feature is already installed. Skipping the install."
        return
    }else {
        Write-Verbose "Installing Containers feature..."
        Enable-WindowsOptionalFeature -NoRestart -Online -FeatureName Containers -All
        $script:restartRequired = $true            
    }
}

function EnableHyperVFeature
{
    $hyperVExists = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V

    if($hyperVExists.State -eq 'Enabled')
    {
        Write-Verbose "HyperV feature is already installed. Skipping the install."
        return
    }else {
        Write-Verbose "Installing Hyper-V feature..."
        Enable-WindowsOptionalFeature -NoRestart -Online -FeatureName Microsoft-Hyper-V -All
        $script:restartRequired = $true            
    }
}

function EnableWSLFeature
{
    $wslExists = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

    if($wslExists.State -eq 'Enabled')
    {
        Write-Verbose "HyperV feature is already installed. Skipping the install."
        return
    }else {
        Write-Verbose "Installing WSL feature..."
        Enable-WindowsOptionalFeature -NoRestart -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All
        $script:restartRequired = $true            
    }
}

function InstallDockerAccessHelperModule
{
    if (Get-Module -ListAvailable -Name dockeraccesshelper) {
        Write-Host "Module already exists. Skipping the install."
        Import-Module dockeraccesshelper
    } 
    else {
        Install-Module -Name dockeraccesshelper -Force
        Import-Module dockeraccesshelper
    }
}

function EnableFeaturesAndModule
{
    EnableContainerFeature
    EnableHyperVFeature
    EnableWSLFeature
    InstallDockerAccessHelperModule
}

function InstallDockerCli
{
    Write-Host 'Installing Docker for Windows...' -ForegroundColor Blue
    Invoke-WebRequest $script:dockerPackageUrl -OutFile "docker.zip"
    Expand-Archive docker.zip -DestinationPath $script:rekcodInstallationPath
    Remove-Item docker.zip
    [Environment]::SetEnvironmentVariable("Path", "$($env:path);$script:rekcodInstallationPath\docker", [System.EnvironmentVariableTarget]::Machine)
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    dockerd --register-service

    ## docker-compose
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest $script:dockerComposePackageUrl -UseBasicParsing -OutFile $script:rekcodInstallationPath\docker\docker-compose.exe

    Write-Host 'Docker for Windows was installed successfully.' -ForegroundColor Green
}

#endregion

##############################
#             WSL            #
##############################

#region wsl

function ImportWslDistro()
{
    Write-Host 'Installing WSL distro for Linux containers...' -ForegroundColor Blue

    ## Download rekcod distro
    mkdir ${script:rekcodInstallationPath}\tools
    Invoke-WebRequest $script:rekcodDistroUrl -Outfile "${script:rekcodInstallationPath}\tools\rekcod-wsl.tar"

    ## Import WSL distro
    wsl --import rekcod-wsl $script:rekcodInstallationPath ${script:rekcodInstallationPath}\tools\rekcod-wsl.tar
    wsl --set-version rekcod-wsl 2
}

function CopyFiles()
{
    Copy-Item ./profile/ $script:rekcodInstallationPath -Recurse
    Copy-Item ./wsl-scripts/ $script:rekcodInstallationPath -Recurse
    Copy-Item ./pwsh-scripts/ $script:rekcodInstallationPath -Recurse
    Copy-Item uninstall.ps1 $script:rekcodInstallationPath
    Copy-Item rekcod-start.ps1 $script:rekcodInstallationPath
    Copy-Item rekcod-stop.ps1 $script:rekcodInstallationPath
    Copy-Item rekcod-switch.ps1 $script:rekcodInstallationPath
}

function ConfigureWslDistro()
{
    ## Call wsl-install.sh script from inside the WSl distro
    Write-Host 'Installing WSL distro...' -ForegroundColor Yellow
    wsl -d rekcod-wsl --exec ./wsl-scripts/wsl-install.sh

    ## Call wsl-systemd.sh script from inside the WSl distro
    Write-Host 'Enabling systemd...' -ForegroundColor Yellow
    wsl -d rekcod-wsl --exec ./wsl-scripts/wsl-systemd.sh

    ## Restart WSL distro to start using systemd
    wsl -t rekcod-wsl

    ## Call wsl-expose.sh script from inside the WSL distro
    Write-Host 'Creating service to expose Docker...' -ForegroundColor Yellow
    wsl -d rekcod-wsl --exec ./wsl-scripts/wsl-expose.sh

    ## Call wsl-service.sh script from inside the WSL distro
    Write-Host 'Enabling service to expose Docker...' -ForegroundColor Yellow
    wsl -d rekcod-wsl --exec ./wsl-scripts/wsl-service.sh

    ## Call wsl-docker.sh script from inside the WSl distro
    Write-Host 'Installing Docker in WSL...' -ForegroundColor Yellow
    wsl -d rekcod-wsl --exec ./wsl-scripts/wsl-docker.sh

    Write-Host 'WSL distro with Docker was installed successfully.' -ForegroundColor Green
    wsl -t rekcod-wsl
}

#endregion

##############################
#        Configuration       #
##############################

#region configuration

function CreatePowershellProfile()
{
    ## Check if a Microsoft profile exist
    if (!(Test-Path -Path $PROFILE))
    {
        New-Item -Type File -Path $PROFILE -Force
    }

    ## Copy the content of the profile into a temporary profile
    Copy-Item $PROFILE "$script:rekcodProfile\old-profile.ps1"

    ## Add the rekcod profile
    Write-Host "" >> $PROFILE
    Get-Content "${script:rekcodProfile}\rekcod-profile.ps1" >> $PROFILE

    ## Load the new profile
    . $PROFILE

    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function CreateDockerContexts()
{
    $winContextExists = $false
    $linContextExists = $false
    $contextsList = docker context ls | ConvertFrom-String

    for($i=1; $i -le $contextsList.Count; $i++)
    {
        if($contextsList[$i].P1 -eq 'lin')
        {
            $linContextExists = $true
        }elseif ($contextsList[$i].P1 -eq 'win') {
            $winContextExists = $true
        }
    }

    if(-Not($linContextExists))
    {
        docker context create lin --docker host=tcp://127.0.0.1:2375
    }
    if(-Not($winContextExists))
    {
        docker context create win --docker host=npipe:////./pipe/docker_engine
    }
    
    docker context use win
}

function FinishInstallation()
{
    if ($script:restartRequired ) {
        Write-Host 'Rekcod installation has finished.' -ForegroundColor Green
        Write-Warning "A restart is required to enable the windows features. Please restart your machine."
        $user_input = Read-Host -Prompt "Would you like to restart now ? (Type 'Y' for 'Yes' or 'N' for no)"
        if ($user_input -eq 'Y')
        {
            Restart-Computer
        }else {
            Write-Host "Press any key to close window..."
        }
    }else {
        Write-Host 'Rekcod installation has finished.' -ForegroundColor Green
    }
}
#endregion

#region main

Menu
EnableFeaturesAndModule
InstallDockerCli
ImportWslDistro
CopyFiles
ConfigureWslDistro
CreatePowershellProfile
CreateDockerContexts
FinishInstallation

#endregion