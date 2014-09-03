#!/bin/bash


########### main variable ###############

recorddir=/data/zqlive/src

########### ftp variable  ################

IP=180.97.46.113
USER=cdnftp
ftpPswd=t3MVSVRhhpTb
uploadPATH=/data/zqlive/upload
uploadlog=/usr/local/nginx/conf/zqlive/upload.log

######### upload fail retry; must be a number

trycount=10
failuploaddir=/data/zqlive/fail_to_upload

######### zqlive BT 20140903 #####

if [ -f /usr/local/nginx/conf/zqlive/streamadd/$1 ] ; then
	ls -t "$recorddir"/"$1"-dl-* | while read line
		do
			rm -f $line 
		done
		rm -f /usr/local/nginx/conf/zqlive/streamadd/$1
		exit
fi

if [ -f /usr/local/nginx/conf/zqlive/streamdel/$1 ] ; then
	rm -r /usr/local/nginx/conf/zqlive/streamdel/$1
else
	grep "\<$1\>" /usr/local/nginx/conf/zqlive/record_list &> /dev/null || exit 
fi

############# ftp module ##############

ftpserver() {
/usr/bin/ftp -v -n <<!
        open $IP
        user $USER $ftpPswd
        bin
        lcd $uploadPATH
        put "$Stream".flv "$Stream".flv
        close
        bye
!
}

######### upload module  #########

upload() {
        i=1

        until [ "$i" -gt "${trycount:=3}" ] 
        do
                let i++
                ftpserver >> "$uploadlog"
                tail -5 "$uploadlog" | grep "226 Transfer complete" &> /dev/null
                RETRUN=$?
                [ "$RETRUN" == 0 ] && echo -e "################`date +%Y%m%d-%T` SENT $Stream.flv TO ftpserver Success" >> "$uploadlog" && RETRUN=3 && break
        done

	[ "$RETRUN" == 3 ] && RETRUN=0 && continue

        [ -d "$failuploaddir" ] || mkdir -p "$failuploaddir"

        mv "$uploadPATH"/"$Stream".flv "$failuploaddir"

        echo -e "################`date +%Y%m%d-%T` SENT $Stream.flv TO ftpserver Failure" >> "$uploadlog"
}

######### main ##################




[ `ls "$recorddir"/"$1"*.flv | wc -l` == 1 ] && ls -t "$recorddir"/"$1"*.flv > /tmp/uptmp.log || ls -t "$recorddir"/"$1"* | tail -n +2 > /tmp/uptmp.log

cat /tmp/uptmp.log | while read line

do

	Stream=`echo "$line" | awk -F "/" '{print $NF}' | awk -F ".flv" '{print $1}' | awk -F -dl- '{print "dl-"$2"-"$1}'`
	
	[ -d "$uploadPATH" ] || mkdir -p "$uploadPATH"
	
	mv "$line" "$uploadPATH"/"$Stream".flv

	[ -n "$line" ] || exit 5

######### test page #############

	echo "################`date +%Y%m%d-%T` THE  $Stream.flv was ready to upload to ftpserver"  >> "$uploadlog"

######### upload module #########

	upload

done
