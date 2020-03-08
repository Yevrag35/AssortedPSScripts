Function Format-FlashDrive {
    param (
        [parameter(Mandatory=$true,ParameterSetName='Check')]
        [switch]$ListDisks
        ,
        [parameter(Mandatory=$true,ParameterSetName='Run')]
        [validateRange(0,6)]
        [Int32]$Disk
        ,
        [string]$Label="Corsair32"
        ,
        [parameter(Mandatory=$true,ParameterSetName='Run')]
        [validateLength(1,1)]
        [string]$DriveLetter
        ,
        [switch]$IsWindowsBootable
        ,
        [switch]$IsLinuxBootable
    )
    $devs = gwmi Win32_DiskDrive
    if ($ListDisks) {
        $array = foreach($dev in $devs) {
            New-Object -TypeName PSObject -Property @{
                Index = $dev.Index
                'Drive Caption' = $dev.Caption
                'Size (in GB)' = ForEach-Object {[math]::Round(($dev.Size/1GB),2)}
            }
        }
        $array | Select Index,'Drive Caption','Size (in GB)' | Sort Index
    }
    if ($Disk -ge $devs.Count) {
        Write-Error "There is no disk that is numbered $Disk.  To find the list of acceptable values, re-run with the '-ListDisks' switch to display currently used drives." -Category InvalidData
    }
    else {
        $txt = New-Item -Path "C:\Admin" -Name "diskpart.txt" -Force
		$con = @()
		$con += 'select disk '+$Disk
		$con += 'clean'
		$con += 'create partition primary'
		if (($IsLinuxBootable) -or ($IsWindowsBootable)) {
			$con += 'active'
			if ($IsLinuxBootable) {
				$fs = "fat32"
			}
			else {
				$fs = "ntfs"
			}
		}
		else {
			$fs = "ntfs"
		}
		$con += 'format fs='+$fs+' label="'+$Label+'" quick'
		$con += 'assign letter='+$DriveLetter
		Add-Content -Path $txt -Value $con -Force
		$diskpart = "C:\Windows\System32\diskpart.exe"
		$diskargs = @('/s', 'C:\Admin\diskpart.txt')
		&cmd /c $diskpart $diskargs
		Remove-File "C:\Admin\diskpart.txt" -Force
	}
}