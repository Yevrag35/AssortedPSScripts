Function Connect-ToAD()
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true, Position=0)]
        [string] $DCServer,

        [parameter(Mandatory=$false)]
        [AllowNull()]
        [pscredential] $Credential = $null
    )

    if ([string]::IsNullOrEmpty($env:USERDNSDOMAIN) -and ($null -eq $Credential -or $null -eq $Credential.Password))
    {
        Write-Warning "You are not connected to an AD Domain!";
        Write-Host "Please enter credentials to use in the remote domain.";
        $Credential = Get-Credential;
        if ($null -eq $Credential.Password)
        {
            return;
        }
        $global:PSDefaultParameterValues += @{
            '*-AD*:Credential' = $Credential
        };
    }
    elseif ($PSBoundParameters.ContainsKey("Credential"))
    {
        $global:PSDefaultParameterValues += @{
            '*-AD*:Credential' = $Credential
        };
    }

    Write-Verbose "Setting `$PSDefaultParameterValues with specified values for all AD cmdlets...";
    $global:PSDefaultParameterValues += @{
        '*-AD*:Server' = $DCServer
    };
    Write-Verbose "`$PSDefaultParameterValues set!";
    Write-Debug "`$PSDefaultParameterValues: `n$($global:PSDefaultParameterValues | Out-String)";
}

Function Disconnect-FromAD()
{
    [CmdletBinding()]
    param()

    Write-Debug "Current `$PSDefaultParameterValues: `n$($global:PSDefaultParameterValues | Out-String)";

    $private:removeThese = @('*-AD*:Server', '*-AD*:Credential');

    [string[]]$keys = $global:PSDefaultParameterValues.Keys
    for ($i = $keys.Length - 1; $i -ge 0; $i--)
    {
        $key = $keys[$i];
        if ($private:removeThese.Contains($key))
        {
            Write-Verbose "Removing '$key' from `$PSDefaultParameterValues...";
            $global:PSDefaultParameterValues.Remove($key);
        }
    }

    Write-Debug "`$PSDefaultParameterValues: `n$($global:PSDefaultParameterValues | Out-String)";
}