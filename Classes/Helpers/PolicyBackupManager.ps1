class PolicyBackupManager {

    # Private field to store the root path for policy backups on disk.
    hidden [string]$RootPath

    # Constructor for the class.
    PolicyBackupManager([string]$outputPath) {
        # Set the root path for policy backups
        $this.RootPath = Join-Path -Path $outputPath -ChildPath "Policies"

        # If the root backup directory does not exist, create it
        if (!(Test-Path -Path $this.RootPath)) {
            [void](New-Item -Path $this.RootPath -ItemType Directory -Force)
        
        }
    }

    # Method to get the specific file system path for a given policy ID.
    hidden [string]GetPolicyPath([string]$policyId) {
        # Return the full path for a policy's backup directory
        return Join-Path -Path $this.RootPath -ChildPath $policyId
    
    }

    # Public method to save a version of a policy to the file system.
    [void]SaveBackup([object]$policy, [string]$version) {
        # Get the path for this specific policy's backups
        $policy_path = $this.GetPolicyPath($policy.Id)

        # If the policy-specific directory does not exist, create it
        if (!(Test-Path -Path $policy_path)) {
            [void](New-Item -Path $policy_path -ItemType Directory)
        
        }

        # Construct the file name for this version
        $file_name = "$($policy.Id)_Version_$($version).json"
        $full_path = Join-Path -Path $policy_path -ChildPath $file_name

        # Convert the policy object to JSON and save it to the specified path
        $policy | ConvertTo-Json -Depth 10 | Out-File -FilePath $full_path -Force
    
    }
}