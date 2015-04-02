param(
    $prefix = "https://s3-ap-southeast-2.amazonaws.com/bc-public-releases/AWS-Lego/Alpha/",
    $kp = (Read-Host 'Name of Key Pair to user for Phabricator Web Server instance access'),
    $ami = (Read-Host 'AMI ID of Phabricator Web Server (Ubuntu)'),
    $tags = @(
        @{"Key" = "Project"; "Value" = "Infrastructure"},
        @{"Key" = "Environment"; "Value" = "Prod"}
    )
)

.".\Deployment.ps1"

Get-StackLinkParameters -TemplateUrl "$($prefix)special-blocks/elasticsearch.template" -StackParameters @(
    @{"Key" = "KeyPairName"; "Value" = $kp},
    @{"Key" = "EsClusterAmi"; "Value" = $ami}
) | Upsert-StackLink -Tags $tags -StackName "Prod-Elasticsearch"