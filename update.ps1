  # Check if System.Web is loaded, if not, load it
 if (-not ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq 'System.Web' })) {
    Add-Type -AssemblyName System.Web
}



<# 

--- AD automation ---

Import-Module ActiveDirectory
$forest = Get-ADForest
$domainNames = @()
foreach ($domain in $forest.Domains) {
    $domainControllers = Get-ADDomainController -Filter * -Server $domain
    $domainControllers | ForEach-Object { $domainNames += $_.HostName }
}
$domainNames = @($domainNames)
$domainNames

#>

 # add the list of domain names as a sample in case domain integration is not used
 $domainNames = @('*.server1.example.com', '*.server2.example.com', '*.server3.example.com')

 <# credentials -- maybe use 
 
$client_id = $env:CLIENT_ID
$client_secret = $env:CLIENT_SECRET
for good luck and best practice

but let's stay basic ... 
#>
 
 $client_id = 'xxxxxxxxxxxx'
 $client_secret = 'yyyyyyyyyyyyyyy'

 
 # Authentication URL
 $authUrl = 'https://config.private.zscaler.com/signin'
 
 # payload for auth request
 $authBody = @{
     client_id = $client_id
     client_secret = $client_secret
 }
 
 # Convert the body to URL-encoded form data
 $authBodyEncoded = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
 $authBody.GetEnumerator() | ForEach-Object {
     $authBodyEncoded.Add($_.Key, $_.Value)
 }
 $authBodyEncodedString = $authBodyEncoded.ToString()
 
 # headers for the authentication
 $authHeaders = @{
     'Content-Type' = 'application/x-www-form-urlencoded'
 }
 
 # authentication
 $authResponse = Invoke-RestMethod -Uri $authUrl -Method Post -Headers $authHeaders -Body $authBodyEncodedString
 $accessToken = $authResponse.access_token
 if (-not $accessToken) {
     Write-Error "Failed to retrieve the access token."
     exit
 }
 
 # headers including the token
 $headers = @{
     'Authorization' = "Bearer $accessToken"
     'accept' = '*/*'
     'Content-Type' = 'application/json'
 }
 
 # GET the existing app segment -> Adjust id's XXXXXXXXXXXX -> fetch it from your ZPA API Portal swagger
 $url = 'https://config.private.zscaler.com/mgmtconfig/v1/admin/customers/xxxxxxxxxxxxx/application/xxxxxxxxxxxx'
 $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers

 # Create a backup
 $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
 $responseJson = $response | ConvertTo-Json
 $responseJson | Out-File -FilePath $backupFilePath -Encoding UTF8
 $backupFilePath = "C:\Path\To\Backup\ZPA_Config_Backup_$timestamp.txt"
 Write-Output "Configuration loaded and backed up to $backupFilePath"
   
 Write-Output "Configuration for:"
 Write-Output $response.name

 
 # Update the domainNames field
 $response.domainNames = $domainNames
 $bodyJson = $response | ConvertTo-Json
 
 # update the configuration
 Invoke-RestMethod -Uri $url -Method Put -Headers $headers -Body $bodyJson
 
 Write-Output "Configuration updated successfully with the following domain names:"
 Write-Output $domainNames
 
 
  
  
