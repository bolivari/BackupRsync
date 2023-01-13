#!/bin/sh
##!/usr/bin/env bash
#@Author: bolivari
#@Version: 0.8
#@License: GPL

FULLSCRIPTNAME=$0
SCRIPTNAME=`basename $0`
VERSION='0.8'

INTERACTIVE=1
VERBOSE=3
QUIET=0
LOG=1
LOGDATE=1
COLOR=1
DATE=0

DIA=0 #1 nocolor #2 Dialog Color #3 XDialog No Color #4 Xdialog Color
DIALOG='dialog'
Dialog_log='dialog.log'
rm -f $Dialog_log

FILE_DATE=$(date +%d%m%y-%H%M%S)
TMPDIR='tmp'
LOGDIR='log'
LOGNAME='BackupLog'
SNAPSHOTDIR='Backup'

program_list='rsync ssh find md5sum' ##TODO Append from other source script
backup_list='backup_list_test.txt'

SAVE=1
RESTORE=0
VERIFY=0
FULL=0
DIFFERENCIAL=0
INCREMENTAL=0
SNAPSHOT=0
SAPSHOPINTERVAL=0

usage(){
cat <<EOF
$SCRIPTNAME $VERSION
  Usage: $SCRIPTNAME [option]
  Options :
	-h | --help		Help
	-i | --interactive	Interactive
	-l | --log		Log
	-q | --quiet		Quiet
	-v | --verbose		Verbose
	-V | --version		Version
	-d | --debug		Debug
EOF
}
arg=$*
optarg(){
#Must have args
#if [ $# -eq 0 ];then usage;exit 1;fi

while [ $# -gt 0 ];
do
  case $1 in
    --save)SAVE=1;RESTORE=0;shift;;
    --restore)SAVE=0;RESTORE=1;shift;;
    --verify)VERIFY=1;shift;;
    --list*)SubString '--list' $1 $2;CheckArgs `echo $result`;if [ $? -eq 0 ];then shift;fi;backup_list=$result;shift;;
    --showlist)showlist;exit 1;; #TODO
    --debug)VERBOSE=3;shift;;
    --interactive)INTERACTIVE=1;shift;;
    --log)LOG=1;shift;;
    --quiet)QUIET=1;INTERACTIVE=0;shift;;
    --verbose)VERBOSE=2;shift;;
    --version)Printe "\tVersion: $VERSION";exit 0;;
    --help)usage;exit 1;;
    --*)usage;exit 1;;
    -)usage;exit 1;;
    -*)
    OPTION='';OPTIND=0;OPTARG='';
    while getopts ":-dilqvTGDRdon:ma:b:r:Vh" OPTION
	do
	case $OPTION in
	  b)CheckArgs $OPTARG;if [ $? -eq 0 ];then backup_list=$result;fi;; #TODO Multiple backuplist
	  d)VERBOSE=3;;
	  i)INTERACTIVE=1;;
  	  l)LOG=1;;
  	  q)QUIET=1;INTERACTIVE=0;;
  	  v)VERBOSE=2;;
  	  V)Printe "\tVersion: $VERSION";exit 0;;
	  h)usage;exit 1;;
	  -)if [ "$MYSHELL" = "/bin/dash" ];then OPTIND=$(($OPTIND - 1));fi;break 1;;
	  *)usage;exit 1;;
    	esac
	done
	optind=$(( $OPTIND - 1 ))
	if [ $# -ge $optind ];then shift $optind;fi;;
     *)usage;exit 1;;
   esac
