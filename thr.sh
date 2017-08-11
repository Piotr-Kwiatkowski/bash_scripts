#!/bin/bash

   ###########################################
   #                                         #
   #   Script for gaining throughput value   #
   #      from jcat logs for n last jobs     #
   #                                         #
   ###########################################
   #                                         #
   #   Author: Piotr Kwiatkowski             #
   #   Date:   2017-08-08                    #
   #                                         #
   ###########################################


STP_NAME="$1"
NR_OF_JOBS="$2"

# ARGUMENT FOR STP OR JOBS NOT GIVEN
if [ -z "$1" ] || [ -z "$2" ]; then
   printf "\n\tUsage:\t   $0 [stp name] [number of jobs]\n\tExample:   $0 listp4927 15\n\n\tNOTE:\tgitenv.csh must be sourced!\n\n"
   exit 1
fi

# STP == Ottawa
if [[ "$1" =~ ki* ]]; then
   printf "\n\tOttawa not supported yet\n\n"
   exit 2
fi

printf "Executing command: \"tgr $STP_NAME $NR_OF_JOBS\"\n"
OUTPUT=`tgr $STP_NAME $NR_OF_JOBS`

if [[ "$OUTPUT" == "No hits" ]]; then
   printf "\n\ttgr command returned \"No hits\" - try different value of jobs\n\n"
   exit 3
fi

printf "Parsing tgr output... (this may take a while)\n"
# LOOP FOR EVERY LINE OF OUTPUT
while read -r oline; do   
   if [[ $oline =~ [0-9]{8} ]]; then  # FIXME: magic numbers
      JOB_NUMBER=${oline:0:8}         # CUT FIRST 8 DIGITS FROM A LINE (job number)
      printf "\nJob number $JOB_NUMBER:\n"
      # RETRIEVE LINK TO JCAT LOGS
      if [[ "$1" =~ li* ]]; then     # FOR LINKOPING STP
         JCAT_LINK=$(tgr $JOB_NUMBER | grep -s "Screen log (link)" | cut -b22-114)   # FIXME: magic numbers
      elif [[ "$1" =~ ot* ]]; then   # FOR OTTAWA STP
         JCAT_LINK=$(tgr $JOB_NUMBER | grep -s "Screen log (link)" | cut -b22-117)   # FIXME: magic numbers
      # elif [[ "$1" =~ ki* ]]; then   # TODO: FOR KISTA STP
         # JCAT_LINK=$(tgr $JOB_NUMBER | grep -s "Screen log (link)" | cut -b22-117)   # FIXME: magic numbers
         # exit 5
      fi
      WEB_CONTENT=$(wget $JCAT_LINK -q -O -)   # RETRIEVE WEB CONTENT USING LINK
      while read -r WLINE; do
         if [[ $WLINE == *"DL LTESim IPEX"* ]]; then
            printf "\t$WLINE\n"
         elif [[ $WLINE == *"UL LTESim IPEX"* ]]; then
            printf "\t$WLINE\n"
         fi
      done <<< "$WEB_CONTENT"
   fi
done <<< "$OUTPUT"

printf "\n"
exit 0
