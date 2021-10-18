#!/bin/bash

tarFiles() {
        if (($# == 3))
        then
                tmpTarBackupFilePath="$3"
        else
                tmpTarBackupFilePath=${tarBackupFilePath}
        fi

        if ((${#2} > 0))
        then
                tarBackupFileHeader="${2}_"
        else
                tarBackupFileHeader=""
        fi

        tarFileDetails="$1"
        if [ -d ${tarFileDetails} ]
        then
                tarFileName=`echo ${tarFileDetails} | awk -F'/' '{print $NF}'`
                tarFileSrcPath=${tarFileDetails:0:${#tarFileDetails} - ${#tarFileName}}
                echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] TarFileDetails : ${tarFileDetails} TarFileDestPath : ${tmpTarBackupFilePath} TarSrcFileName : ${tarBackupFileHeader}${tarFileName} TarFileSrcPath : ${tarFileSrcPath}"
                if [ -d ${tarFileSrcPath} ]
                then
                        cd ${tarFileSrcPath}
                        tar -cvzf ${tmpTarBackupFilePath}/${tarBackupFileHeader}${tarFileName}_${bkpDate}.tgz --exclude=*.log --exclude=core.* --exclude=nohup.* --exclude=catalina.* --exclude=trash/* --exclude=*.log* --exclude=log/* --exclude=logs/* --exclude=work/* --exclude=temp/* --exclude=tmp/* --exclude=backups/* --exclude=pub/media/wordpress/* --exclude=wordpress/wp-content/uploads/*  ${tarFileName}
                        isTarFileExists ${tmpTarBackupFilePath}/${tarBackupFileHeader}${tarFileName}_${bkpDate}.tgz ${tarFileName}
                else
                        echo "ERROR PATH NOT FOUND ${tarFileSrcPath}"
                fi
        else
                        echo "ERROR PATH NOT FOUND ${tarFileDetails}"
        fi
}

bkpSystemInfoFiles() {
        echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] Creating Backup of /etc/sysconfig/network-scripts/"
        bkpSystemInfoFilesName="network-scripts_${bkpDate}.tgz"
        tar -czf ${tarBackupFilePath}/$bkpSystemInfoFilesName /etc/sysconfig/network-scripts/
        isTarFileExists ${tarBackupFilePath}/$bkpSystemInfoFilesName /etc/sysconfig/network-scripts/

        echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] Creating Backup of /etc/sysconfig/networking/devices"
        bkpSystemInfoFilesName="devices_${bkpDate}.tgz"
        tar -czf ${tarBackupFilePath}/$bkpSystemInfoFilesName /etc/sysconfig/networking/devices
        isTarFileExists ${tarBackupFilePath}/$bkpSystemInfoFilesName /etc/sysconfig/networking/devices

        echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] Creating Backup of /etc/hosts"
        bkpSystemInfoFilesName=hosts_${bkpDate}
        cat /etc/hosts > ${tarBackupFilePath}/$bkpSystemInfoFilesName
        isTarFileExists ${tarBackupFilePath}/$bkpSystemInfoFilesName /etc/hosts

        echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] Creating Backup of /etc/rc.local"
        bkpSystemInfoFilesName=rc.local_${bkpDate}
        cat /etc/rc.local > ${tarBackupFilePath}/$bkpSystemInfoFilesName
        isTarFileExists ${tarBackupFilePath}/$bkpSystemInfoFilesName /etc/rc.local

        echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] Creating Backup of IPDetails"
        bkpSystemInfoFilesName=ifconfig_${bkpDate}
        /sbin/ifconfig > ${tarBackupFilePath}/$bkpSystemInfoFilesName
        isTarFileExists ${tarBackupFilePath}/$bkpSystemInfoFilesName ifconfig

        echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] Creating Backup of Routes Details"
        bkpSystemInfoFilesName=route_${bkpDate}
        /sbin/route > ${tarBackupFilePath}/$bkpSystemInfoFilesName
        isTarFileExists ${tarBackupFilePath}/$bkpSystemInfoFilesName route

        echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] Creating Backup of Crontab Entries."
        cp /var/spool/cron/* ${tarBackupFilePath}
}

isTarFileExists()
{
        if [ -f $1 ] && [ -s $1 ]
        then
                echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] ____________________Backup of $2 Succcessfully Created as $1____________________"
        else
                echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] ERROR: Backup Creation of $2 Failed... File $1 Does not Exists"
        fi
        echo
}

transferFile()
{
        destBackupSrvrIP="$2"
        destBackupSrvrUname="$3"
        destBackupSrvrPasswd="$4"
        destBackupSrvrPath="$5"
        tarBackupFile="$1"
        echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] COPINY File ${tarBackupFile} to BACKUP Server ${destBackupSrvrIP} [ ${destBackupSrvrUname} - ${destBackupSrvrPath} ]"
        /usr/bin/lftp -e "set cmd:fail-exit yes; set net:reconnect-interval-base 10; set net:max-retries 5; cd ${destBackupSrvrPath}; mput ${tarBackupFile}; quit" -u ${destBackupSrvrUname},${destBackupSrvrPasswd} sftp://${destBackupSrvrIP}
        if (($? == 0))
        then
                echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] SUCCESSFULLY BACKUP FILE ${tarBackupFile} TRANFERED TO ${destBackupSrvrIP}."
        else
                echo "[ `date '+%d-%m-%Y %H:%M:%S'` ] ERROR: FAILURE IN BACKUP FILE ${tarBackupFile} TRANFERING TO ${destBackupSrvrIP}."
        fi
}
#____________________________________________________________________________________________________________________________________________________________________
bkpDate=`(date --date='today' '+%d%m%y')`
rmBkpDate=`(date --date='1 weeks ago' '+BKP_%d%m%Y.tgz')`
bkpFileName="BKP_`/bin/hostname`"
bkpPath=/opt/6d/backup
tarBackupFilePath=${bkpPath}/${bkpFileName}
tarBackupFileName=${bkpFileName}_${bkpDate}.tgz
mkdir -p ${tarBackupFilePath}

bkpSystemInfoFiles

tarFiles /opt/6d/apps/Wordpress_with_ngnix_reverse_proxy ""
#tarFiles /data/6d/apps/keycloak-8.0.1 ""
tarFiles /opt/html/6d-magento ""
tarFiles /home/dscapusr/Scripts/ ""


tarFiles ${bkpPath}/${bkpFileName} "" ${bkpPath}

rm -rf ${bkpPath}/${bkpFileName}

find /opt/6d/backup -maxdepth 1 -type f -name 'BKP_*.tgz' -mtime +7 -exec rm -f {} \;
###number1

DAYOFWEEK=$(date +"%a")
echo DAYOFWEEK: $DAYOFWEEK
if (($DAYOFWEEK == "Fri"))
then 
   echo "Today is $DAYOFWEEK So Trasferring to 70 Server" 
   ##transferFile "${bkpPath}/${tarBackupFileName}" "10.4.181.12" "dscapusr" "Dscuser@123" "/opt/6d/backup" 
   ###number2
else 
   echo "Today is $DAYOFWEEK So exiting from here"
fi

