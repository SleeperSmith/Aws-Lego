param(
    $prefix = "https://s3-ap-southeast-2.amazonaws.com/bc-public-releases/AWS-Lego/Alpha/",
    $kp = (Read-Host 'Name of Key Pair to user for Phabricator Web Server instance access'),
    $ami = (Read-Host 'AMI ID of Phabricator Web Server (Ubuntu)'),
    $email = (Read-Host 'Email address of phabricator sender. e.g. noreply@your-domain.com'),
    $phost = (Read-Host 'Host name of phabricator web. e.g. http://phabricator.your-domain.com/'),
    $tags = @(
        @{"Key" = "Project"; "Value" = "Infrastructure"},
        @{"Key" = "Environment"; "Value" = "Prod"}
    )
)

.".\Deployment.ps1"

$password = $([Guid]::NewGuid().ToString())
Write-Host "Your phabricator mysql password is: $password" -ForegroundColor Yellow

Get-StackLinkParameters -TemplateUrl "$($prefix)special-blocks/phabricator.template" -StackParameters @(
    @{"Key" = "KeyPairName"; "Value" = $kp},
    @{"Key" = "PhabMailAddress"; "Value" = $email},
    @{"Key" = "DbPassword"; "Value" = "$password"},
    @{"Key" = "Hostname"; "Value" = $phost},
    @{"Key" = "UbuntuAmi"; "Value" = $ami}
) | Upsert-StackLink -Tags $tags -StackName "Prod-Phabricator-1"