param(
)

Set-ExecutionPolicy Unrestricted
Push-Location $PSScriptRoot
$content = Get-Content "BaseTask.xml.original"

function Install-JenkinsTask {
    $localcontent = $content.Replace("#TaskInterval#","1")
    $localcontent = $localcontent.Replace("#TaskCommand#","$PSScriptRoot\RunAgent.ps1")
    Set-Content -Path Task.JenkinsTask.xml -Value $localcontent

    ."schtasks.exe" /create /RU "NT AUTHORITY\SYSTEM" /TN "Jenkins Agent" /XML "Task.JenkinsTask.xml"
}

Install-JenkinsTask

Pop-Location