done
}
prestartup(){
	STARTDATE=$(date +%d/%m/%Y)
	STARTTIME=$(date +%s%N)
	STARTPTIME=$(date +%k:%M:%S)
	
	#Must be root
	#if [ $(whoami) != 'root' ]
	#then
	#	echo -e "Sorry, you must be root to run this script"
	#	exit 1
	#fi
	
	#Must have args
	#if [ "$*" = "" ]
	#then
	#	usage
	#	exit 1
	#fi
	
	INIT_PATH=`pwd`
	script_path=`dirname $FULLSCRIPTNAME`
	cd $script_path
	SCRIPT_PATH=`pwd`
	#source ./include.sh
	. ../lib/include.sh
	#. ../lib/progressbar.sh
	. ./rsync.sh
	#. ./verify.sh
	
	cd "$INIT_PATH"
	optarg `echo "$arg"`
	
	#Locks
	#LOCK_FILE=$TMPDIR/$SCRIPTNAME.lock
	#if [ -f "$LOCK_FILE" ]; then
   	#	echo "Script is already running"
   	#	exit 1
	#fi

	#trap "rm -f $LOCK_FILE" EXIT
	#touch "$LOCK_FILE"
	
	cd "$SCRIPT_PATH"
	
	if [ $QUIET -lt 1 ]
	then
		exec 2>&1 > /dev/stdin
	else
		exec > /dev/null 2>&1
	fi
	CheckDirectory $TMPDIR
	if [ $? -ne 0 ]
	then
		mkdir -p $TMPDIR
	fi
	GetFullPath $TMPDIR;TMPDIR=$result
	
	CheckDirectory $LOGDIR
	if [ $? -ne 0 ]
	then
		mkdir -p $LOGDIR
	fi
	#TODO full LOG not $LOGFILE
	GetFullPath $LOGDIR;LOGDIR=$result
	if [ $LOGDATE -eq 1 ];then LOGFILE=$TMPDIR'/'$LOGNAME'-'$FILE_DATE'.log';else LOGFILE=$TMPDIR'/'$LOGNAME'.log';fi
	if [ $LOG -ne 0 ];then touch $LOGFILE;GetFullPath $LOGFILE;LOGFILE=$result;fi
}
startup(){
	trap TrapStopByUser 2 3 15
	
	if [ $VERBOSE ] && [ $VERBOSE -gt 0 ];then ShowDashLine '=#' '@' '@';fi
	if [ $VERBOSE ] && [ $VERBOSE -gt 0 ];then Printne "$TitleColor";Center '\'$SCRIPTNAME'/';Printne "$ResetColor";fi
	if [ $VERBOSE ] && [ $VERBOSE -gt 0 ];then Printne "$TitleColor";Center '\''Version:'$VERSION'/';Printne "$ResetColor";fi
	if [ $VERBOSE ] && [ $VERBOSE -gt 0 ];then ShowDashLine '=#' '@' '@';fi
	Info 'Start'
	
	
	ShowInformation
	
	Debug 'INTERACTIVE='$INTERACTIVE
	Debug 'VERBOSE='$VERBOSE
	Debug 'LOG='$LOG
	Debug 'SAVE='$SAVE
	Debug 'RESTORE='$RESTORE
	CheckDirectory $TMPDIR
	CheckResult "Directory " $TMPDIR "Exist" "Doesn't Exist"
	CheckDirectory $LOGDIR
	CheckResult "Directory " $LOGDIR "Exist" "Doesn't Exist"
	if [ $LOG -ne 0 ];then Info 'Log file at: '$LOGFILE;fi
	return 0
}
finish(){
	#if [ $VERBOSE ] && [ $VERBOSE -gt 0 ];then PreloadProgressBar '#=@' ' [' '] ' '._$';ProgressBarAnimate '0' '100';fi
	
	Printne "$TextFileColor"
	#find $TMPDIR\/ -mindepth 1 -exec mv -vbt $LOGDIR\/ {} \+
	mv -v $LOGFILE $LOGDIR\/ > /dev/null 2>&1
	Printne "$ResetColor"
	LOGFILE=$LOGDIR'/BackupLog-'$FILE_DATE'.log'
	rm -rf $TMPDIR
	return 0
}
postfinish(){
	#set
        #export
	
	#Error "finish"
	if [ $DIA -eq 3 -o $DIA -eq 4 ];then Xdialog --title $SCRIPTNAME --backtitle "jhf" --smooth --keep-colors --logbox "$Dialog_log" 30 150;fi
	#if [ $DIA -eq 1 -o $DIA -eq 2 ];then $DIALOG --title $SCRIPTNAME  --clear --no-collapse --textbox "$Dialog_log" 100 100;fi
	if [ $DIA -eq 1 -o $DIA -eq 2 ];then $DIALOG --title $SCRIPTNAME --clear --no-collapse --colors --msgbox "$(cat $Dialog_log)" 100 100;fi
	if [ $DIA -eq 1 -o $DIA -eq 2 ];then $DIALOG --title $SCRIPTNAME --no-collapse --colors --infobox "$(tail $Dialog_log)" 100 100;fi
	#rm -r $TMPDIR
	#if [ $DIA -eq 1 -o $DIA -eq 2 -o $VERBOSE -gt 0 ];then Printne '\n';fi
	#if [ $VERBOSE ] && [ $VERBOSE -gt 0 ];then Printne '\n';fi
	EndTime
	Info "Done"
	exit 0
}

