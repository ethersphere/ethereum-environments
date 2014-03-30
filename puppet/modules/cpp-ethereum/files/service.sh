#!/bin/bash
ETHHOME=/home/ethereum/
LOG=${ETHHOME}/eth.log
ETH=/usr/local/bin/eth
while [ 1 ]; do
  if [ -f $LOG ] && sudo -u ethereum mv $LOG $LOG-\$(date +"%Y%m%d-%H$%M%S")
  sudo -u ethereum $ETH -o peer -x 256 -l 30303 -m on -v 1 > $LOG
done
