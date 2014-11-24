Set-DefaultAWSRegion ap-southeast-2
$prefix = "https://s3-ap-northeast-1.amazonaws.com/bit-clouded-deployment/Infrastructure/Sample/"
.".\src\Deployment.ps1"

$tags = @(
    @{"Key" = "Project"; "Value" = "Infrastructure"},
    @{"Key" = "Environment"; "Value" = "Test"}
)

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/vpc.template" |
    Upsert-StackLink -Tags $tags -StackName Test-PrimaryVpc |
    Wait-StackLink

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/internet-access.subnets.template" |
    Upsert-StackLink -Tags $tags -StackName Test-GatewaySubnets |
    Wait-StackLink

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/webserver.subnets.template" |
    Upsert-StackLink -Tags $tags -StackName Test-WebServerSubnets |
    Wait-StackLink

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/private.subnets.template" |
    Upsert-StackLink -Tags $tags -StackName Test-PrivateSubnets |
    Wait-StackLink

Get-StackLinkParameters -TemplateUrl "$($prefix)special-blocks/phabricator.template" -StackParameters @(
    @{"Key" = "KeyPairName"; "Value" = "Default"},
    @{"Key" = "PhabMailAddress"; "Value" = "phabricator-noreply@bit-clouded.com"},
    @{"Key" = "DbPassword"; "Value" = "Password1234!@#$"}
) | Upsert-StackLink -Tags $tags -StackName "Test-Phabricator"