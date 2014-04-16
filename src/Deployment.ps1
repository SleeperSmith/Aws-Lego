# Name > Environment > LogicalUnit

Write-Host AWS-Lego loaded.

function New-StackLink(
        [Parameter(
            Mandatory = $true)]
        [string]$TemplateUrl,

        [string]$StackName,
        $Tags = @(),
        $StackParameters = @(),

        [string]$TemplateUrlBaseParameterKey = "TemplateBaseUrl"
    ) {
    Write-Host
    Write-Host "## Start New-StackLink ##"

    # Metadata
    Write-Host == Metadata ==
    $templateUrlSegments = $TemplateUrl.Split('/')
    $templateName = $templateUrlSegments[$templateUrlSegments.Length - 1]
    Write-Host CloudFormation template name: $templateName
    if ([string]::IsNullOrWhiteSpace($StackName)) {
        $StackName = $templateName.Split('.')[0]
    }
    Write-Host CloudFormation stack name: $StackName
    $templateUrlSegments[$templateUrlSegments.Count-1] = ""
    $templateUrlBase = [string]::Join("/", $templateUrlSegments)
    Write-Host CloudFormation template base path: $templateUrlBase

    $cfnNewLaunchTarget = Test-CFNTemplate -TemplateURL $TemplateUrl
    $cfnNewLaunchTargetParameterKeys = $cfnNewLaunchTarget.Parameters | % {
        $_.ParameterKey
    }

    # Get existing stacks
    Write-Host == Existing Stacks ==
    $templateNameTag = "TemplateName"
    $cfnStacks = Get-CFNStack | ? {
        ($_.Tags | ? { $_.Key -eq $templateNameTag }).Count -eq 1
    }
    if ($cfnStacks.Count -eq 0) {
        Write-Host No stacks found.
    } else {
        Write-Host $([string]::Join(", ", ($cfnStacks | % { $_.StackName })))
    }

    # Add dependant parameters
    Write-Host == Parameters ==
    if ($cfnNewLaunchTargetParameterKeys.Contains($TemplateUrlBaseParameterKey)) {
        $StackParameters += @{
            "Key" = $TemplateUrlBaseParameterKey; "Value" = $templateUrlBase
        }
    }
    foreach($cfnStack in $cfnStacks) {
        $cfnStackTemplateName = $cfnStack.Tags | ? {
            $_.Key -eq $templateNameTag
        } | % {
            $_.Value
        } | Select-Object -First 1
        
        foreach($cfnStackTemplateSegment in $cfnStackTemplateName.Split('.')) {

            $cfnStack[0].Parameters | % {
                $key = $cfnStackTemplateSegment + "In" + $_.Key
                if ($cfnNewLaunchTargetParameterKeys.Contains($key)) {
                    $StackParameters += @{
                        "Key" = $key; "Value" = $_.Value
                    }
                }
            }
            $cfnStack[0].Outputs | % {
                $key = $cfnStackTemplateSegment + "Out" + $_.OutputKey
                if ($cfnNewLaunchTargetParameterKeys.Contains($key)) {
                    $StackParameters += @{
                        "Key" = $key; "Value" = $_.OutputValue
                    }
                }
            }

        }
    }

    $StackParameters | % {
        Write-Host ">" $_["Key"]: $_["Value"]
    }

    Write-Host == Create Stack ==    
    $Tags += @{"Key" = $templateNameTag; "Value" = $templateName}
    $stackId = New-CFNStack -StackName $StackName -Parameters $StackParameters -TemplateURL $TemplateUrl -Tags $tags
    Write-Host StackArn: $stackId
    Write-Host "## End New-StackLink ##"
    return $stackId
}

function Wait-StackLink(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]$StackLinkId,
        [int]$PollInterval = 15
    ) {
    Write-Host
    Write-Host "## Start Wait-StackLink ##"

    $statusToBlock = @(
        [Amazon.CloudFormation.StackStatus]::CREATE_IN_PROGRESS,
        [Amazon.CloudFormation.StackStatus]::DELETE_IN_PROGRESS,
        [Amazon.CloudFormation.StackStatus]::UPDATE_IN_PROGRESS,
        [Amazon.CloudFormation.StackStatus]::ROLLBACK_IN_PROGRESS
    )

    while($statusToBlock.Contains((Get-CFNStack $StackLinkId).StackStatus)) {
        Write-Host "Waiting... Stack status: " (Get-CFNStack $StackLinkId).StackStatus
        sleep $PollInterval
    }
    Write-Host "## End Wait-StackLink ##"
}
