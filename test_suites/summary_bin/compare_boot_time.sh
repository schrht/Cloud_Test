#!/bin/bash

rhel_summary=$(mktemp) && echo "Red Hat Enterprise Linux" >> $rhel_summary
ubtl_summary=$(mktemp) && echo "Ubuntu Linux" >> $ubtl_summary

./summary.sh ./RHEL7-93100rht >> $rhel_summary
./summary.sh ./RHEL7-93100ubt >> $ubtl_summary

vimdiff $rhel_summary $ubtl_summary
#diff $rhel_summary $ubtl_summary > compare_boot_time.report

rm $rhel_summary $ubtl_summary

exit 0

