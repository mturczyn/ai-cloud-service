param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $HostName
  
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $ModelName
)

Invoke-WebRequest `
    -Method POST `
    -uri https://$HostName/api/pull `
    -Body '{"model":"' + $ModelName + '"}'