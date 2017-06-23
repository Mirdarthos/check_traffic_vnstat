#!/bin/bash
# ******************************************************************************************************************** #
# Written by Charl Loubser.
# I wrote this, because sometimes you just need to monitor network traffic. Wheter it is internet
# or any other network. I have scoured the internet for something the can do the job, but, to my
# suprise, couldn't find anything. So I made the descisin to do this. It is also my first bash script,
# and therefore might be riddled with errors.
#
# Arguments:
#    * -w: Incoming Speed Warning
#    * -c: Incoming speed Critical
#    * -W: Outgoing speed Warning
#    * -C: Outgoing speed Critical
#    * -i: Interface this should monitor
#    * -p: Whether the script should provide performance data or not. PLEASE NOTE: The more network interfaces present, the longer the check
#             will take if Performance Data is neccesary to be retrieved.
#    * -m: 	REQUIRED WITH -p OPTION. Method to use to get the interfaces list for retrieving perfomance data.
#
# Please Note:
# The units you specify the warnings/critical in must be the same units as "/etc/vnstat.conf"
# is configured to use, otherwise the script will not work correctly, and eveything would give incorrect
# information
#
# Usage:
# ./check_traffic_vnstat.sh -w <incomingwarning> -W <outgoingwarning> -c <incomingcritical> -C <outgoingcritical> -i <interface> -p
#
# ******************************************************************************************************************** # 
function unit_to_kib() {
	local AMOUNT=$1
	local FROMUNIT=$2
	if [ $FROMUNIT == "KiB" ]; then
		CONVERTED_AMOUNT=$AMOUNT
		echo $(bc -l <<< "scale=2;$CONVERTED_AMOUNT")
	elif [ $FROMUNIT == "kB" ]; then
		CONVERTED_AMOUNT=$(bc -l <<< "scale=2;$AMOUNT*0.976562")
		echo $(bc -l <<< "scale=2;$CONVERTED_AMOUNT")
	elif [ $FROMUNIT == "kbit" ]; then
		CONVERTED_AMOUNT=$(bc -l <<< "scale=2;$AMOUNT*0.12207")
		echo $(bc -l <<< "scale=2;$CONVERTED_AMOUNT")
	elif [ $FROMUNIT == "MiB" ]; then
		CONVERTED_AMOUNT=$(bc -l <<< "scale=2;$AMOUNT*1024")
		echo $(bc -l <<< "scale=2;$CONVERTED_AMOUNT")
		elif [ $FROMUNIT == "Mbit" ]; then
		CONVERTED_AMOUNT=$(bc -l <<< "scale=2;$AMOUNT*122.07")
		echo $(bc -l <<< "scale=2;$CONVERTED_AMOUNT")
	elif [ $FROMUNIT == "mbit" ]; then
		CONVERTED_AMOUNT=$(bc -l <<< "$scale=2;$AMOUNT*122.07")
		echo $(bc -l <<< "scale=2;$CONVERTED_AMOUNT")
	else
		return 2
	fi
}

#Help function
function HELP {
	echo ""
	echo "Written by Charl Loubser."
	echo "I wrote this, because sometimes you just need to monitor network traffic. Wheter it is internet"
	echo "or any other network. I have scoured the internet for something the can do the job, but, to my"
	echo "suprise, couldn't find anything. So I made the descisin to do this. It is also my first bash script,"
	echo "and therefore might be riddled with errors."
	echo ""
	echo "Arguments:"
	echo "   * -w: Incoming Speed Warning (KiB/s)"
	echo "   * -c: Incoming speed Critical (KiB/s)"
	echo "   * -W: Outgoing speed Warning (KiB/s)"
	echo "   * -C: Outgoing speed Critical (KiB/s)"
	echo "   * -i: Interface this should monitor"
	echo "   * -p: Whether the script should provide performance data or not. PLEASE NOTE: The more network interfaces present, the longer the check"
	echo "           will take if Performance Data is neccesary to be retrieved."
	echo "   * -m: REQUIRED WITH -p OPTION. Method to use to get the interfaces list for retrieving perfomance data."
	echo ""
	echo "Please Note:"
	echo "The units you specify the warnings/critical in must be the same units as \"/etc/vnstat.conf\""
	echo "is configured to use, otherwise the script will not work correctly, and eveything would give incorrect"
	echo "information"
	echo ""
	echo "Usage:"
	echo "./check_traffic_vnstat.sh -w <incomingwarning> -W <outgoingwarning> -c <incomingcritical> -C <outgoingcritical> -i <interface> -p"
	echo ""
  exit 1
}

