#!/usr/bin/env bash
# A simple script for Amazon EC2 to monitor another HA node and take over a Virtual IP (VIP)
# if the service on the other node fails

# The script is inspired by the following article:
# - Leveraging Multiple IP Addresses for Virtual IP Address Fail-over in 6 Simple Steps
#   http://aws.amazon.com/articles/2127188135977316

# The two instances must have both two Network Interfaces and an Elastic IP on the primary interface
# On the secondary interface there should be a single Elastic IP only on one of the two instances
# That Elastic IP is the VIP moved between the instances and is identified by the AllocationID

# Time in seconds between checks
Check_Time=2

# Time to wait during a take over to start checking again
Take_Over_Time=60

# Timeout in seconds depending on the tool/protocol to test
Timeout_ping=5
Timeout_nc=5
Timeout_wget=5

# High Availability IP variables
# Other node's IP to ping, TCP Port, HTTP URL to check, and EIP Allocation ID to swap if other node goes down
Other_Node_IP=X.X.X.X
Other_Node_Port=80
Other_Node_URL=http://${Other_Node_IP}:${Other_Node_Port}/
AllocationID=eipalloc-1234abcd

# Specify the EC2 Region that this will be running in
Region=eu-west-1

# Run aws-apitools-common.sh to set up default enviornment variables and to
# leverage AWS security credentials provided by EC2 roles
. /etc/profile.d/aws-apitools-common.sh

InstanceID=`/opt/aws/bin/ec2-metadata -i|cut -d " " -f2`
NetworkInterface=`/opt/aws/bin/ec2-describe-network-interfaces --region eu-west-1 -F "attachment.instance-id=${InstanceID}"|grep ^NETWORKINTERFACE|grep -v Primary|cut -f2`

function take_over_vip {
    echo `date` "-- HA heartbeat failed, taking over VIP"
    /opt/aws/bin/ec2-associate-address --region ${Region} --allow-reassociation -a ${AllocationID} -n ${NetworkInterface}
}

function check_if {
    "$@"
    status=$?
    if [ $status -ne 0 ]; then
	echo "check failed for: $1"
	take_over_vip
	sleep ${Take_Over_Time}
    fi
    return $status
}

echo `date` "-- Starting HA monitor"
while [ . ]; do
  # You can comment out the checks that you don't need depending on the service/protocol to monitor
  # ICMP -> ping
  # TCP -> nc
  # HTTP/HTTPS -> wget
  check_if ping -c 3 -W ${Timeout_ping} ${Other_Node_IP}
  check_if nc -w ${Timeout_nc} -z ${Other_Node_IP} ${Other_Node_Port}
  check_if wget -q -T ${Timeout_wget} -t 3 -O /dev/null --no-cache ${Other_Node_URL}
  sleep ${Check_Time}
done

