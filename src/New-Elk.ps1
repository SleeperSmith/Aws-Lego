param(
    $prefix = "https://s3-ap-southeast-2.amazonaws.com/bc-public-releases/AWS-Lego/Alpha/",
    $kp = (Read-Host 'Name of Key Pair to user for server instance access'),
    $ami = (Read-Host 'AMI ID of Phabricator Web Server (Ubuntu)'),
    $raw = (Read-Host 'S3 bucket name to hold raw logs'),
    $access = (Read-Host 'S3 bucket name to hold access logs'),
    $tags = @(
        @{"Key" = "Project"; "Value" = "Infrastructure"},
        @{"Key" = "Environment"; "Value" = "Prod"}
    )
)

.".\Deployment.ps1"

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/s3-aws-logs.template" -StackParameters @(
    @{"Key" = "RawLogBucketName"; "Value" = "$raw"},
    @{"Key" = "AccessLogBucketName"; "Value" = "$access"}
) | Upsert-StackLink -Tags $tags -StackName "$($tags[1].Value)-LogStuff"

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/s3-aws-logs.template" -StackParameters @(
    @{"Key" = "RawLogBucketName"; "Value" = "$raw"},
    @{"Key" = "AccessLogBucketName"; "Value" = "$access"},
    @{"Key" = "IsSubscribed"; "Value" = "subscribe"}
) | Upsert-StackLink -Tags $tags -StackName "$($tags[1].Value)-LogStuff"

Get-StackLinkParameters -TemplateUrl "$($prefix)special-blocks/elasticsearch.template" -StackParameters @(
    @{"Key" = "KeyPairName"; "Value" = $kp},
    @{"Key" = "EsClusterAmi"; "Value" = $ami},
    @{"Key" = "SnapshotBucketName"; "Value" = "bc-es-ss"}
) | Upsert-StackLink -Tags $tags -StackName "$($tags[1].Value)-Elasticsearch"

Get-StackLinkParameters -TemplateUrl "$($prefix)special-blocks/aws-log-stashing.template" -StackParameters @(
    @{"Key" = "KeyPairName"; "Value" = $kp},
    @{"Key" = "UbuntuAmi"; "Value" = $ami}
) | Upsert-StackLink -Tags $tags -StackName "$($tags[1].Value)-Logstash"