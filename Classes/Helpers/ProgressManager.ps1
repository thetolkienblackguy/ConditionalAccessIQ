class ProgressManager {
    <#
        .SYNOPSIS
        A class to manage the writing of progress to the console.

        .PARAMETER Total
        The total number of items to process.

        .PARAMETER Iteration
        The current iteration number.
        
    #>
    [int]$Total
    [int]$Iteration = 0
    [int]$PercentComplete = 0


    ProgressManager([int]$total, [int]$iteration = 0) {
        $this.Total = $total
        $this.Iteration = $iteration

    }
    [void]WriteProgress($item) {
        $this.Iteration++
        $this.PercentComplete = ($this.Iteration / $this.Total) * 100
        $write_progress_params = @{}
        $write_progress_params["Activity"] = "Processing $item"
        $write_progress_params["Status"] = "Processing $($this.Iteration) of $($this.Total)"
        $write_progress_params["PercentComplete"] = $this.PercentComplete
        Try {
            Write-Progress @write_progress_params

        } Catch {
            Throw "An error occurred while writing progress to the console.  The error message was: $_"

        }

    }

    [void]ResetProgress() {
        $this.Iteration = 0
        $this.PercentComplete = 0

    }
}