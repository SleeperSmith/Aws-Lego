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


Example usages
==============

Set-AWSCredentials -AccessKey &lt;key&gt; -SecretKey &lt;secret&gt;  
Set-DefaultAWSRegion -Region &lt;region&gt;  
<sub>(Please note there are currently some issues with us-east-1 due to the possible skipping of AZ returned from [Fn::GetAZs](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html)</sub>

Setting up a VPC with public subnets, private subnets, and NAT (And all associated firewall and routing rules.) Then set up Phabricator, Jenkins  
Download:  
https://s3-ap-southeast-2.amazonaws.com/bc-public-releases/AWS-Lego/Alpha/Deployment.ps1  
https://s3-ap-southeast-2.amazonaws.com/bc-public-releases/AWS-Lego/Alpha/Create-CompleteReferenceTopology.ps1

Open Powershell ISE (or just Powershell) and run Create-CompleteReferenceTopology.ps1

You will be prompted for required details.


<h3>Chef? Puppet?</h3>
May be supported later. AWS Launch Configuration has been chosen first as it allows the a