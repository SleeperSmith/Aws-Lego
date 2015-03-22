param(
    $prefix = "https://s3-ap-southeast-2.amazonaws.com/bc-public-releases/AWS-Lego/Alpha/",
    $kp = (Read-Host 'Name of Key Pair to user for Go Server instances access'),
    $ami = (Read-Host 'AMI ID of Go Master Server (Ubuntu)'),
    $winami = (Read-Host 'AMI ID of Go Windows Build Agent (Windows)'),
    $tags = @(
        @{"Key" = "Project"; "Value" = "Infrastructure"},
        @{"Key" = "Environment"; "Value" = "Prod"}
    )
)

.".\Deployment.ps1"

Get-StackLinkParameters -TemplateUrl "$($prefix)special-blocks/jenkins.template" -StackParameters @(
    @{"Key" = "KeyPairName"; "Value" = $kp},
    @{"Key" = "ServerAmi"; "Value" = $ami},
    @{"Key" = "LinuxAgentAmi"; "Value" = $ami},
    @{"Key" = "WindowsAgentAmi"; "Value" = $winami}
) | Upsert-StackLink -Tags $tags -StackName "Prod-Jenkins"