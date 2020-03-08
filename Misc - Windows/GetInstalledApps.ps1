[CmdletBinding()]
[OutputType([psobject])]
param
(
    [parameter(Mandatory=$false,Position=0)]
    [string] $ComputerName = "localhost",
    
    [parameter(Mandatory=$false,Position=1)]
    [SupportsWildcards()]
    [string[]] $SearchFor
)

$UninstallKeys = @( 
    "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall", 
    "SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
)

$list = New-Object 'System.Collections.Generic.List[psobject]';

foreach($UninstallKey in $UninstallKeys) {

    #Create an instance of the Registry Object and open the HKLM base key
    if ($ComputerName -eq "$env:COMPUTERNAME" -or $ComputerName -eq "localhost" -or $ComputerName -eq ".")
    {
        $Reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', [Microsoft.Win32.RegistryView]::Default);
    }
    else
    {
        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $ComputerName);
        if ($null -eq $Reg)
        {
            throw "Could not open the remote machine's registry!  Is the `"RemoteRegistry`" running`?"
        }
    }

    #Drill down into the Uninstall key using the OpenSubKey Method
    $Regkey = $Reg.OpenSubKey($UninstallKey)

    #Retrieve an array of string that contain all the subkey names
    $Subkeys = $Regkey.GetSubKeyNames() 

    foreach($key in $subkeys) 
    {

        $thisKey=$UninstallKey+"\\"+$key
        $thisSubKey=$reg.OpenSubKey($thisKey) 

        $list.Add((New-Object PSObject -Property @{

            ComputerName = $Computername
            DisplayName = $thisSubKey.GetValue("DisplayName")
            DisplayVersion = $thisSubKey.GetValue("DisplayVersion")
            InstallLocation = $thisSubKey.GetValue("InstallLocation")
            Publisher = $thisSubKey.GetValue("Publisher")
            UninstallString = $thisSubKey.GetValue("UninstallString")
        }));
    }
}
if ($PSBoundParameters.ContainsKey("SearchFor"))
{
    foreach ($appToSearch in @($SearchFor))
    {
        $wildcardSearch = [System.Management.Automation.WildcardPattern]::Get(
            $appToSearch, [System.Management.Automation.WildcardOptions]::IgnoreCase
        );
        foreach ($app in $($list.ToArray() | ?{![string]::IsNullOrEmpty($_.DisplayName)}))
        {
            if ($wildcardSearch.IsMatch($app.DisplayName))
            {
                Write-Output $app;
            }
        }
    }
}
else
{
    Write-Output $list.ToArray();
}