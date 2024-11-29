param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $HostName,
  
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $ModelName
)

$body = '{"model":"' + $ModelName + '"}'

Invoke-WebRequest `
    -Method POST `
    -uri https://$HostName/api/pull `
    -Body $body