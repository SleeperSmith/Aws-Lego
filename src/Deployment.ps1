$templateNameTag = "TemplateName"
# Name > Environment > LogicalUnit

function New-Deployment {
    param (
        [string]$bucketname,
        [string]$projectname,
        [string]$version,
        [string]$deployroot
    )

    $prefix = "$projectname/$version/"
    $oldfiles = Get-S3Object -BucketName $bucketname -KeyPrefix $prefix | % {
        Write-Host "Uploading > $($_.Key)"
    }
    if ($oldfiles.Count -gt 0) {
        $removedObjects = Remove-S3Object -BucketName $bucketname -Keys $oldfiles -Force
    }
    $writtenObjects = Write-S3Object -BucketName $bucketname -KeyPrefix $prefix -Folder $deployroot -Recurse
    $region = (Get-DefaultAWSRegion).Region
    $deploymentUrl = "https://s3-$region.amazonaws.com/$bucketname/$projectname/$version/"
    return $deploymentUrl
}

function InternalMatchTag {
    param(
        $CfnStacks,
        $TemplateName
    )

    $result = @()
    foreach($cfnStack in $CfnStacks) {

        $templateTag = $CfnStack.Tags | ? {
            $_.Key -eq $templateNameTag
        } | ? {
            $_.Value.Split('.') | ? {
                $_ -eq $TemplateName
            }
        }

        if($templateTag.Count -gt 0) {
            $result += $cfnStack
        }
    }

    if ($result.Count -gt 0) {
        return $result[0]; #pick first. The order of stack is the priority.
    }
    return $null;
}

function Get-StackLinkParameters {
    param(
        [Parameter(
            Mandatory = $true)]
        [string]$TemplateUrl,

        [string]$TemplateUrlBaseParameterKey = "TemplateBaseUrl",
        $StackParameters = (New-Object 'System.Collections.Generic.List[object]'),
        [string[]]$PriorityStackNames = @()
    )

    $cfnNewLaunchTarget = Test-CFNTemplate -TemplateURL $TemplateUrl
    $cfnNewLaunchTargetParameterKeys = $cfnNewLaunchTarget.Parameters | % {
        $_.ParameterKey
    }

    $templateUrlSegments = $TemplateUrl.Split('/')
    $templateUrlSegments[$templateUrlSegments.Count-1] = ""
    $templateUrlBase = [string]::Join("/", $templateUrlSegments)

    Write-Host == Existing Stacks ==
    $cfnStacks = Get-CFNStack | ? {
        ($_.Tags | ? { $_.Key -eq $templateNameTag }).Count -eq 1
    }
    $priorityCfnStacks = $cfnStacks | ? {
        $PriorityStackNames.Contains($_.StackName)
    }
    $nonePriorityStacks = $cfnStacks | ? {
        !($PriorityStackNames.Contains($_.StackName))
    }
    $cfnStacks = @()
    $cfnStacks += $priorityCfnStacks
    $cfnStacks += $nonePriorityStacks
    if ($cfnStacks.Count -eq 0) {
        Write-Host No stacks found.
    } else {
        Write-Host $([string]::Join(", ", ($cfnStacks | % { $_.StackName })))
    }

    Write-Host == Parameters ==
    foreach($cfnParameter in $cfnNewLaunchTarget.Parameters) {
        # Only if the parameter doesn't exist yet
        $matchedParams = $StackParameters | ? {
            $_.Key -eq $cfnParameter.ParameterKey
        }
        if ($matchedParams.count -gt 0) {
            continue
        }

        $paramDerivative = Select-String "\[(.*)\]" -input $cfnParameter.Description -AllMatches | Foreach {$_.Matches.Groups[1].Value}
        # Only if there's param derivative directive
        if (($paramDerivative -eq $null) -or ($paramDerivative.Count -ne 1)) {
            continue
        }

        $segments = $paramDerivative.Split('.')
        # Only if the derivative directive has 3 segments
        if ($segments.Count -ne 3) {
            continue
        }

        $matchedStack = InternalMatchTag -CfnStacks $cfnStacks -TemplateName $segments[0]
        # Only if the stack exist.
        if ($matchedStack -eq $null) {
            continue
        }
        $matchedStack = $matchedStack[0]

        $value = $null
        switch($segments[1].ToLower()) {
            "parameters" {
                $matchedParams = $matchedStack.Parameters | ? {
                    $_.ParameterKey -eq $segments[2]
                }
                if ($matchedParams.Count -eq 1) {
                    $value = $matchedParams[0].Value
                }
            }
            "resources" {
                $resources = Get-CFNStackResources -StackName $matchedStack.StackName
                $matchedResource = $resources | ? {
                    $_.LogicalResourceId -eq $segments[2]
                }
                if ($matchedResource.Count -eq 1) {
                    $value = $matchedResource[0].PhysicalResourceId
                }
            }
            "outputs" {
                $matchedOutputs = $matchedStack.Outputs | ? {
                    $_.OutputKey -eq $segments[2]
                }
                if ($matchedOutputs.Count -eq 1) {
                    $value = $matchedOutputs[0].OutputValue
                }
            }
        }

        if ($value -ne $null) {
            $StackParameters += @{"Key" = $cfnParameter.ParameterKey; "Value" = $value}
        }

    }

    $StackParameters | % {
        Write-Host ">" $_["Key"]: $_["Value"]
    }

    $result = New-Object Object
    $result | Add-Member -MemberType NoteProperty -Name TemplateUrl -Value $TemplateUrl
    $result | Add-Member -MemberType NoteProperty -Name StackParameters -Value $StackParameters

    return $result
}

function Upsert-StackLink(
        [parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string]$TemplateUrl,
        [parameter(
            ValueFromPipelineByPropertyName=$true)]
        $StackParameters,

        [string]$StackName,
        $Tags = @(),
        [bool]$UpdateExisting = $true
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

    $cfnNewLaunchTarget = Test-CFNTemplate -TemplateURL $TemplateUrl

    Write-Host == Create Stack ==    
    $Tags += @{"Key" = $templateNameTag; "Value" = $templateName}

    if ((Get-CFNStack | ? { $_.StackName -eq $StackName}).Count -eq 0) {
        $stackId = New-CFNStack -StackName $StackName -Parameters $StackParameters -TemplateURL $TemplateUrl -Tags $tags -Capabilities "CAPABILITY_IAM"
    } elseif ($UpdateExisting) {
        $stackId = Update-CFNStack -StackName $StackName -Parameters $StackParameters -TemplateURL $TemplateUrl -Capabilities "CAPABILITY_IAM"
    }
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

Write-Host AWS-Lego loaded.