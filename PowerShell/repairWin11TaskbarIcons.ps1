Get-AppxPackage Microsoft.Windows.ShellExperienceHost | foreach {Add-AppxPackage -register "$($_. InstallLocation)\appxmanifest.xml" -DisableDevelopmentMode}

Get-AppXPackage | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_. InstallLocation)\AppXManifest.xml"}