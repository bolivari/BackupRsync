#!/bin/sh
#TMPDIR='tmp'
#program_list='find gpg md5sum shasum' #TODO not surcharge
CHECKSUMFILE='CHECKSUM'
PutChecksumInto(){
	cp $1 $2
}
RmChecksum(){
	rm -f $CHECKSUMFILE
}
Md5SumGenerate(){
	Debug "Md5check"
	eval `find -type f -not -name $CHECKSUMFILE -exec md5sum {} \; > $CHECKSUMFILE`
}
#return 0 if success
Md5SumVerify(){
	Debug "Md5Sumverify"
	#--status
	result=`md5sum -c $CHECKSUMFILE`
	#Printe $result
	if [ $? -eq 0 ];then return 0;else return 1;fi
}
ShaSumGenerate(){
	Debug "shasumcheck"
	exec > /dev/null 2>&1
	eval `find -exec shasum -pa 256 {} \; > $CHECKSUMFILE`
	exec 2>&1 > /dev/stdin
}
#return 0 if success
ShaSumVerify(){
	Debug "shasumverify"
	eval `shasum -cs $CHECKSUMFILE`
}
GpgGeneratekey(){
	Debug "key"
	eval `gpg --gen-key`
}
GpgSumGenerate(){
	eval `find -exec gpg --print-mds {} \; > $CHECKSUMFILE`
}
#TODO
GpgSumVerify(){
	Debug "gpgsumverify"
	eval `gpg --verify-files $CHECKSUMFILE`
}
List(){
	Debug "List"
	eval `find $1 -print`
}
#TODO not work with ssh
Verify(){
	RmChecksum
	invert=0
	if [ $1 -eq 1 ];then invert=$1;fi
	nbline=$((`wc -l $backup_list | cut -d' ' -f1`+1))
	i=1
	while [ $i -le $nbline ];
	do
		if [ $invert -eq 1 ];then GetLineByLineInvert $backup_list $i;else GetLineByLine $backup_list $i;fi
		if [ "$line" != "" ];then
			if [ $invert -eq 1 ];then GetByField 2 `echo $line`;field=$result;FinishWithSlash $field;if [ $? -eq 1 ];then name=`basename $field`;else name='';fi;GetByField 1 `echo $line`;field=$result;FinishWithSlash $field;if [ $? -eq 0 ];then result=$field$name;else result=$field;fi;n01=$result;GetByField 2 `echo $line`;field=$result;SubString $name $result;if [ $? -eq 0 ];then n02=$result;else n02=$field;fi;line=$n01' '$n02;else GetByField 1 `echo $line`;n01=$result;GetByField 2 `echo $line`;n02=$result;fi
			Info "Verify: $line"
			FinishWithSlash $n01;if [ $? -eq 1 ];then n01=$n01\/;name=`basename $n01`;n02=$n02$name\/;fi
			Debug $n02
			cd $n01
			Md5SumGenerate $n01
			cd $INIT_PATH
			cp $n01$CHECKSUMFILE $n02$CHECKSUMFILE
			cd $n02
			Md5SumVerify
			if [ $? -eq 0 ];then Info "Success";else Info "Error";fi
			cd $INIT_PATH;
			cd $n01;RmChecksum;cd $INIT_PATH;cd $n02;RmChecksum;cd $INIT_PATH
		fi
		i=$(($i+1))
	done
}
