function New-StackLink {
    param(
        [string]$TemplateUrl,
        $tags = @()
    )

    $templateUrlSegments = $TemplateUrl.Split('/')
    $templateName = $templateUrlSegments[$templateUrlSegments.Length - 1].Split('.')[0]
    Write-Host CloudFormation template name: $templateName

    $cfnNewLaunchTarget = Test-CFNTemplate -TemplateURL $TemplateUrl
    $cfnNewLaunchTargetParameterKeys = $cfnNewLaunchTarget.Parameters | % {
        $_.ParameterKey
    }

    $templateNameTag = "TemplateName"
    $cfnStacks = Get-CFNStack | ? {
        ($_.Tags | ? { $_.Key -eq $templateNameTag }).Count -eq 1
    }
    $cfnStacks.Count

    $dependantParameters = @()
    foreach($cfnStack in $cfnStacks) {
        $cfnStackTemplateName = $cfnStack.Tags | ? {
            $_.Key -eq $templateNameTag
        } | % {
            $_.Value
        } | Select-Object -First 1

        $cfnStack[0].Parameters | % {
            $key = $cfnStackTemplateName + "In" + $_.Key
            if ($cfnNewLaunchTargetParameterKeys.Contains($key)) {
                $dependantParameters += @{
                    "Key" = $key; "Value" = $_.Value
                }
            }
        }
        $cfnStack[0].Outputs | % {
            $key = $cfnStackTemplateName + "Out" + $_.OutputKey
            if ($cfnNewLaunchTargetParameterKeys.Contains($key)) {
                $dependantParameters += @{
                    "Key" = $key; "Value" = $_.OutputValue
                }
            }
        }
    }

    $dependantParameters | % {
        $_
    }
    
    $tags += @{"Key" = $templateNameTag; "Value" = $templateName}
    New-CFNStack -StackName $templateName -Parameters $dependantParameters -TemplateURL $TemplateUrl -Tags $tags
}

function Wait-StackLink {
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName=$true)]
        [string]$StackLinkId,
        [int]$PollInterval = 15
    )

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
}
