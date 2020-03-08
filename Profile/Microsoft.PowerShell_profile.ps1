$window=$host.UI.RawUI
$window.BackgroundColor="Black"
$myWinID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myPrinID = New-Object System.Security.Principal.WindowsPrincipal($myWinID)
$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
if ($myPrinID.IsInRole($adm)) {
	$tit = "ELEVATED"
}
else {
	$tit = "STANDARD"
}
$window.WindowTitle = "Garvey's PowerShell - $tit"

Function ConvertFrom-SecureToPlain {
    param(
	[Parameter(Mandatory=$true,
		Position=0,
		ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true)]
	[alias("pass", "Password")]
	[System.Security.SecureString] $SecurePassword
	)
    # Create a "password pointer"
    $private:PasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    # Get the plain text version of the password
    $private:PlainTextPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto($private:PasswordPointer)
    # Free the pointer
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($private:PasswordPointer)
    # Return the plain text password
    $private:PlainTextPassword
}

# Create DISPLAYED Variables
$me = $env:USERPROFILE
if (![String]::IsNullOrEmpty($env:DESK))
{
	$desk = $env:DESK
}
else
{
	$desk = "$env:USERPROFILE\Desktop"
}
$pubdesk = "$pub\Desktop"
$p86 = ${env:ProgramFiles(x86)}
$p64 = $env:ProgramFiles
$psDir = "$p64\WindowsPowerShell\Modules"
$psWinDir = "$env:WINDIR\System32\WindowsPowerShell\v1.0"

Function Show-Profile()
{
	[CmdletBinding(PositionalBinding=$false)]
	[alias("shpf")]
	param
	(
		# [parameter(Mandatory=$false,Position=0)]
		# [ValidateSet('Notepad','Notepad++','VSCode','Console')]
		# [string] $OpenIn = "Notepad"
	)
	DynamicParam
	{
		if ($null -eq $global:TextEditors)
		{
			$global:TextEditors=@()
			# Notepad ++ -- Priority #1
			$32npp = "$p86\Notepad++\notepad++.exe"
			$64npp = "$p64\Notepad++\notepad++.exe"
			if (Test-Path $32npp)
			{
				$test = $32npp
			}
			elseif (Test-Path $64npp)
			{
				$test = $64npp
			}
			if ($null -ne $test)
			{
				$global:TextEditors += New-Object PSObject -Property @{
					Name = "Notepad++"
					Path = $test
					Priority = 1
				}
			}
			# Add Visual Studio Code...
			$vsCode = "$p64\Microsoft VS Code\Code.exe"
			if (Test-Path $vsCode)
			{
				$global:TextEditors += New-Object PSObject -Property @{
					Name = "VSCode"
					Path = $vsCode
					Priority = 2
				}
			}
			# Add Stupid Notepad...
			$global:TextEditors += New-Object psobject -Property @{
				Name = "Notepad"
				Path = "$env:WINDIR\System32\Notepad.exe"
				Priority = 3
			}
			# Add Stupid Console...
			$global:TextEditors += New-Object psobject -Property @{
				Name = "Console"
				Path = "Get-Content" # little trickery...
				Priority = 4
			}
		}
		$attName = "OpenIn"
		$editors = $global:TextEditors.Name
		$rtDict = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
		$attCol = New-Object 'System.Collections.ObjectModel.Collection[System.Attribute]'
		$pAtt = New-Object System.Management.Automation.ParameterAttribute -Property @{
			Mandatory = $false
			Position = 0
		}
		$attCol.Add($pAtt)
		$alias = New-Object System.Management.Automation.AliasAttribute("o", "oi")
		$attCol.Add($alias)
		$valSet = New-Object System.Management.Automation.ValidateSetAttribute($editors)
		$attCol.Add($valSet)
		$rtParam = New-Object System.Management.Automation.RuntimeDefinedParameter($attName, [string], $attCol)
		$rtDict.Add($attName, $rtParam)
		return $rtDict;
	}
	Begin
	{
		$chosen = $PSBoundParameters["OpenIn"]
		if ($null -eq $chosen)
		{
			# ...then go by priority
			$OpenIn = ($global:TextEditors | Sort Priority)[0]
		}
		else
		{
			$OpenIn = $global:TextEditors | ? Name -eq $chosen
		}
	}
	Process
	{
		if ($OpenIn.Path -like "*.exe")
		{
			Start-Process $OpenIn.Path -ArgumentList $profile
		}
		else
		{
			Invoke-Expression -Command "$($OpenIn.Path) `$profile"
		}
	}
	End
	{
		return
	}
}

# Put PowerShell Command Aliases below
New-Alias -Name "sel" -Value "Select-Object"
New-Alias -Name "help" -Value "Get-Help"
New-Alias -Name "esn" -Value "Enter-PSSession"
New-Alias -Name "no" -Value "New-Object"
New-Alias -Name "ch" -Value "choco"

Set-Location $desk
Clear-Host
Write ''