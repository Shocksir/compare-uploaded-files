#!/bin/bash
TESTDIRPATH="/files location on your computer"
cd $TESTDIRPATH
S3BUCKETNAME="s3://files location in your bucket/"

TEMPRESULTFILE="/tmp/$(basename $0).$$.txt"
TEMPS3FILE="/tmp/$(basename $0).$$.s3.txt"

echo "Bucket name is \"$S3BUCKETNAME\"" >$TEMPRESULTFILE

FILESONBUCKET=`s3cmd ls $S3BUCKETNAME`
if [ -n "$FILESONBUCKET" ]
then        
    echo "$FILESONBUCKET" | cut -c17- | sed 's/^ *\(.*\) *$/\1/' | sed 's/\s\s\+/,/g'  > $TEMPS3FILE #| cut -d',' -f1,2


    ALLFILES="/*"

    for f in $TESTDIRPATH$ALLFILES
    do
        LOCALFILNAME="${f##*/}"
        LOCALFILESIZE=$(stat -c%s "$LOCALFILNAME")
        FILENAME_ESCAPED=`echo "$LOCALFILNAME" | sed s/\\ /\\\\\\\\\\\\\\ /g | sed s/\\'/\\\\\\\\\\\\\\'/g | sed s/\&/\\\\\\\\\\\\\\&/g | sed s/\;/\\\\\\\\\\\\\\;/g | sed s/\(/\\\\\\\\\\(/g | sed s/\)/\\\\\\\\\\)/g`
        
        INS3=`egrep "($S3BUCKETNAME$FILENAME_ESCAPED$)" $TEMPS3FILE`
        if [ -n "$INS3" ]
        then 
                INS3FILESIZE=`echo $INS3 | cut -d',' -f1`
                if [ $INS3FILESIZE -eq 0 ]
                then
                    printf "File %30s has been uploaded to S3. File size does not match: %d\n" $LOCALFILNAME, $INS3FILESIZE 1>>$TEMPRESULTFILE 
                elif [ $INS3FILESIZE -eq $LOCALFILESIZE ]
                then
                    $CHECKPOINT
                else    
                    printf "File %30s has been uploaded to S3. File size does not match: %d\n" $LOCALFILNAME, $INS3FILESIZE 1>>$TEMPRESULTFILE 
                fi
        else 
               printf "File %30s was NOT uploaded to S3 \n" $LOCALFILNAME 1>>$TEMPRESULTFILE
        fi
    done
    SUBJECT="Automated daily check for S3"
    EMAIL="it-research@ucentralasia.org"
    EMAILMESSAGE=$TEMPRESULTFILE
    mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE
else
    echo "Empty result from S3. Maybe bucket does not exists" 1>>$TEMPRESULTFILE
    exit
fi