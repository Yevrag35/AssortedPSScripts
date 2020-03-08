[CmdletBinding()]
[OutputType([psobject])]
param
(
    [parameter(Mandatory=$false,Position=0)]
    [string[]] $ComputerName = $env:COMPUTERNAME,

    [parameter(Mandatory=$false,Position=1)]
#    [SupportsWildcards()]
    [string[]] $SearchFor
)

$UninstallKeys = @(
    "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
    "SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
)

$list = New-Object 'System.Collections.Generic.List[object]';

foreach ($computer in $ComputerName)
{

    if ($computer -eq "localhost" -or $computer -eq ".")
    {
        $computer = $env:COMPUTERNAME
    }

    try
    {
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $computer);
    }
    catch [System.IO.IOException]
    {
        Write-Error "$($computer): Could not open the registry remotely!  Is the `"RemoteRegistry`" running`?"
    }
    if ($null -eq $Reg)
    {
        Write-Error "$($computer): Could not open the registry remotely!  Is the `"RemoteRegistry`" running`?"
    }

    foreach($UninstallKey in $UninstallKeys)
    {
        #Drill down into the Uninstall key using the OpenSubKey Method
        $Regkey = $Reg.OpenSubKey($UninstallKey)

        #Retrieve an array of string that contain all the subkey names
        $Subkeys = $Regkey.GetSubKeyNames()

        foreach($key in $subkeys)
        {

            $thisKey = $UninstallKey+"\\"+$key
            $thisSubKey= $reg.OpenSubKey($thisKey)
            $displayName = $thisSubKey.GetValue("DisplayName")
            $publisher = $thisSubKey.GetValue("Publisher")

            if (-not [string]::IsNullOrEmpty($displayName) -or -not [string]::IsNullOrEmpty($publisher))
            {
                $pso = New-Object -TypeName 'psobject' -Property @{
                    ComputerName = $computer
                    DisplayName = $displayName
                    DisplayVersion = $thisSubKey.GetValue("DisplayVersion")
                    InstallLocation = $thisSubKey.GetValue("InstallLocation")
                    Publisher = $publisher
                    UninstallString = $thisSubKey.GetValue("UninstallString")
                }
                $list.Add($pso)
            }
        }
    }
}

if ($PSBoundParameters.ContainsKey("SearchFor"))
{
    $patterns = New-Object -TypeName 'System.Collections.Generic.List[System.Management.Automation.WildcardPattern]' -ArgumentList $SearchFor.Count
    foreach ($appToSearch in $SearchFor)
    {
        $patterns.Add((New-Object -TypeName "System.Management.Automation.WildcardPattern" -ArgumentList $appToSearch, "IgnoreCase"))
    }
    foreach ($app in $list)
    {
        if (@($patterns | ForEach-Object { $_.IsMatch($app.DisplayName)}) -contains $true)
        {
            $app
        }
    }
}
else
{
    $list
}