# Parse the options from the command line
while getopts :w:W:c:C:i:hpm: FLAG; do
  case $FLAG in
    w)
      INWARNING=$OPTARG
      ;;
    c) 
      INCRITICAL=$OPTARG
      ;;
    W)
      OUTWARNING=$OPTARG
      ;;
    C)
      OUTCRITICAL=$OPTARG
      ;;
	i)
	  INTERFACE=$OPTARG
	  ;;
	p)
		PERFORMANCE_DATA=true
	;;
    h)  #show help
      HELP
      ;;
    \?) #unrecognized option - show help
      echo "Option -${BOLD}$OPTARG${NORM} not allowed."
      HELP 
      ;;
  esac
done

VNSTATEXEC="/usr/bin/vnstat"
VNSTATCMD="$VNSTATEXEC -i $INTERFACE -tr" 
vnstatoutput=$($VNSTATCMD)

reqrxspeed=$(echo $vnstatoutput | grep -o 'rx \(.*\)' |  cut -c 3- | awk '{print $1}')
reqrxspeedunit=$(echo "$vnstatoutput" | grep -o 'rx \(.*\)' |  cut -c 3- | awk '{print $2}' | cut -c -4)
reqrxspeedunit=$(echo $reqrxspeedunit | sed 's:/*$::')
reqrxspeedkib=$(unit_to_kib "$reqrxspeed" "$reqrxspeedunit")
# if less than 1, put 0 in front of it so that it doesn't start with a "."
if (( $(bc <<< "$reqrxspeedkib < 1") )); then
	reqrxspeedkib="0"$reqrxspeedkib
fi

reqtxspeed=$(echo "$vnstatoutput" | grep -o 'tx \(.*\)'|  cut -c 3- | awk '{print $1}')
reqtxspeedunit=$(echo "$vnstatoutput" | grep -o 'tx \(.*\)'|  cut -c 3- | awk '{print $2}' | cut -c -4)
reqtxspeedunit=$(echo $reqtxspeedunit | sed 's:/*$::')
reqtxspeedkib=$(unit_to_kib "$reqtxspeed" "$reqtxspeedunit")
# if less than 1, put 0 in front of it so that it doesn't start with a "."
if (( $(bc <<< "$reqtxspeedkib < 1") )); then
	reqtxspeedkib="0"$reqtxspeedkib
fi

#Compare the values to the warning and critical values and perform neccesary actions
#The critical errors
CRITICALS=0

if (( $(bc <<< "scale=2;$reqrxspeedkib >= $INCRITICAL") )); then
	EXTRAMESSAGE="The current Receiving Rate (RX) of $reqrxspeed$reqrxspeedunit/s  ("$reqrxspeedkib"KiB/s) is exceeding the critical threshold of $INCRITICAL""KiB/s"
	(( CRITICALS++ ))
fi

if (( $(bc <<< "scale=2;$reqtxspeedkib >= $OUTCRITICAL") )); then
	EXTRAMESSAGE="The current Transmit Rate (TX) of $reqtxspeed$reqtxspeedunit/s  ("$reqtxspeedkib"KiB/s) is exceeding the critical threshold of $OUTCRITICAL""KiB/s"
	(( CRITICALS++ ))
fi

WARNINGS=0
#Warnings
if (( $(bc <<< "scale=2;$reqrxspeedkib >= $INWARNING") )) && (( $CRITICALS == 0 )); then
	EXTRAMESSAGE="The current Receiving Rate (RX) of $reqrxspeed$reqrxspeedunit/s  ("$reqrxspeedkib"KiB/s) is exceeding the warning threshold of $INWARNING""KiB/s"
	(( WARNINGS++ ))
