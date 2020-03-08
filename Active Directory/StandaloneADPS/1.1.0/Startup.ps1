param
(
    [parameter(Mandatory=$false, Position=0)]
	[AllowEmptyString()]
    [string] $DC,

    [parameter(Mandatory = $false, Position=1)]
	[AllowNull()]
    [pscredential] $Creds = $null
)

if ($PSBoundParameters.ContainsKey("DC") -and $PSBoundParameters.ContainsKey("Creds"))
{
    $global:PSDefaultParameterValues += @{
        '*-AD*:Server' = $DC
        '*-AD*:Credential' =  $Creds
    };
}