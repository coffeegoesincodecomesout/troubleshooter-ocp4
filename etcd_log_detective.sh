#!/bin/bash

#
# Author : Peter Ducai <peter.ducai@gmail.com>
# Homepage : https://github.com/peterducai/troubleshooter-ocp4
# License : GPL3
# Copyright (c) 2022, Peter Ducai
# All rights reserved.
#

# Purpose : ETCD logs analyzer and merger
# Usage : etcd_log_analyzer.sh for more options


# TERMINAL COLORS -----------------------------------------------------------------

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BLACK='\033[30m'
BLUE='\033[34m'
VIOLET='\033[35m'
CYAN='\033[36m'
GREY='\033[37m'

color=('\033[34m' '\033[37m' '\033[01;31m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m' '\033[00m')

#TIMELINE='2022-10-13T10'
TIMELINE='2022-10-10T1'
ETCD_NS='openshift-etcd'
MUST_PATH=$1
ORIG_PATH=$(pwd)
OUTPUT_PATH=$ORIG_PATH/DATA

mkdir -p $OUTPUT_PATH



# PARSER --------------------------------------------------------------------------

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -a|--my-boolean-flag)
      MY_FLAG=0
      shift
      ;;
    -b|--my-flag-with-argument)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        MY_FLAG_ARG=$2
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

#---------------------------------------------------------------------------------


echo -e "OVERLOADED = leader failed to send out heartbeat on time; took too long, leader is overloaded likely from slow disk"
echo -e ""





# MAIN --------------------------

cd $MUST_PATH
cd $(echo */)
cd namespaces/$ETCD_NS/pods

etcd_check() {
    i=0
    
    for member in $(ls |grep -v "revision"|grep -v "quorum"); do
      echo "processing $member"
      echo -e "" > $OUTPUT_PATH/$member.log
      cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'overloaded'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} OVERLOADED     [$member] !!!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      # cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'took too long'|cut -d ' ' -f1| \
        # xargs -I {} echo -e "{} took too long  [$member]" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'leader'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} LEADER changed [$member] !" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'clock'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} NTP clock difference [$member] !!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      cat $member/etcd/etcd/logs/current.log |grep "$TIMELINE"|grep 'buffer'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} BUFF [$member] !!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$member.log; done
      #increment color
      i=$((${i}+1))
    done
    i=0
    cat $OUTPUT_PATH/etcd*.log > $OUTPUT_PATH/output_etcd_logs.log
    sort -t:  -k2 -k3 $OUTPUT_PATH/output_etcd_logs.log > $OUTPUT_PATH/sorted.tmp
    cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_etcd_logs.log
}

router_check() {
    i=0
    
    for router in $(ls); do
      echo "processing $router"
      echo -e "" > $OUTPUT_PATH/$router.log
      cat $router/router/router/logs/current.log |grep "$TIMELINE"|grep 'Unexpected watch close'|cut -d ' ' -f1| \
        xargs -I {} echo -e "{} Unexpected watch close     [$router] !!!" | while read -r line; do echo -e "$YELLOW$line$NONE" >> $OUTPUT_PATH/$router.log; done
      # cat $member/router/router/logs/current.log |grep "$TIMELINE"|grep 'took too long'|cut -d ' ' -f1| \
        # xargs -I {} echo -e "{} took too long  [$router]" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$router.log; done
      # cat $member/router/router/logs/current.log |grep "$TIMELINE"|grep 'leader'|cut -d ' ' -f1| \
      #   xargs -I {} echo -e "{} LEADER changed [$router] !" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$router.log; done
      # cat $member/router/router/logs/current.log |grep "$TIMELINE"|grep 'clock'|cut -d ' ' -f1| \
      #   xargs -I {} echo -e "{} NTP clock difference [$router] !!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$router.log; done
      # cat $member/router/router/logs/current.log |grep "$TIMELINE"|grep 'buffer'|cut -d ' ' -f1| \
      #   xargs -I {} echo -e "{} BUFF [$router] !!" | while read -r line; do echo -e "${color[$i]}$line$NONE" >> $OUTPUT_PATH/$router.log; done
      #increment color
      i=$((${i}+1))
    done
    i=0
    cat $OUTPUT_PATH/router*.log > $OUTPUT_PATH/output_router_logs.log
    sort -t:  -k2 -k3 $OUTPUT_PATH/output_router_logs.log > $OUTPUT_PATH/sorted.tmp
    cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_router_logs.log
}

stackinfra_check() {
    i=0
    
    for keepalived in $(ls |grep master|grep -v "coredns"|grep -v "haproxy"); do
      echo "processing $keepalived"
      echo -e "" > $OUTPUT_PATH/$keepalived.log
      cat $keepalived/keepalived/keepalived/logs/current.log |grep "$TIMELINE"|grep 'Entering'| \
        xargs -I {} echo -e "{}      [$keepalived] !!!" | while read -r line; do echo -e "$YELLOW$line$NONE" >> $OUTPUT_PATH/$keepalived.log; done
      #increment color
      i=$((${i}+1))
    done
    i=0
    cat $OUTPUT_PATH/keepalived*.log > $OUTPUT_PATH/output_keepalived_logs.log
    sort -t:  -k2 -k3 $OUTPUT_PATH/output_keepalived_logs.log > $OUTPUT_PATH/sorted.tmp
    cat $OUTPUT_PATH/sorted.tmp > $OUTPUT_PATH/output_keepalived_logs.log
}


etcd_check

cd ../../..
cd namespaces/openshift-ingress/pods

router_check

cd ../../..
cd namespaces/openshift-openstack-infra/pods

stackinfra_check

clear

cd $OUTPUT_PATH
cat $OUTPUT_PATH/output_keepalived_logs.log $OUTPUT_PATH/output_router_logs.log $OUTPUT_PATH/output_etcd_logs.log > $OUTPUT_PATH/output_logs.log
sort -tT -k2 -k3 $OUTPUT_PATH/output_logs.log