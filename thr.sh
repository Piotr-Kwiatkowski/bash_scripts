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

# FIRST ARGUMENT INCLUDES SUBSTRING stp
if [[ "$1" =~ *"stp"* ]]; then
   echo "$1 is not a proper stp name"
   exit 2
fi

printf "Executing command: \"tgr $STP_NAME $NR_OF_JOBS\"\n"
OUTPUT=`tgr $STP_NAME $NR_OF_JOBS`

if [[ "$OUTPUT" == "No hits" ]]; then
   printf "\n\ttgr command returned \"No hits\" - try different value of jobs\n\n"
   exit 4
fi

printf "Parsing tgr output... (this may take a while)\n"
# LOOP FOR EVERY LINE OF OUTPUT
while read -r O_LINE; do
   if [[ $O_LINE =~ [0-9]{8} ]]; then  # FIRST 8 DIGITS IN A LINE ARE NUMBERS
      JOB_NUMBER=${O_LINE:0:8}         # CUT FIRST 8 DIGITS FROM A LINE (job number)
      printf "\nJob number: $JOB_NUMBER\n"
      # RETRIEVE LINK TO JCAT LOGS
      JCAT_LINK=$(tgr $JOB_NUMBER | grep -s "Screen log (link)")
      IFS='h' read -r PRE REST <<< "$JCAT_LINK"  # DELETE SUBSTRING BEFORE LETTER h
      JCAT_LINK="h${REST}"
      JCAT_LINK=${JCAT_LINK%txt*}  # DELETE TRASH AT THE END OF STRING
      JCAT_LINK="${JCAT_LINK}txt"
      WEB_CONTENT=$(wget $JCAT_LINK -q -O -)  # RETRIEVE WEB CONTENT USING LINK
      if [[ -z $WEB_CONTENT ]]; then
         printf "No web content returned\n"
         continue
      fi

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
