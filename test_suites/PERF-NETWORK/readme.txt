This test case forked from RHEL7-88713.

QE may be compared the results with AWS Linux releases, and/or may be with previous RHEL releases.

This case verifies the bandwidth for which instance type has declared their KPI in Amazon Console.
The scripts valides both ENA and Intel 82599 VF Interface.

SPEC:
https://www.ec2instances.info/?region=us-west-2

Test Scope:
All the IPv6 supported instance types which has specified SPEC on network performance.

