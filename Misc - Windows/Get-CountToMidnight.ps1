Function Get-CountToMidnight()
{
    [CmdletBinding(PositionalBinding=$false)]
    [OutputType([int])]
    param
    (
        [parameter(Mandatory=$false, Position = 0)]
        [ValidateSet("Seconds", "Minutes", "Milliseconds")]
        [string] $In = "Seconds"
    )
    $midnight = (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(1);
    $timeBetween = New-TimeSpan -Start $([datetime]::Now) -End $midnight;
    $timeIn = $timeBetween."Total$In";
    [int]$round = [math]::Round($timeIn, [System.MidpointRounding]::ToEven);
    Write-Output $round;
}