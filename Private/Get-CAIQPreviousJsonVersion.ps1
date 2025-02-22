Function Get-CAIQPreviousJsonVersion {
    param (
        [Parameter(Mandatory=$true)]
        [string]$PolicyPath,
        [Parameter(Mandatory=$true)]
        [string]$PolicyId
    )
    $all_versions = Get-ChildItem -Path $policyPath -Filter "$($policyId)_Version_*.json" | ForEach-Object {
        $version = $_.Name -replace "$($policyId)_Version_(.+)\.json", '$1'
        $output = [ordered]@{}
        $output["Fullname"] = $_.Fullname
        $output["Version"] = $version
        $output["SortableVersion"] = if ($version -eq "Initial") { 
            [DateTime]::MinValue 
        
        } Else { 
            [DateTime]::ParseExact($version, "MM_dd_yyyy_HH_mm_ss", $null) 
        
        }
        [PSCustomObject]$output
        } | Sort-Object SortableVersion -Descending
    $all_versions

}

            

    
