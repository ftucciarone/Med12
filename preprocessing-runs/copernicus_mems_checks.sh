#!/bin/bash
# Source the parameters
source tools_date.sh


# ###########################################################################################################
#
# Mandatory arguments check
#
# ###########################################################################################################
if [ "$#" -lt 4 ] || [ "$1" != "-dl" ] || [ "$3" != "-pr" ]; then
    echo " " 
    echo "Usage: ./copernicus_get-and-process.sh -dl true/false -pr true/false -fd YYYY-MM-DD -ld YYYY-MM-DD -cl"
    echo "      where"
    echo "             -dl (true/false): option to download the files"
    echo "             -pr (true/false): option to process the data"
    echo "             -fd (YYYY-MM-DD): first day to process"
    echo "             -ld (YYYY-MM-DD): last day to process"
    echo "             -cl             : option to clean the data"
    echo " " 
    # Check if first argument is the download flag
    if [ "$1" != "-dl" ]; then
        echo " Warning, download flag -dl not found:" $1
    fi

    # Check if second argument is the either true or false
    if !([ "$2" == "false" ] || [ "$2" == "true" ]) ; then
        echo " Warning,   download switch is not a boolean (true/false):" $2
    fi

    # Check if third argument is the download flag
    if [ "$3" != "-pr" ]; then
        echo " Warning, download flag -pr not found:" $3
    fi

    # Check if second argument is the either true or false
    if !([ "$4" == "false" ] || [ "$4" == "true" ]) ; then
        echo " Warning, processing switch is not a boolean (true/false):" $4
    fi

    exit -1
fi

# Check if second argument is the either true or false
if !([ "$2" == "false" ] || [ "$2" == "true" ]) ; then
    echo " Warning,   download switch is not a boolean (true/false):" $2
    exit -1
fi

# Check if second argument is the either true or false
if !([ "$4" == "false" ] || [ "$4" == "true" ]) ; then
    echo " Warning, processing switch is not a boolean (true/false):" $4
    exit -1
fi


# ###########################################################################################################
#
# Optional arguments check
#
# ###########################################################################################################
# Check if 5th argument is -fd and 6th is non-empty
if [ "$5" == "-fd" ] && [ ! -z "$6" ]; then
    if [[ $6 == ????-??-?? ]] || [[ $6 == ???????? ]]; then
	firstDate=$($datecommand -d $6 +%Y-%m-%d)
    else
        echo " Error: first day (-fd) is not a valid date. Use YYYY-MM-DD or YYYYMMDD format "
    fi
# Check if 5th argument is -ld and 6th is non-empty
elif [ "$5" == "-ld" ] && [ ! -z "$6" ]; then
    if [[ $6 == ????-??-?? ]] || [[ $6 == ???????? ]]; then
	lastDate=$($datecommand -d $6 +%Y-%m-%d)
    else
        echo " Error: last day (-ld) is not a valid date. Use YYYY-MM-DD or YYYYMMDD format "
    fi
fi
# Check if 7th argument is -ld and 8th is non-empty
if [ "$7" == "-ld" ] && [ ! -z "$8" ]; then
    if [[ $8 == ????-??-?? ]] || [[ $8 == ???????? ]]; then
	lastDate=$($datecommand -d $8 +%Y-%m-%d)
    else
        echo " Error: first day (-ld) is not a valid date. Use YYYY-MM-DD or YYYYMMDD format "
    fi
fi
# Check if lastDate is after firstDate, otherwise the whole thing will fail
if [[ "$firstDate" > "$lastDate" ]]; then
    echo "error: cannot work"
fi
#echo $firstDate $lastDate
#exit

