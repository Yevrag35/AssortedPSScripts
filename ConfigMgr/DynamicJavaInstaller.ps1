<#
    .SYNOPSIS
        A PowerShell script for the Java Runtime Environment offline installer.

    .DESCRIPTION
        Place the offline jre EXE installer in this folder.  No editing of this script is necessary when switching
        version of Java (as long as the installer is in .EXE form).
#>
#Requires -Version 2.0
[CmdletBinding()]
param ()

$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition;
Write-Verbose "Current Directory: $curDir";

$javaExe = Get-ChildItem -Path $curDir -Include jre*.exe -Recurse | Select -ExpandProperty PSPath | Convert-Path;
if ([string]::IsNullOrEmpty($javaExe))
{
	Write-Warning "No Java installer was found in the current directory!";
}
else
{
	Write-Verbose "Java Installer: $javaExe";
}

$installArgs = @("INSTALL_SILENT=Enable", "AUTO_UPDATE=Disable", "WEB_ANALYTICS=Disable", "EULA=Disable", "REBOOT=Disable",
    "NOSTARTMENU=Enable", "REMOVEOUTOFDATEJRES=0");
	
Write-Verbose "Install Arguments: `n$($installArgs | Out-String)";

Write-Verbose "Starting installation...";
### For v2.0 compatibility...
$startInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
	FileName = $javaExe
	Arguments = $installArgs
	CreateNoWindow = $true
	UseShellExecute = $false
};
$process = New-Object System.Diagnostics.Process -Property @{
	StartInfo = $startInfo
};

### Start the Installation
$process.Start();			# <== This will output "True".

Write-Verbose "The script will now wait for 5 minutes for installer to finish...";
### We will now wait for 5 minutes for the installer to finish.
### After 5 minutes elapses, the script will exit with code '101'.
$i = 0; while ((!$process.HasExited) -and ($i -lt 300))
{
	Start-Sleep -Seconds 1;
	$i++;
}
if ($i -ge 300)
{
	Write-Warning "The timeout period has elapsed.  Considering the install a failure!";
	exit 101;
}
else
{
	Write-Verbose "The java installer exited with a $($process.ExitCode) exit code.";
	exit $process.ExitCode;
}