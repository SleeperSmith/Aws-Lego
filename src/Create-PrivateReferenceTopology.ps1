param(
    $prefix = "https://s3-ap-southeast-2.amazonaws.com/bc-deployment/AWS-Lego/Alpha/"
)

.".\Deployment.ps1"
$tags = @(
    @{"Key" = "Project"; "Value" = "Infrastructure"},
    @{"Key" = "Environment"; "Value" = "Prod"}
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