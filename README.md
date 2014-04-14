Aws-Lego
========

A set of templates designed for often used components of Amazon Web Services

Example usages
==============
Download deployment.ps1 from https://s3-ap-southeast-2.amazonaws.com/bc-deployment/Temp/Deployment.ps1

Open powershell

```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
Initialize-AWSDefaults -AccessKey <key> -SecretKey <secret> -Region <region>
.".\Deployment.ps1"

# Launch stacks
New-StackLink -TemplateUrl 'https://s3-ap-southeast-2.amazonaws.com/bc-deployment/Temp/vpc.template' | Wait-StackLink
New-StackLink -TemplateUrl 'https://s3-ap-southeast-2.amazonaws.com/bc-deployment/Temp/subnet.template' | Wait-StackLink
```
