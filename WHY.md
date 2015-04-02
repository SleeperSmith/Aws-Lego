Why use Aws-Lego
========

For the end users (startups, businesses, corporates, etc), there's always this long arduous journey of going from clicking up your infrastructure > to the mayhem of pieces being everywhere and anywhere > finally (if given the resource) to tidy things up. The ammount of things to manage and consider, contrary to popular belief, is tremendous.

So, if software can be open sourced, why not infrastructure that has been written as code? An infrastructure and software topology, free, open source, ready to go, with all the points and best practices considered:

1. Immutable infrastructure with snapshot based and/or ASG rotation based migration / upgrade path.
2. Infrastructure as code that can be version controlled and continuously deployed and changes tracked.
3. Cross availability zone and cross region compatible. Same set of templates and scripts that can truly utilise AWS's global pressense.
4. Even stronger isolation of network concerns than the AWS's recommended VPC setup; in and out bound traffic enabled public subnet for ELB and out bound traffic only public subnet for NAT are just the tip of the iceberg.
5. Vendor supported topology in the future. Gone will be the days of going through tutorials, production deployment whitepapers, network redesign and adjustment, trouble shooting, and a few years later the headache of upgrade/migrations.
6. Just plain save time!!

For the FOSS projects and software vendors, this will provide a ground of reference for creating deployment materials (scripts, templates, etc). AWS-Lego provides a semantic for automatically deriving infrastructure related information from CloudFormation. Where's the Zookeeper endpoint? Where's the private subnet with RDS subnet group? What ports are open/allowed between what subnets? With a standard deployment topology adopted, it will be possible for FOSS projects and software vendors to publish deployment setup and methdology with confidence. They would know that the infrastructure and environment they have tested in will be similar, if not exactly the same as the end users.

<h2>But Chef and Puppet already does this?</h2>
And no it doesn't. Chef and Puppet covers a very small part of what AWS-Lego try to achieve on AWS:  
1. Networking; subnets, routing, ACL, firewall
2. Migration and immutable infrastructure; DB Snapshot, State and Data repository such as S3 and DynamoDB
3. Automatic scaling, self healing and cloudwatch alerting and monitoring.
4. Lastly, stringing all of the previous points and encapsulating that in a single self suffecient pagack that is natively supported by AWS.

In fact, AWS-Lego will aim to support Chef and Puppet in place of AWS Launch Configuration in the future.