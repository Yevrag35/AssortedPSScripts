Function Combine-Data()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [object[]] $ReferenceObjects,

        [Parameter(Mandatory=$true)]
        [object[]] $UnionWith,

        [Parameter(Mandatory=$true)]
        [Alias("Property")]
        [string] $JoinOnProperty
    )

    foreach ($ro in $ReferenceObjects)
    {
        $roProps = $ro.psobject.Properties
        $roVal = $roProps[$JoinOnProperty].Value
        foreach ($uwo in $UnionWith)
        {
            $uwoProps = $uwo.psobject.Properties
            $uwoPropMem = $uwoProps[$JoinOnProperty]
            if ($uwoPropMem.Value.Equals($roVal))
            {
                foreach ($uwoProp in $uwoProps.Where({$_.Name -notin $roProps.Name}))
                {
                    $ro.psobject.Members.Add($uwoProp)
                }
            }
        }
    }
}

# TEST
<#
$pso1 = [pscustomobject]@{
    Prop1 = 1
    Prop2 = "what"
    Prop3 = @{ Solar = "Eclipse" }
}
$pso12 = [pscustomobject]@{
    Prop1 = 3
    Prop2 = "who"
    Prop3 = @{ Just = "A skitty" }
}
$pso2 = [pscustomobject]@{
    Prop1 = 2
    Prop2 = "what"
    Prop7 = @{
        Who = "Cares?"
        I = "Don't"
    }
    Prop8 = "More", "Information", "Needed"
}
$pso3 = [pscustomobject]@{
    Prop1 = 2
    Prop2 = "who"
    Prop7 = @{
        Who = "Cares?"
        I = "Don't"
    }
    Prop8 = "More", "Information", "Needed"
}
Combine-Data -ReferenceObjects @($pso1, $pso12) -UnionWith @($pso2, $pso3) -JoinOnProperty "Prop2"
#>

Function Join-PSObjects()
{
    <#
        .EXAMPLE
            $pso1 = [pscustomobject]@{ hey = "there" }
            $pso2 = [pscustomobject]@{ yo = "dawg" }
            Join-PSObjects -AddTo ([ref]$pso1) -UnionWith $pso2

        .NOTES
            about_Ref - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_ref
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param
    (
        [Parameter(Mandatory=$true, Position = 0)]
        [ValidateScript({
            # 'AddTo' MUST BE a reference to a [pscustomobject]
            $_.Value -is [pscustomobject]
        })]
        [ref] $AddTo,

        [Parameter(Mandatory=$true)]
        [ValidateScript({
            # UnionWith should only contain individual [pscustomobject] instances
            # and cannot contain other objects of other types.
            $false -notin $(foreach ($o in $_) { $o -is [pscustomobject]})
        })]
        [object[]] $UnionWith
    )

    [string[]] $memberNames = $AddTo.Value.psobject.Properties.Name
    foreach ($pso in $UnionWith)
    {
        foreach ($prop in $pso.psobject.Properties.Where({$_.Name -cnotin $memberNames}))
        {
            $AddTo.Value.psobject.Members.Add((New-Object psnoteproperty -ArgumentList $prop.Name, $prop.Value))
        }
    }
}

Function Join-Hashtables()
{
    <#
        .EXAMPLE
            $hash1 = @{ hey = "there" }
            $hash2 = @{ yo = "dawg" }
            Join-Hashtables -JoinTo ([ref]$hash1) -UnionWith $hash2

        .NOTES
            about_Ref - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_ref
    #>
    [CmdletBinding(PositionalBinding = $false)]
    param
    (
        [Parameter(Mandatory=$true, Position = 0)]
        [ValidateScript({
            # 'JoinTo' MUST BE a reference to a [hashtable].
            $_.Value -is [hashtable]
        })]
        [ref] $JoinTo,

        [Parameter(Mandatory=$true)]
        [ValidateScript({
            # UnionWith should only contain individual [hashtable] objects and
            # cannot contain other objects of other types.
            $false -notin $(foreach ($t in $_) { $t -is [hashtable] })
        })]
        [object[]] $UnionWith
    )
    foreach ($union in $UnionWith)
    {
        foreach ($de in $union.GetEnumerator())
        {
            if (-not $JoinTo.Value.ContainsKey($de.Key))
            {
                $JoinTo.Value.Add($de.Key, $de.Value)
            }
        }
    }
}
