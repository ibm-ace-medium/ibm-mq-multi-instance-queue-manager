#!/bin/bash

install() {
  local qmgrName=$1
  local qmgrPort=$2
  local mqAdminsGroup=$3
  local logFilesDirectory=$4
  local dataFilesDirectory=$5

  echo "Create data files directory."
  mkdir -p ${dataFilesDirectory}
  echo "Create log files directory."
  mkdir -p ${logFilesDirectory}

  echo "Create Queue Manager."
  crtmqm -p ${qmgrPort} -ll -u SYSTEM.DEAD.LETTER.QUEUE -md ${dataFilesDirectory} -ld ${logFilesDirectory} ${qmgrName}

  echo "Start Queue Manager."
  strmqm -x ${qmgrName}

  echo "Set authentication on Queue Manager."
  setmqaut -m ${qmgrName} -t qmgr -g ${mqAdminsGroup} +connect +inq +dsp +chg
  . /opt/mqm/samp/bin/amqauthg.sh ${qmgrName} ${mqAdminsGroup}

  echo "Run mq-setup.mqsc file"
  runmqsc ${qmgrName} < /home/mqm/mq-setup.mqsc

}

install $1 $2 $3 $4 $5