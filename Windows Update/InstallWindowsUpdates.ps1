#Requires -Version 4.0
[CmdletBinding()]
param
(
    [Parameter(Mandatory=$false)]
    [switch] $PassThru,

    [Parameter(Mandatory=$false, DontShow=$true)]
    [string] $EventLogName = "Update Automation"
)

#region FUNCTIONS
Function Private:Register-CustomEventSource([string]$Name)
{
    New-EventLog -LogName $Name -Source $Name
    $hash = @{
        LogName = $Name
        Source = $Name
    }
    $hash
}

Function Private:GetEventArgs([string]$Source)
{
    if (![System.Diagnostics.EventLog]::SourceExists($Source))
    {
        $eventArgs = Private:Register-CustomEventSource -Name $Source
    }
    else
    {
        $eventArgs = @{
            LogName = $Source
            Source = $Source
        }
    }
    $eventArgs
}

#endregion

$eArgs = Private:GetEventArgs -Source $EventLogName

$session = New-Object -ComObject 'Microsoft.Update.Session'
$searcher = $session.CreateUpdateSearcher()
$updates = $searcher.Search("IsInstalled=0").Updates
if ($updates.Count -eq 0)
{
    $noUpsMsg = "No updates were found that need to be installed."
    Write-Host $noUpsMsg -f Cyan
    Write-EventLog -Message $noUpsMsg -EntryType Information -EventId 10 @eArgs
    break
}


$needToDownload = New-Object -ComObject 'Microsoft.Update.UpdateColl'
$needToInstall = New-Object -ComObject 'Microsoft.Update.UpdateColl'
foreach ($up in $updates)
{
    if ($up.IsDownloaded -or $up.IsDownloaded -eq "True")
    {
        [void] $needToInstall.Add($up)
    }
    else
    {
        [void] $needToDownload.Add($up)
    }
}

if ($needToDownload.Count -gt 0)
{
    $downloader = $session.CreateUpdateDownloader()
    $downloader.Updates = $needToDownload
    $result = $downloader.Download()
    if ($result.ResultCode -ne 2)
    {
        $erMsg = "Updates could not be downloaded.  Result Code: {0} ({1})" -f $result.ResultCode, $result.Hresult
        Write-Host $erMsg -f Red
        Write-EventLog -Message $erMsg -EntryType Error -EventId 9989 @eArgs
        break
    }
    else
    {
        foreach ($dlUp in $downloader.Updates)
        {
            [void] $needToInstall.Add($dlUp)
        }
    }
    Start-Sleep -Seconds 2
}

if ($needToInstall.Count -gt 0)
{
    $installer = $session.CreateUpdateInstaller()
    $installer.Updates = $needToInstall

	$strs = New-Object -TypeName 'System.Text.StringBuilder' -ArgumentList ($needToInstall.Count + 1)
    [void] $strs.AppendLine("We will install the following updates:`n")

    $htmlObj = foreach ($up in $needToInstall)
    {
        New-Object PSObject -Property @{
            KBArticleID = $up.KBArticleIDs -join ', '
            'Update Title' = $up.Title
        };
    }
    [void] $strs.AppendLine(($htmlObj | Out-String))

	Write-EventLog -Message $strs.ToString() -EntryType "Information" -EventId 50 @eArgs
    Write-Host $strs.ToString() -f Yellow

    $installResult = $installer.Install();

    if ($installResult.ResultCode -ne 2)
    {
        $subLine = "FAILURE!";
        $eArgs.Message = "We were unable to install the updates!  Exit Code was {0} ({1})." -f $installResult.ResultCode, $installResult.Hresult
        $eArgs.EventId = 9999;
        $eArgs.EntryType = "Error";

        Write-Host "$subLine - $($eArgs.Message)" -f Red
    }
    else
    {
        $subLine = "SUCCESS!"
        $eArgs.Message = "Updates were installed successfully!";
        $eArgs.EventId = 100;
        $eArgs.EntryType = "Information";

        Write-Host "$subLine - $($eArgs.Message)" -f Green
    }
    Write-EventLog @eArgs;

    if ((Test-Path -Path "$PSScriptRoot\Get-PendingReboot.ps1" -PathType Leaf))
    {
        & "$PSScriptRoot\Get-PendingReboot.ps1"
    }
}