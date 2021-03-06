﻿param(
    $bucketname = (Read-Host 'Name of deployment bucket'),
    $projectname = "AWS-Lego",
    $version = "Temporary"
)

.".\Deployment.ps1"
$prefix = New-Deployment -bucketname $bucketname -projectname $projectname -version $version -deployroot ".\"

Write-Host "Deployment s3 prefix: $prefix"

return $prefix