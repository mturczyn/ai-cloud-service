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
    -Headers @{'Authorization' = 'Bearer 1234'} `
    -uri https://$HostName/api/pull `
    -Body $body