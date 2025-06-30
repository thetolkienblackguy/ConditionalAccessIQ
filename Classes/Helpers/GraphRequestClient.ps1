class GraphRequestClient {
    <#
        .SYNOPSIS
        This class is used to manage the graph request parameters.

        .DESCRIPTION
        This class is used to manage the graph request parameters.

        .PARAMETER GraphEndpoint
        The graph endpoint to use.

        .PARAMETER ApiVersion
        The API version to use.

        .PARAMETER GraphRequestParams
        The graph request parameters.

    #>
    [string]$GraphEndpoint
    [ValidateSet("Beta","v1.0")]
    [string]$ApiVersion = "v1.0"
    static [System.Collections.Generic.List[hashtable]]$ResponseCache = [System.Collections.Generic.List[hashtable]]::new()
    hidden [hashtable]$GraphRequestParams = @{}
    hidden [System.Collections.ArrayList]$BatchQueue = @()
    
    # Constructor
    GraphRequestClient() {
        # Initialize the current arguments
        $this.GraphRequestParams = @{}
        $this.SetGraphEndpoint()

    }

    #region Invoke Graph Requests
    # Method to invoke graph requests
    hidden [object[]]InvokeGraphRequest([string]$method, [string]$endpoint, [string]$filter, [string[]]$segments, [hashtable]$body, [hashtable]$queryParams) {
        # Build the full Graph query parameters
        $query_params = If ($method -eq "GET") {
            $this.BuildGraphQuery($filter, $queryParams)
        
        } Else {
            $null
        
        }
        # Build the request URI
        $uri = $this.BuildGraphUri($endpoint, $segments, $query_params, $false)
        
        # Set the Graph request parameters
        $options = @{}
        If ($method -eq "GET") {
            $options["Headers"] = @{}
            $options["Headers"]["ConsistencyLevel"] = "eventual"
        
        }

        # Set the body if it exists
        If ($body) {
            $options["Body"] = $body 
        
        }

        # Set the Graph request parameters
        $this.SetGraphRequestParams($uri, $method, $options)

        # Retrieve the final request parameters
        $params = $this.ShowGraphRequest()

        # Paginate and return results
        If ($method -eq "GET") {
            return $this.Paginate($params)
        
        } Else {
            # Build the cache key
            $cache_key = [GraphRequestClient]::BuildWriteCacheKey($method, $params.Uri, $body)

            # Execute the request and return results
            Try {
                $r = Invoke-MgGraphRequest @params
                $cache_table = @{}
                $cache_table[$cache_key] = $r
                [GraphRequestClient]::ResponseCache.Add($cache_table)
                return $r
            
            } Catch {
                Throw "Error executing $method request to $uri. Error: $_"
            
            }
        }
    }

    # Method to invoke a GET request to Microsoft Graph
    hidden [object[]]InvokeGraphGetRequest([string]$endpoint, [string[]]$segments, [string]$filter, [hashtable]$queryParams) {
        return $this.InvokeGraphRequest("GET", $endpoint, $filter, $segments, $null, $queryParams)
    
    }

    # Method to invoke a POST request to Microsoft Graph
    hidden [object[]]InvokeGraphPostRequest([string]$endpoint, [string[]]$segments, [hashtable]$body) {
        return $this.InvokeGraphRequest("POST", $endpoint, $null, $segments, $body, $null)
    }

    # Method to invoke a PATCH request to Microsoft Graph
    hidden [object[]]InvokeGraphPatchRequest([string]$endpoint, [string[]]$segments, [hashtable]$body) {
        return $this.InvokeGraphRequest("PATCH", $endpoint, $null, $segments, $body, $null)
    }

    # Method to invoke a PUT request to Microsoft Graph
    hidden [object[]]InvokeGraphPutRequest([string]$endpoint, [string[]]$segments, [hashtable]$body) {
        return $this.InvokeGraphRequest("PUT", $endpoint, $null, $segments, $body, $null)

    }

    # Method to invoke a DELETE request to Microsoft Graph
    hidden [object[]]InvokeGraphDeleteRequest([string]$endpoint, [string[]]$segments) {
        return $this.InvokeGraphRequest("DELETE", $endpoint, $null, $segments, $null, $null)
    
    }

    # Method to invoke batch requests
    [System.Collections.ArrayList]InvokeBatchRequests() {
        # Initialize the responses
        $responses = [System.Collections.ArrayList]::new()

        # Invoke the batch requests
        foreach ($batch in $this.BatchQueue) {
            # Set the batch request parameters
            $this.SetGraphBatchRequestParams($batch)

            # Get the parameters
            $params = $this.ShowGraphRequest()

            # Invoke the batch request
            Try {
                $r = Invoke-MgGraphRequest @params

                # Extract the response status
                $request_status = $this.ExtractBatchRequestStatus($r)

                # Add the response to the successful responses list
                [void]$responses.AddRange(@($request_status.Success))

                # If there are failed requests, build the retry parameters
                If ($request_status.Failed.Count -gt 0) {
                    # Get the retry delay
                    $retry_delay = $this.GetRetryDelay($request_status.Failed)

                    # If the retry delay is greater than 0, build the retry parameters
                    If ($retry_delay -gt 0) {
                        # Build the retry parameters
                        $retry_params = $this.BuildBatchRetryParams($params, $request_status.Failed)

                        # Wait for the retry delay before retrying
                        Try {
                            # Wait for the retry delay before retrying
                            Write-Warning "Microsoft Graph API rate limit exceeded. Waiting $retry_delay seconds before retrying failed requests..."
                            Start-Sleep -Seconds $retry_delay

                            # Retry the requests
                            $r = Invoke-MgGraphRequest @retry_params

                            # Extract the response status
                            $request_status = $this.ExtractBatchRequestStatus($r)

                            # Add the response to the successful responses list
                            [void]$responses.AddRange(@($request_status.Success))

                        } Catch {
                            Throw "$($_.Exception.Message)"

                        }
                    }
                }
                # Wait for 1 second before processing the next batch
                Start-Sleep -Seconds 1

            } Catch {
                Throw "$($_.Exception.Message). Retrying..."

            }
        }
        $this.BatchQueue.Clear()
        return $responses

    }

    # Method to extract the batch request status
    hidden [Object[]]ExtractBatchRequestStatus([Object[]]$response) {
        # Extract the response content
        $responses = [GraphRequestClient]::ExtractResponseContent($response)

        # Initialize the status
        $status = @{}
        $status["Success"] = [System.Collections.ArrayList]::new()
        $status["Failed"] = [System.Collections.ArrayList]::new()

        # Loop through the responses
        foreach ($r in $responses.responses) {
            # Add the response to the successful responses list
            if ($r.status -in @("200","204")) {
                [void]$status["Success"].Add($r)

            } Else {
                # Add the response to the failed responses list
                [void]$status["Failed"].Add($r)

            }
        }
        return $status

    }

    # Method to build the retry parameters
    hidden [hashtable]BuildBatchRetryParams([hashtable]$params, [object[]]$failedResponses) {
        # Get the body
        $body = $params.Body | ConvertFrom-Json
        
        # Extract the failed requests
        $failed_requests = $body.requests | Where-Object {
            $_.id -in $failedResponses.id

        }

        # Update the body with the failed requests
        $body.requests = $failed_requests

        # Add the updated body to the parameters
        $params.Body = $body | ConvertTo-Json -Depth 10
        return $params
    
    }

    hidden [int]GetRetryDelay([object[]]$failedResponses) {
        # Initialize the retry delay
        $retry_after = 0

        # Get the throttled responses
        $throttled_responses = $failedResponses | Where-Object { 
            $_.status -eq 429 
        
        }

        # If there are throttled responses, get the retry delay
        if ($throttled_responses) {
            foreach ($throttled_response in $throttled_responses) {
                if ($throttled_response.headers.'retry-after') {
                    $retry_after = [Math]::Max($retry_after, [int]$throttled_response.headers.'retry-after')
                
                }
            }
        } Else {
            $retry_after = 1
        
        }
        return $retry_after
    
    }

    #endregion

    #region Pagination
    # Method to paginate through next links. It's written to be dynamic so that it can be used for any method.
    hidden [System.Collections.Generic.List[object]]Paginate([hashtable]$params) {
        $results = [System.Collections.Generic.List[object]]::new()
        $next_link = $null
        $top_limit = $null

        # Extract $top value 
        if ($params["Uri"] -match '\$top=(\d+)') {
            $top_limit = [int]$matches[1]
        
        }
        Do {
            # If nextLink exists, update URI
            if ($next_link) {
                $params["Uri"] = $next_link
            
            }
            # Get the data
            try {
                $r = Invoke-MgGraphRequest @params
                # Extract the response content if the status code is 200
                If ($r.StatusCode.value__ -eq 200) {
                    $r_obj = [GraphRequestClient]::ExtractResponseContent($r)

                } Else {
                    throw "Error during pagination: $($r.StatusCode.value__) $($r.ReasonPhrase)"
                
                }
                # Add results to collection
                if ($r_obj.value) {
                    foreach ($item in $r_obj.value) {
                        $results.Add($item)

                        # Check if we've reached the top limit
                        if ($top_limit -and $results.Count -ge $top_limit) {
                            return $results
                        
                        }
                    }
                } ElseIf ($r_obj -and !$r_obj."@odata.context") {
                    return $r_obj

                }
                # Update nextLink for next iteration
                $next_link = $r_obj."@odata.nextLink"
            } catch {
                throw "Error during pagination: $_"
            
            } 
        } Until (!$next_link)
        
        return $results
    }
    #endregion

    #region Request formatting
    # Method to dynamically set the graph endpoint
    hidden [void]SetGraphEndpoint() {
        # Get the graph environment
        $context = Get-MgContext -ErrorAction Stop
        If ($context) {
            # Get the graph endpoint
            $this.GraphEndpoint = (Get-MgEnvironment -Name $context.Environment -ErrorAction Stop).GraphEndpoint
        
        } Else {
            throw "Authentication needed. Please call Connect-MgGraph."
        
        }
    }

    # Method to set the graph request parameters
    hidden [void]SetGraphRequestParams([string]$uri, [string]$method, [hashtable]$params) {
        # Clear the graph request parameters
        $this.ClearGraphRequestParams()

        # Invoke-MgGraphRequest parameters
        $this.GraphRequestParams["Uri"] = $uri
        $this.GraphRequestParams["Method"] = $method
        $this.GraphRequestParams["OutputType"] = "HttpResponseMessage"
        $this.GraphRequestParams["ErrorAction"] = "Stop"
        Foreach ($key in $params.Keys) {
            $this.GraphRequestParams[$key] = If ($key -eq "Body") {
                $params[$key] | ConvertTo-Json -Depth 10

            } Else {
                $params[$key]

            }
        }
    }

    # Method to set the graph batch request parameters
    hidden[void]SetGraphBatchRequestParams([hashtable]$body) {
        $this.GraphRequestParams["Uri"] = $this.BuildGraphUri($null, "`$batch", $null, $false)
        $this.GraphRequestParams["Method"] = "POST"
        $this.GraphRequestParams["Body"] = $body | ConvertTo-Json -Depth 10
        $this.GraphRequestParams["OutputType"] = "HttpResponseMessage"
        $this.GraphRequestParams["ErrorAction"] = "Stop"
    
    }

    # Method to clear the graph request parameters
    hidden [void]ClearGraphRequestParams() {
        $this.GraphRequestParams = @{}
    
    }

    # Method to build the batch request body
    hidden [hashtable]SetGraphBatchRequestBody([hashtable]$requests) {
        # Build the batch request
        $batch_request = @{}
        $batch_request["requests"] = $requests.requests
        return $batch_request
    
    }

    # Method to split the batch requests into smaller segments of 20 requests each
    hidden [void]SplitBatchRequests([hashtable]$batchRequests) {        
        # Calculate how many 
        $total_requests = $batchRequests.requests.Count
        $total_batches = [Math]::Ceiling($total_requests / 20)
        
        # Split the batch requests into smaller segments of 20 requests each
        for ($i = 0; $i -lt $total_batches; $i++) {
            # Get the current segment of requests
            $start_index = $i * 20
            $end_index = [Math]::Min($start_index + 20 - 1, $total_requests - 1)
            $batch = $batchRequests.requests[$start_index..$end_index]
            
            # Build the batch request for this segment
            $batch_request_body = @{}
            $batch_request_body["requests"] = $batch
            $this.BatchQueue.Add($batch_request_body)
        
        }        
    }
    #endregion

    #region Static request formatting
    # Method to set the default select parameters
    static [string[]]SetDefaultSelect([string[]]$select, [string[]]$default) {
        Foreach ($item in $default) {
            If ($item -notin $select -or $item -notin ($select -split ",")) {
                $select += $item

            }
        }
        return $select
    
    }

    # Method to initialize the query parameters
    static [hashtable]InitializeQueryParams([string[]]$select, [string[]]$keys, [hashtable]$params, [bool]$count = $false) {
        $query_params = @{}
        $query_params["Select"] = $select -join ","
        If ($count) {
            $query_params["Count"] = "true"

        }
        Foreach ($param in $keys) {
            If ($params[$param]) {
                $query_params[$param] = $params[$param]

            }
        }
        return $query_params
    }

    # Method to check if a string is a GUID
    static [bool]IsGuid([string]$id) {
        return $id -match "^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$"
    
    }

    #endregion

    #region Graph URI building
    # Method to build the graph URI 
    [string]BuildGraphUri([string]$endpoint, [string[]]$segments, [hashtable]$queryParams, [bool]$returnRelative = $false) {
        # Build the base URI
        $base_uri = "$($this.GraphEndpoint)/$($this.ApiVersion)/$endpoint"

        # Add the segments
        If ($segments) {
            $graph_uri = "$($base_uri)/$(($segments -replace '(^/+|/+$)', '') -join "/")"
            
        } Else {
            $graph_uri = $base_uri
        
        }
        
        # Add the query parameters
        If ($queryParams) {
            $graph_uri += $this.BuildODataQueryString($queryParams)
        
        }
        
        # Return the relative URI if needed
        If ($returnRelative) {
            # This is to support batch requests
            Return $graph_uri -replace "^$([regex]::Escape($this.GraphEndpoint))", ""
        
        }
        # Sanitize the URL
        Return $this.SanitizeUrl($graph_uri)
    
    }

    # Method to build the graph query hash table
    hidden [hashtable]BuildGraphQuery([string]$filter, [hashtable]$queryParams) {
        $query_params = @{}
        $query_params["Filter"] = $filter
        Foreach ($param in $queryParams.Keys) {
            $query_params[$param] = $queryParams[$param]
        
        }
        return $query_params
    
    }

    # Helper method to build OData query string parameters
    hidden [string]BuildODataQueryString([hashtable]$queryParams) {
        If (!$queryParams) {
            Return ""
        
        }
        # Initialize the query strings
        $query_strings = [System.Collections.ArrayList]::new()
        
        # Loop through the query parameters
        Foreach ($key in $queryParams.Keys) {
            $value = $queryParams[$key]
            
            # Format parameter key with $ prefix if needed
            $param_key = If ($key -match '^\$') { 
                $key 
            
            } Else { 
                "`$$key" 
            
            }
            # Format value based on type
            $encoded_value = $this.FormatQueryValue($value)
            
            [void]$query_strings.Add("$param_key=$encoded_value")
        
        }
        If ($query_strings) {
            return "?$($query_strings -join '&')"
        
        } Else {
            return ""
        
        }
    }

    # Helper method to format query parameter values
    hidden [string]FormatQueryValue($value) {
        if ($value -is [array]) {
            return [uri]::EscapeDataString(($value -join ","))
        
        }
        return [uri]::EscapeDataString($value.ToString())
    
    }

    # Method to sanitize the URL
    hidden [string]SanitizeUrl([string]$url) {
        # Strip duplicate slashes (but keep https:// intact)
        $url = $url -replace "(?<!https:)/{2,}", "/"
    
        # Remove trailing slash unless it’s just root
        if ($url -ne "/" -and $url.EndsWith("/")) {
            $url = $url.TrimEnd("/")
        
        }
    
        return $url
    }
    #endregion

    #region Client-side data management
    static [object[]]ExtractResponseContent([object]$response) {
        return ($response.Content.ReadAsStringAsync().Result | ConvertFrom-Json)

    }
    # Method to get the Invoke-MgGraphRequest parameters..
    [hashtable]ShowGraphRequest() {
        return $this.GraphRequestParams 
    
    }

    # Method to get the Invoke-MgGraphRequest parameters as a JSON string. This can be used for debugging purposes.
    [string]ShowGraphRequestAsJson() {
        return $this.GraphRequestParams | ConvertTo-Json -Depth 10 -Compress
    
    }

    # Method to build the cache key
    static [string]BuildWriteCacheKey([string]$method, [string]$uri, $body) {
        $bodyJson = If ($body) {
            $body | ConvertTo-Json -Depth 10 -Compress
        
        } Else {
            ""
        }
        return @($method,$uri,$bodyJson) -join "|"
    
    }
    #endregion
}