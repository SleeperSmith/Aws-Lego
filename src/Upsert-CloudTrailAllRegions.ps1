param(
    $bucketName
)

Get-AWSRegion | ? {
    $_.Region.Contains("-")
} | % {
    $trail = Get-CTTrail -Region $_.Region -TrailNameList $_.Region
    if ($trail -eq $null) {
        Write-Host "New CloudTrail in region $($_.Region)"
        New-CTTrail -S3BucketName $bucketName -Region $_.Region -IncludeGlobalServiceEvents $_.IsShellDefault -Name $_.Region
    } elseif ($trail.S3BucketName -ne $bucketName) {
        Write-Host "Updating region $($_.Region)"
        Update-CTTrail -Name $_.Region -Region $_.Region -S3BucketName $bucketName
    } else {
        Write-Host "No changes for region $($_.Region)"
    }
}