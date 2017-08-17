#!/bin/bash

   ###########################################
   #                                         #
   #   Script for gaining throughput value   #
   #      from jcat logs for n last jobs     #
   #                                         #
   ###########################################
   #                                         #
   #   Author:      Piotr Kwiatkowski        #
   #   Created:     2017-08-08               #
   #   Last update: 2017-08-16               #
   #                                         #
   ###########################################


STP_NAME="$1"
NR_OF_JOBS="$2"

# ARGUMENT FOR STP OR JOBS NOT GIVEN
if [ -z "$1" ] || [ -z "$2" ]; then
   printf "\n\tUsage:\t   $0 [stp name] [number of jobs]\n\tExample:   $0 listp4927 15\n\n\tNOTE:\tgitenv.csh must be sourced!\n\n"
   exit 1
fi

# FIRST ARGUMENT DOES NOT INCLUDE SUBSTRING stp
if [[ "$1" != *"stp"* ]]; then
   printf "\n\t$1 is not a proper stp name\n\n"
   exit 2
fi

# SECOND ARGUMENT CONTAINS NON-DIGITS
#if [[ "$2" != ^[^0-9]+$ ]]; then
#   printf "\n\t$2 is not a proper number of jobs\n\n"
#   exit 3
#fi

printf "Executing command: \"tgr $STP_NAME $NR_OF_JOBS\"\n"

# GAIN RESULTS FROM tgr
OUTPUT=`tgr $STP_NAME $NR_OF_JOBS`
if [[ "$OUTPUT" == "No hits" ]]; then
   printf "\n\ttgr command returned \"No hits\" - try different value of jobs\n\n"
   exit 4
fi

printf "Parsing tgr output... (this may take a while)\n"

# ITERATE OVER LINES OF tgr OUTPUT
while read -r O_LINE; do
   # IF FIRST 8 DIGITS IN A LINE ARE NUMBERS
   if [[ $O_LINE =~ [0-9]{8} ]]; then
      # CUT FIRST 8 DIGITS FROM A LINE (job number)
      JOB_NUMBER=${O_LINE:0:8}
      printf "\nJob number: $JOB_NUMBER\n"

      # RETRIEVE LINK TO JCAT LOGS
      JCAT_LINK=$(tgr $JOB_NUMBER | grep -s "Screen log (link)")
      
      # DELETE SUBSTRING BEFORE LETTER h
      IFS='h' read -r PRE REST <<< "$JCAT_LINK"
      JCAT_LINK="h${REST}"
      
      # DELETE TRASH AT THE END OF STRING
      JCAT_LINK=${JCAT_LINK%txt*}
      JCAT_LINK="${JCAT_LINK}txt"

      # RETRIEVE WEB CONTENT USING JCAT LINK
      WEB_CONTENT=$(wget $JCAT_LINK -q -O -)
      if [[ -z $WEB_CONTENT ]]; then
         printf "No web content returned\n"
         continue
      fi

      # PARSING FOR DL/UL VALUE
      while read -r W_LINE; do
         if [[ $W_LINE == *"DL LTESim IPEX"* ]]; then
            printf "\t$W_LINE\n"
         elif [[ $W_LINE == *"UL LTESim IPEX"* ]]; then
            printf "\t$W_LINE\n"
         fi
      done <<< "$WEB_CONTENT"
   fi
done <<< "$OUTPUT"

printf "\n"
exit 0
