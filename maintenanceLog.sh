#!/bin/bash

logMaintaiance()
{
        curHour=`(date --date='now' '+%H')`
        curMinute=`(date --date='now' '+%M')`
        totMintime=`expr $curHour \* 60 + $curMinute`
        logPath="$1"
        delimiter="$2"
        bkpLogLimitDays="$3"
        tarLogLimitDays="$4"
        tarFileName=`echo "$5" | sed '/^$/d'`
        rmLogPath="$6"
        rmLogLimitDays="$7"
        rmFileName=`echo "$tarFileName" | sed '/^$/d'`
        totMintime=`expr "$totMintime * $bkpLogLimitDays"`
        bkpFileName=`(date --date=$bkpLogLimitDays" days ago" '+'${tarFileName}'%d%m%y')`
        rmFileName=`(date --date=$rmLogLimitDays" days ago" '+'${rmFileName}'%d%m%y.tgz')`
        tarFileName=`(date --date=$tarLogLimitDays" days ago" '+'${tarFileName}'%d%m%y')`
        echo logPath=$logPath delimiter=$delimiter tarLogLimitDays=$tarLogLimitDays tarFileName=$tarFileName rmLogPath=$rmLogPath rmLogLimitDays=$rmLogLimitDays rmFileName=$rmFileName totMintime=$totMintime
        if [ -d $logPath ]
        then
                cd $logPath
                echo "Moved to Path `pwd`. Taring Logs of $totMintime Minutes ago [ With Delimiter '$delimiter' ]."
                fileList=`find . -maxdepth 1 -type f -iname "$delimiter" -mmin +$totMintime`
                if (( ${#fileList} > 0 ))
                then
                        echo File List :- $fileList
                        mkdir -p $logPath/$bkpFileName
                        mv $fileList $logPath/$bkpFileName
                        if [ -d $tarFileName ]
                        then
                                tar -cvzf $tarFileName.tgz $tarFileName
                                if [ -f $tarFileName.tgz ] && [ -s $tarFileName.tgz ]
                                then
                                        echo "Tar File $tarFileName.tgz, Created Successfully. Removing Old Back Up File $rmFileName and $tarFileName."
                                        rm -rf $rmLogPath/$rmFileName $tarFileName
                                else
                                        echo "ERROR: Failed to Create Tar File $tarFileName.tgz."
                                fi
                        else
                                echo "WARNING: No Directory Found Like '$tarFileName' For Taring."
                        fi
                else
                        echo "WARNING: No Files are Presented in the Path $logPath, Having Updated Before $totMintime Minutes ago [ With Delimiter '$delimiter' ]."
                fi
        else
                echo "ERROR: Path $logPath, Does not Exists."
        fi
}

daySatmp=`(date --date='7 days ago' '+%y%m%d')`
rmDaySatmp=`(date --date='30 days ago' '+%y%m%d')`

#logMaintaiance <LOG PATH> <DELIMITER> <BKP NUMBER OF DAYS> <TAR NUMBER OF DAYS> <TAR FILE NAME HEADER> <REMOVE LOG PATH> <REMOVE NUMBER OF DAYS>
#for directory in `find /home/sdpuser/LOGS/ -mindepth 1 -type d`
#do
#        echo $directory
#	logMaintaiance $directory "*.log*" 1 3 "" $directory 30
#done
logMaintaiance /opt/6d/apps/Wordpress_with_ngnix_reverse_proxy/wordpress/wp-content/themes/Divi-child/logger/logs/ "*.log*" 1 1 "" /opt/6d/apps/Wordpress_with_ngnix_reverse_proxy/wordpress/wp-content/themes/Divi-child/logger/logs/ 7

logMaintaiance /opt/6d/apps/Wordpress_with_ngnix_reverse_proxy/apache_logs "*.log*" 1 1 "" /opt/6d/apps/Wordpress_with_ngnix_reverse_proxy/apache_logs 7

