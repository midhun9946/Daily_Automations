#!/bin/bash

date=$(date --date='now' '+%d%m%y')

cd /opt/6d/backup

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



echo _________________________BKP_WORDPRESS_$(date '+%d%m%Y_%H').sql.gz__________________________________________________
mysqldump --force -udscuser -pDscuser@123  -h10.4.185.10 -P3306 Wordpress --routines --lock-tables=false | gzip -9 > BKP_DB_WORDPRESS_$(date '+%d%m%Y_%H').sql.gz
echo _________________________BKP_MAGENTO_$(date '+%d%m%Y_%H').sql.gz_________________________________________________
mysqldump --force -umagento_eshopuser -p'SYS^d#e%rR1' -h10.4.185.10 -P3306 magento_prod_eshop --routines --lock-tables=false | gzip -9 > BKP_DB_MAGENTO_$(date '+%d%m%Y_%H').sql.gz

echo _________________________BKP_KEYCLOAK_$(date '+%d%m%Y_%H').sql.gz______________________________________
#mysqldump --force -udscuser -pdscuser -h10.4.185.14 -P3306 KEYCLOAK --routines --lock-tables=false  | gzip -9 > BKP_DB_KEYCLOAK_$(date '+%d%m%Y_%H').sql.gz



echo _________________________BKP_DSC_OOREDOO_$(date '+%d%m%Y').tgz_____________________________________________________
ls -ltrh BKP_DB_*.sql.gz
tar -cvzf BKP_DSC_OOREDOO_$(/bin/hostname)_$(date '+%d%m%Y').tgz BKP_DB_*.sql.gz
rm -f BKP_DB_*.sql.gz
###number14
###number15
find /opt/6d/backup  -maxdepth 1 -type f -name 'BKP_*.tgz' -mtime +7 -exec rm -f {} \;
find  /opt/6d/backup  -maxdepth 1 -mindepth 1 -type f -name '*.sql.gz' -mtime +7 -exec rm -f {} \;

DAYOFWEEK=$(date +"%a")
echo DAYOFWEEK: $DAYOFWEEK
if (($DAYOFWEEK == "Fri"))
then
   echo "Today is $DAYOFWEEK So Trasferring to 70 Server" 
   #transferFile "BKP_DSC_OOREDOO_$(/bin/hostname)_$(date '+%d%m%Y').tgz" "10.4.181.12" "dscapusr" "Dscuser@123" "/opt/6d/backup"
   ###number2
else
   echo "Today is $DAYOFWEEK So exiting from here"
fi
