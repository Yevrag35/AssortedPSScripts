[CmdletBinding()]
param
(
    [parameter(Mandatory=$true, ParameterSetName='AddValues')]
    [switch] $AddChange,

    [parameter(Mandatory=$true, ParameterSetName='RemoveValues')]
    [switch] $Remove,

    [parameter(Mandatory=$true, ParameterSetName='AddValues')]
    [ValidateSet("1024", "1432", "2048", "4096", "6120", "8192", "9216", "10240", "12288", "16384")]
    [int] $BlockSize,

    [parameter(Mandatory=$true, ParameterSetName='AddValues')]
    [ValidateRange(1,16)]
    [int] $WindowSize
)

$server = "SCCM.yevrag35.com";

try
{
    $regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $server);
    $dpKey = $regKey.OpenSubKey("SOFTWARE\Microsoft\SMS\DP", $true);
    if ($PSBoundParameters.ContainsKey("AddChange"))
    {
        $dpKey.SetValue("RamDiskTFTPBlockSize", $BlockSize, [Microsoft.Win32.RegistryValueKind]::DWord);
        $dpKey.SetValue("RamDiskTFTPWindowSize", $WindowSize, [Microsoft.Win32.RegistryValueKind]::DWord);
    }
    elseif ($PSBoundParameters.ContainsKey("Remove"))
    {
        $dpKey.DeleteValue("RamDiskTFTPBlockSize", $false);
        $dpKey.DeleteValue("RamDiskTFTPWindowSize", $false);
    }
    Get-Service -Name wdsserver -ComputerName $server | Restart-Service -Verbose;
}
catch
{
    Write-Host $_.Exception.Message -f Red;
}
finally
{
    $dpKey.Close();
    $dpKey.Dispose();
    $regKey.Close();
    $regKey.Dispose();
}