#!/bin/bash

rhel_summary=$(mktemp) && echo "Red Hat Enterprise Linux" >> $rhel_summary
amzn_summary=$(mktemp) && echo "Amazon Linux" >> $amzn_summary

./summary.sh ./RHEL7-88713rht >> $rhel_summary
./summary.sh ./RHEL7-88713amz >> $amzn_summary

vimdiff $rhel_summary $amzn_summary
#diff $rhel_summary $amzn_summary > compare_boot_time.report

rm $rhel_summary $amzn_summary

exit 0

