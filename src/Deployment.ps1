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
        $_.Key
    }
    if ($oldfiles.Count -gt 0) {
        Remove-S3Object -BucketName $bucketname -Keys $oldfiles -Force
    }
    Write-S3Object -BucketName $bucketname -KeyPrefix $prefix -Folder $deployroot -Recurse
    
}

function InternalAddParameter {
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.Generic.List[string]]$ParameterKeys,
        #[Parameter(Mandatory=$true)]
        [System.Collections.Generic.List[object]]$Parameters = @(),
        [Parameter(Mandatory=$true)]
        [string]$Key,
        [Parameter(Mandatory=$true)]
        [string]$Value
    )

    if ($ParameterKeys.Contains($Key) -and !($Parameters.Contains($Key))) {
        $Parameters.Add(@{"Key" = $Key; "Value" = $Value})
    }
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

    $templateUrlSegments = $TemplateUrl.Split('/')
    $templateUrlSegments[$templateUrlSegments.Count-1] = ""
    $templateUrlBase = [string]::Join("/", $templateUrlSegments)

    $cfnNewLaunchTarget = Test-CFNTemplate -TemplateURL $TemplateUrl
    $cfnNewLaunchTargetParameterKeys = $cfnNewLaunchTarget.Parameters | % {
        $_.ParameterKey
    }

    Write-Host == Existing Stacks ==
    $cfnStacks = Get-CFNStack | ? {
        ($_.Tags | ? { $_.Key -eq $templateNameTag }).Count -eq 1
    }
    if ($cfnStacks.Count -eq 0) {
        Write-Host No stacks found.
    } else {
        Write-Host $([string]::Join(", ", ($cfnStacks | % { $_.StackName })))
    }

    Write-Host == Parameters ==
    InternalAddParameter -ParameterKeys $cfnNewLaunchTargetParameterKeys `
        -Parameters $StackParameters -Key $TemplateUrlBaseParameterKey -Value $templateUrlBase

    $priorityCfnStack = $cfnStacks | ? {
        $PriorityStackNames.Contains($_.StackName)
    }
    foreach($cfnStack in $priorityCfnStack) {
        $cfnStackTemplateName = $cfnStack.Tags | ? {
            $_.Key -eq $templateNameTag
        } | % {
            $_.Value
        } | Select-Object -First 1
        
        foreach($cfnStackTemplateSegment in $cfnStackTemplateName.Split('.')) {

            $cfnStack[0].Parameters | % {
                $key = $cfnStackTemplateSegment + "In" + $_.Key
                InternalAddParameter -ParameterKeys $cfnNewLaunchTargetParameterKeys `
                    -Parameters $StackParameters -Key $key -Value $_.Value
            }
            $cfnStack[0].Outputs | % {
                $key = $cfnStackTemplateSegment + "Out" + $_.OutputKey
                InternalAddParameter -ParameterKeys $cfnNewLaunchTargetParameterKeys `
                    -Parameters $StackParameters -Key $key -Value $_.OutputValue
            }
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
                InternalAddParameter -ParameterKeys $cfnNewLaunchTargetParameterKeys `
                    -Parameters $StackParameters -Key $key -Value $_.Value
            }
            $cfnStack[0].Outputs | % {
                $key = $cfnStackTemplateSegment + "Out" + $_.OutputKey
                InternalAddParameter -ParameterKeys $cfnNewLaunchTargetParameterKeys `
                    -Parameters $StackParameters -Key $key -Value $_.OutputValue
            }
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
        $StackParameters = @(),

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
        $stackId = New-CFNStack -StackName $StackName -Parameters $StackParameters -TemplateURL $TemplateUrl -Tags $tags
    } elseif ($UpdateExisting) {
        $stackId = Update-CFNStack -StackName $StackName -Parameters $StackParameters -TemplateURL $TemplateUrl
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
