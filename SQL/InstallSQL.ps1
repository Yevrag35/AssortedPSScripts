[CmdletBinding(PositionalBinding=$false)]
param
(
    [parameter(Mandatory=$false,Position=0)]
    [ValidateSet('SQL','SQLEngine','Replication','FullText','DQ','PolyBase','AdvancedAnalytics',
        'AS','RS','RS_SHP','RS_SHPWFE','DQC','IS','MDS','SQL_SHARED_MR')]
    [string[]] $InstallFeatures = 'SQLEngine'   # https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt#Feature
    ,
    [parameter(Mandatory)]
    [pscredential] $SQLEngineAccount
    ,
    [parameter(Mandatory)]
    [pscredential] $SQLAgentAccount
    ,
    [ValidateNotNullOrEmpty()]
    [string[]] $SQLAdmins = "$env:USERDOMAIN\Domain Admins"
    ,
    [ValidateScript({
        Test-Path -LiteralPath $_
    })]
    [string] $ConfigurationFile = ".\SQL2016Config.ini"
    ,
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $InstanceId = "MSSQLSERVER"
    ,
    [parameter(Mandatory=$false)]
    [string] $InstanceDirectory
)

Function ConvertFrom-SecureToPlain
{
	param 
	(
		[parameter(Mandatory=$true,Position=0,
			ValueFromPipeline=$true)]
		[System.Security.SecureString]$SecureString
	)
		# Create a "password pointer"
        $PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        # Get the plain text version of the password
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($PasswordPointer)
        # Free the pointer
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordPointer)
        return $plain
}

# Read Config File
$config = cat $ConfigurationFile

if (!$InstanceDirectory)
{
    $InstanceDirectory = "C:\Program Files\Microsoft SQL Server\MSSQL13.$InstanceId"
}
$newCfg=@()
foreach ($line in $config)
{
    # Replace config lines with parameter values
    if ($line -clike "FEATURES=*")
    {
        $newCfg += "FEATURES=$($InstallFeatures -join ',')"
    }
    elseif ($line -clike "SQLSVCACCOUNT=*")
    {
        $newCfg += "SQLSVCACCOUNT=`"$($SQLEngineAccount.UserName)`""
    }
    elseif ($line -clike "AGTSVCACCOUNT=*")
    {
        $newCfg += "AGTSVCACCOUNT=`"$($SQLAgentAccount.UserName)`""
    }
    elseif ($line -clike "SQLSYSADMINACCOUNTS=*")
    {
        $newCfg += "SQLSYSADMINACCOUNTS=`"$($SQLAdmins -join '" "')`""
    }
    else
    {
        if ($line -clike "INSTANCENAME=*")
        {
            $newCfg += "INSTANCENAME=`"$InstanceId`""
        }
        elseif ($line -clike "INSTANCEID=*")
        {
            $newCfg += "INSTANCEID=`"$InstanceId`""
        }
        elseif ($line -clike "INSTANCEDIR=*")
        {
            $newCfg += "INSTANCEDIR=`"$InstanceDirectory`""
        }
        else
        {
            $newCfg += $line
        }
    }
}
Clear-Content $ConfigurationFile -Force; Add-Content $ConfigurationFile -Value $newCfg -Force

& "D:\Setup.exe" /IACCEPTSQLSERVERLICENSETERMS /SQLSVCPASSWORD="$($SQLEngineAccount.Password | ConvertFrom-SecureToPlain)" /AGTSVCPASSWORD="$($SQLAgentAccount.Password | ConvertFrom-SecureToPlain)" /ConfigurationFile="$ConfigurationFile"