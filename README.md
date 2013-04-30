ec2-watchdog
============

A simple script for Amazon EC2 to monitor another HA node and take over a Virtual IP (VIP) if the service on the other node fails.

The script is inspired by the following article:

[Leveraging Multiple IP Addresses for Virtual IP Address Fail-over in 6 Simple Steps](http://aws.amazon.com/articles/2127188135977316)

One of the main differences is that here you can check that a service is working on the other node with different protocols, i.e. using ICMP, TCP and/or HTTP/HTTPS.

The two instances must have both two Network Interfaces and an Elastic IP on the primary interface.
On the secondary interface there should be a single Elastic IP on one of the two instances.
That Elastic IP is the VIP moved between the instances and is identified by the AllocationID.

Please look at the script for parameters and options.
