#!/usr/bin/env bash

# Description:
# Check the dmesg outputs
#
# Inputs:
# $@ - dmesg log file(s)

#DEBUG="YES"

function remove_pattern()
{
	# $1 - pattern for removing

	num=$(grep -c -e "$1" $logfile)
	cat $logfile | grep -v -e "$1" > ${logfile}.tmp && mv ${logfile}.tmp $logfile || exit 1
	printf "> %4s lines were removed with pattern \"%s\"\n" "$num" "$1"
}


[ $# -lt 1 ] && echo -e "Usage: $0 <dmesg logs> \nExample: $0 ./RHEL*/dmesg*.log" && exit 1

logfile="./check_dmesg.log"

echo "Get dmesg logs..."
grep "dmesg -l warn" -B 1000 $@ | grep -v "dmesg -l warn" > $logfile || exit 1
[ "$DEBUG" = "YES" ] && cat $logfile && echo

echo "Remove the titles..."
grep -v -e "dmesg -l \w" $logfile > ${logfile}.tmp && mv ${logfile}.tmp $logfile || exit 1
grep -v -e "-----------" $logfile > ${logfile}.tmp && mv ${logfile}.tmp $logfile || exit 1
[ "$DEBUG" = "YES" ] && cat $logfile && echo

echo "Remove empty lines..."
grep -v -e "-$" $logfile > ${logfile}.tmp && mv ${logfile}.tmp $logfile || exit 1
grep -v -e "^$" $logfile > ${logfile}.tmp && mv ${logfile}.tmp $logfile || exit 1
echo "" >> $logfile	# add protecting line so that the file will never be empty
[ "$DEBUG" = "YES" ] && cat $logfile && echo

echo "Remove harmless messages..."
remove_pattern "piix4_smbus .* SMBus base address uninitialized - upgrade BIOS or use force_addr=0xaddr"
remove_pattern "ACPI PCC probe failed."
remove_pattern "Cannot get hvm parameter CONSOLE_EVTCHN (18)"
[ "$DEBUG" = "YES" ] && cat $logfile && echo

echo "Remove known issues..."
remove_pattern "tsc: Fast TSC calibration failed"
remove_pattern "nouveau 0000:00:.*.0: unknown chipset (.*)"
remove_pattern "nouveau 0000:00:.*.0: DRM: Pointer to TMDS table invalid"
remove_pattern "nouveau 0000:00:.*.0: bus: MMIO read of 00000000 FAULT at.*IBUS"
[ "$DEBUG" = "YES" ] && cat $logfile && echo

echo -e "\nPlease check the results in output file: $logfile\n"

exit 0

