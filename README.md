Aws-Lego
========

Status: Alpha

A set of templates designed to unify common AWS deployment topology. The common use cases it currently aim to facilitate includes:
- Web Hosting with only ELB exposed.
- Database with isolated subnets.
- Source Control; using Phabricator
- Continuous Integration; using Jenkins<sub>1</sub> and Go.CD<sub>1</sub>
- Integligence and Analytics; AWS log collection, Elasticsearch, Logstash<sub>1</sub> and Kibana<sub>1</sub>
- Middle Ware and Support; Zookeeper, Kafka<sub>1</sub>

<sub>1 Denotes sork in progress</sub>  
Also others to come later:
- Clustering and Orchestration of Docker deployment; Mesospohere + HAProxy + Kubernetes
- A unified monitoring, alerting, reporting and anlytics topology across Windows and Linux. Encompassing all web servers, applications and runtimes; Apache, Nginx, Windows and all the listed software packages and nodejs, java, .net, etc etc.
- And more, Storm, Hadoop, Druid


With an all encompassing deployment topology, software vendors would then be able to create step by step walk through of deployment scenarios that map precisely to topologies that choose to dopt AWS-Lego.

As for 


Getting Started
==============

One of the most common task of a starting dev team is 1) source control and 2) build server. Let's try deploy a complete VPC with both a Phabricator and a Jenkins installation.

<h4>Prerequisite</h4>
Install AWS .Net SDK and have access to PowerShell  
From PowerShell:  
```
Set-AWSCredentials -AccessKey <key> -SecretKey <secret>  
Set-DefaultAWSRegion -Region <region>  
```

<h4>Deploy Reference Topology</h4>
Setting up a VPC with public subnets, private subnets, and NAT (And all associated firewall and routing rules.) Then set up Phabricator, Jenkins  
Download:  
https://s3-ap-southeast-2.amazonaws.com/bc-public-releases/AWS-Lego/Alpha/Deployment.ps1  
https://s3-ap-southeast-2.amazonaws.com/bc-public-releases/AWS-Lego/Alpha/New-CompleteReferenceTopology.ps1  
<sub>(Please note there are currently some issues with us-east-1 due to the possible skipping of AZ returned from [Fn::GetAZs](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html)</sub>

Open Powershell ISE (or just Powershell) and run New-CompleteReferenceTopology.ps1

You will be prompted for required details.

<h4>Deploy Phabricator</h4>
Download and run:  
https://s3-ap-southeast-2.amazonaws.com/bc-public-releases/AWS-Lego/Alpha/New-Phabricator.ps1  

<h4>Deploy Jenkins</h4>
(to come.)