fi

if (( $(bc <<< "scale=2;$reqtxspeedkib >= $OUTWARNING") )) && (( $CRITICALS == 0 )); then
	EXTRAMESSAGE="The current Transmit Rate (TX) of $reqtxspeed$reqtxspeedunit/s  ("$reqtxspeedkib"KiB/s) is exceeding the warning threshold of $OUTWARNING""KiB/s"
	(( WARNINGS++ ))
fi

if (( $CRITICALS > 0 )); then
	TRAFFICSTATUS="TRAFFIC CRITICAL"
	RXSTATUS="The current Receiving Rate (RX) of $INTERFACE is $reqrxspeed$reqrxspeedunit/s ("$reqrxspeedkib"KiB/s)"
	TXSTATUS="The current Transmit Rate (TX) of $INTERFACE is $reqtxspeed$reqtxspeedunit/s ("$reqtxspeedkib"KiB/s)"
	EXITCODE=2
fi

if (( $WARNINGS > 0 )) && (( $CRITICALS == 0 )); then
	TRAFFICSTATUS="TRAFFIC WARNING"
	RXSTATUS="The current Receiving Rate (RX) of $INTERFACE is $reqrxspeed$reqrxspeedunit/s ("$reqrxspeedkib"KiB/s)"
	TXSTATUS="The current Transmit Rate (TX)  of $INTERFACE is $reqtxspeed$reqtxspeedunit/s ("$reqtxspeedkib"KiB/s)"
	EXITCODE=1
fi

if (( $WARNINGS == 0 )) && (( $CRITICALS == 0 )); then
	TRAFFICSTATUS="TRAFFIC OK"
	RXSTATUS="The current Receiving Rate (RX) of $INTERFACE is $reqrxspeed$reqrxspeedunit/s ("$reqrxspeedkib"KiB/s)"
	TXSTATUS="The current Transmit Rate (TX) of $INTERFACE is $reqtxspeed$reqtxspeedunit/s ("$reqtxspeedkib"KiB/s)"
	EXITCODE=0
fi

# If requested, add necessary Performance Data
REQUESTED_INTERFACE=$INTERFACE
if [ $PERFORMANCE_DATA ]; then
	ALL_INTERFACES=$(ls /sys/class/net)
	ALL_INTERFACES_ARRAY=$(echo "$ALL_INTERFACES" | tr ' ' "\n")
	TXSTATUS+="| "
	for INTERFACE in $ALL_INTERFACES_ARRAY
	do
	if [[  "$INTERFACE" != "lo"  ]]; then
		if [[ "$INTERFACE" == "$REQUESTED_INTERFACE" ]]; then
			TXSTATUS+="$INTERFACE-rx-rate=$reqrxspeed;$INWARNING;$INCRITICAL; $INTERFACE-tx-rate=$reqtxspeed;$OUTWARNING;$OUTCRITICAL; "
		else
		VNSTATCMD="vnstat -i $INTERFACE -tr" 
		vnstatoutput=$($VNSTATCMD)	
		rxspeed=$(echo "$vnstatoutput" | grep -o 'rx \(.*\)' |  cut -c 3- | awk '{print $1}')
		txspeed=$(echo "$vnstatoutput" | grep -o 'tx \(.*\)'|  cut -c 3- | awk '{print $1}')
		
		TXSTATUS+="$INTERFACE-rx-rate=$rxspeed;;; $INTERFACE-tx-rate=$txspeed;;; "
		fi
	fi
	done	
fi


if [ $EXITCODE -eq 0 ] || [ $EXITCODE -eq 1 ] || [ $EXITCODE -eq 2 ]; then
	echo "$TRAFFICSTATUS"
	echo "$RXSTATUS"
	echo "$TXSTATUS"
else 
	EXITCODE=3
fi


if [ -z "${EXTRAMESSAGE-}" ] && [ "${EXTRAMESSAGE+xxx}" != "xxx" ]; then
	echo "$EXTRAMESSAGE"
fi

exit $EXITCODE
