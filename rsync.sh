#!/bin/sh
#TODO
GetPath(){
	Debug "TODO"
}
GetHost(){
	Debug "TODO"	
}
GetPort(){
	Debug "TODO"			
}
CheckSSHService(){
	sshpath='';sshhost='';host='';port='';
	sshpath=$1
	sshhost=${sshpath%%\/*}
	host=${sshhost%%:*}
	port=$(echo $sshhost | sed 's/\w*[@]\w*[:]*//')
	if [ "$port" = "" ];then port=22;fi
	ssh -tq -p $port $host
	if [ $? -ne 0 ];then Error "Couldn't Connect to SSH";fi
}
#TODO info with diffezrence from CheckSSHRsync
CheckSSH(){
	sshpath='';sshhost='';host='';port='';dpath=''
	sshpath=$1
	test='test -e'
	sshhost=${sshpath%%\/*}
	host=${sshhost%%:*}
	port=$(echo $sshhost | sed 's/\w*[@]\w*[:]*//')
	if [ "$port" = "" ];then port=22;fi
	dpath=${sshpath#*/}
	Debug "Host: "$host "Port: "$port "Path: "$dpath
	ssh -tq -p $port $host $test $dpath
	if [ $? -eq 0 ];then return 0;else return 1;fi
}
CheckSSHRsync(){
	sshpath='';sshhost='';host='';port='';dpath=''
	sshpath=$1
	test='test -e'
	host=${sshpath%%:*}
	if [ "$port" = "" ];then port=22;fi
	dpath=${sshpath#*:}
	Debug "Host: "$host "Port: "$port "Path: "$dpath
	ssh -tq -p $port $host $test $dpath
	if [ $? -eq 0 ];then return 0;else return 1;fi
}
PutSSHKey(){
	#set SSH_ASKPASS
	element=''
	CheckFile ~/.ssh\/$USER@$HOSTNAME
	check=$?
	CheckFile ~/.ssh\/$USER@$HOSTNAME.pub
	check=$(( $check + $? ))
	if [ $check -eq 0 ]
	then
		Info "Public and Private Key Exist on Local machine"
	else
		Printne "$SSHColor"
		cp -v $sshkeydir\/$USER@$HOSTNAME $sshkeydir\/$USER@$HOSTNAME.pub ~/.ssh/
		Printne "$ResetColor"
		Info "Public and Private Key duplicate on Local machine"
	fi
	
	listelement=$*
	Debug "List Remote Element: $listelement"
	if [ "$listelement" != "" ]
	then
		for element in $listelement;
		do
			sshpath=$element
			sshhost=${sshpath%%\/*}
			listhost=$listhost' '$sshhost
		done
	fi
	
	listhost=$(echo $listhost | tr ' ' '\n' | sort -u | tr '\n' ' ')
	Debug "List Remote Host: $listhost"
	#password='aaaaaa'
	#echo "$password" | $(ssh guest@localhost)
	#echo "$password" | exec ssh guest@localhost
	#old_settings=3D$(stty -g)
	#stty -echo
	#printf 'password: '
	#IFS=3D read -r passwd
	#stty "$old_settings"
	#Printe $passwd

	if [ "$listhost" != "" ]
	then
		for sshhost in $listhost;
		do
			host=${sshhost%%:*}
			port=$(echo $sshhost | sed 's/\w*[@]\w*[:]*//')
			if [ "$port" = "" ];then port=22;fi
			Printne "$SSHColor"
			#ssh -tq -p $port $host ' '
			#if [ $? -ne 0 ];then Error "Couldn't Connect to SSH";else Info "Could Connect to SSH";fi
			Printne "$ResetColor"
			#authorized_keys=$(ssh -tq -p $port $host "if [ -e .ssh/authorized_keys ];then cat .ssh/authorized_keys;else touch .ssh/authorized_keys;fi")
			Printne "$SSHColor"
			authorized_keys=$(ssh -tq -p $port $host "cat .ssh/authorized_keys")
			Printne "$SSHColor"
			public_key=$(cat $sshkeydir\/$USER@$HOSTNAME.pub)
			#echo $authorized_keys
			echo "$authorized_keys" | grep "$public_key" > /dev/null
			if [ $? -eq 0 ]
			then
				Info "Public Key Exist on Remote machine: "$sshhost
			else
				Printne "$SSHColor"
				ssh-copy-id -i $sshkeydir\/$USER@$HOSTNAME.pub $sshhost
				#scp $sshkeydir\/$USER@$HOSTNAME.pub $1:~/.ssh\/
				Printne "$ResetColor"
				#cat ~/.ssh/id_dsa.pub | ssh user@machine "cat - >> ~/.ssh/authorized_keys"
				Info "Public Key installed on Remote machine: "$sshhost
			fi
		done
	fi
}
GenerateSSHKey(){
	keysize='1024'
	keytype='dsa'
	sshkeydir='ssh-key'
	CheckFile $sshkeydir\/$USER@$HOSTNAME
	check=$?
	CheckFile $sshkeydir\/$USER@$HOSTNAME.pub
	check=$(( $check + $? ))
	if [ $check -eq 0 ]
	then
		Info "Public and Private Key Already Generated"
	else
		Printne "$SSHColor"
		ssh-keygen -b $keysize -t $keytype -f $sshkeydir\/$USER@$HOSTNAME
		Printne "$ResetColor"
	fi
}
GetListLocalDirectory(){
	Debug "GetListLocalDirectory"
	file=$1
	listlocaldir=''
	listlocaldir=$(awk -F"~" '
	BEGIN{
		FS=" "
	}
	{	
		if ( NR > 0 && $0 !~ /^#/ && $0 != "" ) {
			if ( $1 !~ /\w*[@]/){
			printf("%s ",$1);
			}
			if ( $2 !~ /\w*[@]/){
			printf("%s ",$2);
			}
		}
	}
	END {
	}' $file)
	Debug 'Listlocaldir: '$listlocaldir
}
GetListRemoteDirectory(){
	Debug "GetListRemoteDirectory"
	file=$1
	listremotedir=''
	listremotedir=$(awk -F"~" '
	BEGIN{
		FS=" "
	}
	{	
		if ( NR > 0 && $0 !~ /^#/ && $0 != "" ) {
			if ( $1 ~ /^\w*[@]/){
			printf("%s ",$1);
			}
			if ( $2 ~ /^\w*[@]/ ){
			printf("%s ",$2);
			}
		}
	}
	END {
	}' $file)
	Debug 'Listremotedir: '$listremotedir
}
GetLineByLine(){
	file=$1
	nb=$2
	#Debug $nb
	line=''
	line=$(awk -F"~" '
	BEGIN{
		FS=" "
	}
	{
		if ( NR == '$nb' && NR > 1 && $0 !~ /^#/ && $0 != "" ) {
			printf("%s %s",$1,$2);
			exit;
		}
	}
	END {
	}' $file)
	#Debug 'Line: '$line
}
GetLineByLineInvert(){
	file=$1
	nb=$2
	line=''
	line=$(awk -F"~" '
	BEGIN{
		FS=" "
	}
	{
		if ( NR == '$nb' && NR > 1 && $0 !~ /^#/ && $0 != "" ) {
			printf("%s %s",$2,$1);
			exit;
		}
	}
	END {
	}' $file)
}
PrintFileInvertGeneric(){
	file=$1
	line=''
	nbcol=$(tput cols)
	nbcol=$(($nbcol/2))
	#nbline=$(awk -F"~" 'BEGIN{FS=" ";i=0}{if ( NR > 0 && $0 !~ /^#/ && $0 != "" ){i=i+1}}END{print i}' $file)
	line=$(awk -F"~" '
	function basename(path) { n=split(path,file,"/"); return file[n]; }
	function dirname (pathname) {if (!sub(/\/[^\/]*\/?$/, "", pathname)) return "."; else if (pathname != "") return pathname; else return "/";}
	function substring(path,string) { n=index(string,path); n=substr(path,length(path) +1,length(string)); return n; }  #TODO
	BEGIN{
		FS=" "
	}
	{
		if ( NR > 0 && $0 !~ /^#/ && $0 != "" ) {
			slash=substr( $2, length($2), length($2));
			if ( slash == "/" ){
				b=basename($1);
				if ( b != "" ){
					printf("%-'$nbcol's",$2b);
					d=dirname($1);
					printf("%-'$nbcol's\n",d"/");
				}else{
					printf("%-'$nbcol's%-'$nbcol's\n",$2,$1);
				}
			}else{
				printf("%-'$nbcol's%-'$nbcol's\n",$2,$1);
			}
		}
	}
	END {
	}' $file)
	Printe "$line"
}
RsyncSave(){
	#--delete save in a snapshot tag deleted
	#-azrv --progress --compress-level=9
	#rsync --del --force
	#rsync -a --delete --backup --backup-path
	#rsync -aE --link-dest=/mnt/external_disk/backup_20090612 dir_to_backup /mnt/external_disk/backup_20090613
	#rsync -va --stats Bd/ mnt/Bd
	#rsync -va -e 'ssh -p 22' guest@localhost:mnt/test/ dest/
	#rsync -va --rsh='ssh -p 873' guest@localhost:mnt/test/ dest/
	#--partial-dir for resume
	#--fake-super for gid uid
	#--log-file=FILE
	Debug "Rsync Save"
	nbline=$((`wc -l $backup_list | cut -d' ' -f1`+1))
	Debug "Nbline: $nbline"
	i=1
	while [ $i -le $nbline ];
	do
		GetLineByLine $backup_list $i
		if [ "$line" != "" ];then
			Info "Rsync: $line"
			GetByField 1 `echo $line`;n01=$result
			GetByField 2 `echo $line`;n02=$result
			Printne "$ResetColor";Printne "$TextFileColor"
			if [ $LOG -gt 0 ];
			then
				eval rsync "--rsh='ssh -p 22'" -avzh --compress-level=9 --force --del --progress --stats $line --log-file=$LOGFILE
			else
				eval rsync "--rsh='ssh -p 22'" -avzh --compress-level=9 --force --del --progress --stats $line
			fi
			Printne "$ResetColor"
		fi
		i=$(($i+1))
	done
}
RsyncRestore(){ #TODO work only with directory substring basename only TEST
	Debug "Rsync Restore"
	nbline=$((`wc -l $backup_list | cut -d' ' -f1`+1))
	Debug "Nbline: $nbline"
	i=1
	while [ $i -le $nbline ];
	do
		GetLineByLineInvert $backup_list $i
		if [ "$line" != "" ];then
			
			GetByField 2 `echo $line`;field=$result;FinishWithSlash $field;if [ $? -eq 1 ];then name=`basename $field`;else name='';fi;GetByField 1 `echo $line`;field=$result;FinishWithSlash $field;if [ $? -eq 0 ];then result=$field$name;else result=$field;fi;n01=$result
			GetByField 2 `echo $line`;field=$result;SubString $name $result;if [ $? -eq 0 ];then n02=$result;else n02=$field;fi
			
			line=$n01' '$n02
			Info "Rsync: $line"
			
			#TESR
			#Verify 1;exit 1
			#GetFullPath '~/../barn/mnt'
			#Debug $result
			#ListField `echo $line`
			#Debug $result
			#GetByField 1 `echo $line`
			#field=$result
			#FinishWithSlash $field
			#Debug $?
			#SubString '@test' '/nnone/n@test/@.600/@test'
			#Debug "$result"
			#List $line
			#AppendStringToList 'aaaa ' $result
			#RemoveFirstStringFromList `echo $line`
			#RemoveLastStringFromList $line' fdgs fghsfhs'
			#RemoveLastStringFromList `echo $line`
			#RemoveLastStringFromList 'fgds'
			#RemoveFirstStringFromList  `echo $line`
			#GetFullPath $result
			#Debug $result
			#FinishWithSlash $result
			#if [ $? -eq 0 ];then RemoveLastCharacter $result;Debug $result;fi
			#GetFullPath $result
			#Debug $result
			#GetRelativePath $result\/'test001'
			
			Printne "$ResetColor";Printne "$TextFileColor"
			if [ $LOG -gt 0 ];
			then
				eval rsync "--rsh='ssh -p 22'" -avzh --compress-level=9 --force --progress --stats $line --log-file=$LOGFILE
			else
				eval rsync "--rsh='ssh -p 22'" -avzh --compress-level=9 --force --progress --stats $line
			fi
			Printne "$ResetColor"
		fi
		i=$(($i+1))
	done
}