main(){
	startup
	
	CheckList 'CheckProgram' $program_list
	CheckListResult "Program " " is on the system at: " " is not on the system" "A Program not Found on System" "All Program Found" "List is empty"
	CheckFile $backup_list
	CheckResult "File" $backup_list "Exist" "Doesn't Exist"
	GetFullPath $backup_list;backup_list=$result
	
	#CleanComment $backup_list
	#CheckSSH "guest@localhost:22/mnt/test"
	#GenerateSSHKey
	#PutSSHKey $listremotedir
	GetListLocalDirectory $backup_list
	GetListRemoteDirectory $backup_list
	#directory_list=$(cat $backup_list)
	
	empty=0
	if [ "$listlocaldir" != "" ];then
		CheckList 'CheckDirectory' $listlocaldir
		if [ $? -eq 0 ];then
			CheckListResult "Directory " " Exist " " Doesn't Exist" "A Directory in the List didn't Exist" "All Directory in List Exist" "List is empty"
		else
			empty=$(($empty+1))
		fi
	fi
	if [ "$listremotedir" != "" ];then CheckList 'CheckSSHRsync' $listremotedir
		if [ $? -eq 0 ];then 
			CheckListResult "SSH Directory " " Exist " " Doesn't Exist" "A SSH Directory in the List didn't Exist or SSH connection is busy" "All SSH Directory in List Exist" "List is empty"
		else
			empty=$(($empty+1))
		fi
	fi
	if [ $empty -eq 2 ];then Error "List is empty";fi
	#Module for check md5
	
	#if [ $SAVE -eq 1 -o $RESTORE -eq 1 ];then if [ $SAVE -eq 1 -a $RESTORE -eq 1 ];then SAVE=0;RESTORE=0;Error "You Save or Restore ?";else Info "SAVE: "$SAVE;Info "RESTORE: "$RESTORE;fi;else Error "Nothing to do";fi
	#if [ $SAVE -eq 1 -a $RESTORE -eq 1 ];then SAVE=0;RESTORE=0;Error "You Save or Restore";else Error "Nothing to do";fi 
	#if [ $RESTORE -eq 1 ];then SAVE=0;else SAVE=1;RESTORE=0;fi
	#if [ $SAVE -eq 1 ];then RESTORE=0;else SAVE=0;RESTORE=1;fi
	
	if [ $SAVE -eq 1 ];then
		ShowFile $backup_list
		Confirm "[QUESTION]:  Would you like to Continue (Y)es/(N)o: " "Yes" "No" "Retry with (Y)es/(N)o: "
		if [ $? -eq 1 ]
		then
			RsyncSave
		else
			StopByUser
		fi
	fi
	if [ $RESTORE -eq 1 ];then
		ShowFileInvert $backup_list
		Confirm "[QUESTION]:  Would you like to Continue (Y)es/(N)o: " "Yes" "No" "Retry with (Y)es/(N)o: "
		if [ $? -eq 1 ]
		then
			RsyncRestore
		else
			StopByUser
		fi
	fi
	finish
}
prestartup
main
postfinish
