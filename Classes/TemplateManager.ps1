class TemplateManager {
    # Private fields
    hidden [hashtable]$TemplateCache = @{}
    hidden [string]$TemplatePath

    # Constructor
    TemplateManager([string]$templatePath) {
        $this.TemplatePath = $templatePath
        if (!(Test-Path -Path $templatePath)) {
            throw "Template path not found: $templatePath"
        
        }
    }

    # Method to get template with caching
    [string] GetTemplate([string]$templateName) {
        $cache_key = Join-Path -Path $this.TemplatePath -ChildPath $templateName
        
        if ($this.TemplateCache.ContainsKey($cache_key)) {
            return $this.TemplateCache[$cache_key]
        
        }

        $template = Join-Path -Path $this.TemplatePath -ChildPath $templateName
        if (Test-Path -Path $template -PathType Leaf) {
            try {
                $content = Get-Content -Path $template -Raw
                $this.TemplateCache[$cache_key] = $content
                return $content
            
            } catch {
                throw "Error reading template $templateName`: $_"
            
            }
        }
        throw "Template not found: $templateName"
    
    }

    # Method to clear cache
    [void] ClearCache() {
        $this.TemplateCache.Clear()
    
    }

    # Method to get cache size
    [int] GetCacheSize() {
        return $this.TemplateCache.Count
    
    }
}