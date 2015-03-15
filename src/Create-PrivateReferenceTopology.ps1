param(
    $prefix = "https://s3-ap-southeast-2.amazonaws.com/bc-public-releases/AWS-Lego/Alpha/"
)

.".\Deployment.ps1"
$tags = @(
    @{"Key" = "Project"; "Value" = "Infrastructure"},
    @{"Key" = "Environment"; "Value" = "Prod"}
)

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/vpc.template" |
    Upsert-StackLink -Tags $tags -StackName Prod-PrimaryVpc |
    Wait-StackLink

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/internet-access.subnets.template" |
    Upsert-StackLink -Tags $tags -StackName Prod-GatewaySubnets |
    Wait-StackLink

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/private.subnets.template" |
    Upsert-StackLink -Tags $tags -StackName Prod-PrivateSubnets |
    Wait-StackLink

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/nat-enabled.subnets.template" -StackParameters @(
    @{"Key" = "KeyPairName"; "Value" = "none-prod"} # name of Key Pair to user for NAT server instance access
) | Upsert-StackLink -Tags $tags -StackName Prod-NatSubnets |
    Wait-StackLink
