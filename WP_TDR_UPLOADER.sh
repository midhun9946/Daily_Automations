#!/bin/bash

getTime (){
        echo "[ $(date '+%d-%m-%Y %H:%M:%S') ]"
}


tdr_tble_value_update () {
        dbserverIP=${1}
        dbserverPort=${2}
        dbserverUserName=${3}
        dbserverPassword=${4}
        dbbaseName=${5}
	dbInstanceToken=${7}
	dbTableName=${6}
	dbUploadFileName="${8}"
	echo "$(getTime) TDR Table UPDATE [ ${dbserverIP} - ${dbserverPort} - ${dbserverUserName} - ${dbserverPassword} - ${dbbaseName} :: ${dbTableName} >> ${dbInstanceToken} >> ${dbUploadFileName} ]"
	mysql -h${dbserverIP} -P${dbserverPort} -u${dbserverUserName} -p${dbserverPassword} ${dbbaseName} -Ae "UPDATE ${dbbaseName}.${dbTableName} SET EXTRA_2=STATUS, STATUS='FAILURE' WHERE API_NAME='getCartItems' AND STATUS <> 'SUCCESS' AND TDR_FILENAME = '${dbUploadFileName}';"
	mysql -h${dbserverIP} -P${dbserverPort} -u${dbserverUserName} -p${dbserverPassword} ${dbbaseName} -Ae "UPDATE ${dbbaseName}.${dbTableName} SET STATUS='SUCCESS' WHERE API_NAME='getCartItems' AND EXTRA_2 LIKE '%FAILURE - No such entity with%' AND TDR_FILENAME = '${dbUploadFileName}';"
	mysql -h${dbserverIP} -P${dbserverPort} -u${dbserverUserName} -p${dbserverPassword} ${dbbaseName} -Ae "UPDATE ${dbbaseName}.${dbTableName} SET EXTRA_2=STATUS, STATUS=TRIM(SUBSTRING(STATUS,1,POSITION('-' IN STATUS)-1)) WHERE STATUS LIKE '%-%' AND TDR_FILENAME = '${dbUploadFileName}';"
        mysql -h${dbserverIP} -P${dbserverPort} -u${dbserverUserName} -p${dbserverPassword} ${dbbaseName} -Ae "UPDATE ${dbbaseName}.${dbTableName} SET MSISDN = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(SUBSTRING_INDEX(SUBSTRING_INDEX(EXTRA_2, '-', 3), '-', -1),'&&',''), ',', 1), '-', -1)) WHERE TRIM(EXTRA_2) <> '' AND UPPER(EXTRA_2) LIKE '%MSISDN%' AND TDR_FILENAME = '${dbUploadFileName}';"
        mysql -h${dbserverIP} -P${dbserverPort} -u${dbserverUserName} -p${dbserverPassword} ${dbbaseName} -Ae "UPDATE ${dbbaseName}.${dbTableName} SET CUSTOMER_ID = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(EXTRA_2, '-', CHAR_LENGTH(EXTRA_2) - LOCATE('-', REVERSE(EXTRA_2))+1), '-', -1)) WHERE TRIM(EXTRA_2) <> '' AND UPPER(EXTRA_2) LIKE '%CUSTOMER_ID%' AND TDR_FILENAME = '${dbUploadFileName}';"
}

cdrFileDBUploader () {
	dbserverIP=${1}
	dbserverPort=${2}
	dbserverUserName=${3}
	dbserverPassword=${4}
	dbbaseName=${5}
	dbTableName=${6}
        fileUploaddStatus=0
        retryCnt=0
        dbUploadStatus=false
	dbInstanceToken=$((dbInstanceToken + 1))
	tdr_file_sourcesystem=$(/bin/hostname)
        tdr_file_sourcesystem=${tdr_file_sourcesystem^^}

        while (($fileUploaddStatus == 0)) && (($tdrfile_upload_retry_counter >= $retryCnt))
        do
                echo "$(getTime) Loading TDR File :: ${fileName} Having Size :: ${fileSize} into DB [ ${dbserverIP} - ${dbserverPort} - ${dbserverUserName} - ${dbserverPassword} - ${dbbaseName} - ${dbTableName} >> ${dbInstanceToken} >> ${tdr_file_basename} ]"
                mysql -h${dbserverIP} -P${dbserverPort} -u${dbserverUserName} -p${dbserverPassword} ${dbbaseName} -Ae "LOAD DATA LOCAL INFILE '${fileName}' INTO TABLE ${dbbaseName}.${dbTableName} FIELDS TERMINATED BY '${tdrfile_field_delimiter}' LINES TERMINATED BY '${tdrfile_line_delimiter}' (EXTRA_1,@TDR_TIMESTAMP,@BUSINESS_TYPE,@USER_TYPE,@REQUEST_TYPE,@API_NAME,@STATUS,@FEATURE_NAME,@REQUEST_ID,@DEVICE_TYPE,@REMOTE_ADDRESS,@SESSION_ID,@PROCESS_ID,TDR_FILENAME) SET TDR_TIMESTAMP=TRIM(@TDR_TIMESTAMP), BUSINESS_TYPE=TRIM(@BUSINESS_TYPE), USER_TYPE=TRIM(@USER_TYPE), REQUEST_TYPE=TRIM(@REQUEST_TYPE), API_NAME=TRIM(@API_NAME), STATUS=TRIM(@STATUS), FEATURE_NAME=TRIM(@FEATURE_NAME), REQUEST_ID=TRIM(@REQUEST_ID), DEVICE_TYPE=TRIM(@DEVICE_TYPE), REMOTE_ADDRESS=TRIM(@REMOTE_ADDRESS), SESSION_ID=TRIM(@SESSION_ID), PROCESS_ID=TRIM(@PROCESS_ID), REQUEST_TIME=SUBSTRING_INDEX(TDR_TIMESTAMP,',',1), REQUEST_DATE=DATE(REQUEST_TIME), TDR_FILENAME='${tdr_file_basename}', TDR_SOURCE_SYSTEM='${tdr_file_sourcesystem}';" 
		executionStatus=$?
#| grep -v "Using a password on the command line interface can be insecure" 1>$propFilePath/mysql_LoadData_TDR.err 2>&1

                if (( ${executionStatus} > 0 ))
                then
                        echo "**********************MYSQL ERROR - ${dbserverIP} >> ${dbserverPort} >> ${dbserverUserName} >> ${dbbaseName}**********************"
                        fileUploaddStatus=0
                else
                        fileUploaddStatus=1
                fi
                
		if (($fileUploaddStatus == 1))
                then
			tdr_tble_value_update ${dbserverIP} ${dbserverPort} ${dbserverUserName} ${dbserverPassword} ${dbbaseName} ${dbTableName} ${dbInstanceToken} ${tdr_file_basename}
			tdr_tble_value_update ${dbserverIP} ${dbserverPort} ${dbserverUserName} ${dbserverPassword} ${dbbaseName} ${dbTableName} ${dbInstanceToken} ${tdr_file_basename}
                        dbUploadStatus=true
			if ((${dbInstanceToken} == 1))
			then
				dbFileUploadStatusFLAG=$(echo ${dbFileUploadStatusFLAG} | sed s/./1/1)
			elif ((${dbInstanceToken} == 2))
                        then
				dbFileUploadStatusFLAG=$(echo ${dbFileUploadStatusFLAG} | sed s/./1/2)
			fi
                        echo "$(getTime) Successfully Loaded the TDR From File :: ${fileName} Having File Size :: ${fileSize} into DB With IP :: ${dbserverIP}."
                else
                        retryCnt=$((retryCnt + 1))
                        echo "$(getTime) WARNING: Uploading of TDR File ${fileName} into DB With IP ${dbserverIP} Failed, Retring File Upload - Retry Counter = $retryCnt."
                        if (($tdrfile_upload_retry_counter < $retryCnt))
                        then
                                echo "$(getTime) ERROR: File Upload Retry Count Value Exceeds - Retry Counter = $retryCnt, Uploading of File ${fileName} into DB ${dbserverIP} Stopping Forcefully."
                        fi
                        dbUploadStatus=false
                        sleep 1
                fi
        done
        rm -f $propFilePath/mysql_LoadData_TDR.err
}
#_____________________________________________________________________________________________________________________________________________________________

#Checking Script is Already Running or not...
if (($(ps ax | grep $(basename ${0}) | grep -v grep | wc -l) > 3))
then
        echo "$(getTime) WARNING: Since  $(basename ${0}) is Already Running Exiting the new Instance."
        ps ax | grep $(basename ${0}) | grep -v grep
        exit 0
fi

#Loading the Properties File
path=${0}
thisfileName=$(basename ${0})
length=$((${#path} - ${#thisfileName}))
if (($length == 0))
then
        propFilePath="./"
else
        propFilePath=${path:0:$length}
fi

if ((${#propFilePath} <= 1))
then
        appPath=$(pwd)
        cd ${appPath}
fi

#cdrFileIndex=$(echo ${thisfileName} | awk -F'_' '{print $NF}' |  awk -F'.' '{print $1}')
cdrFileIndex=""

echo "$(getTime) Getting the Details From Properties File Located in the Path = " $propFilePath
. ${propFilePath}WP_TDR_UPLOADER.PROPERTIES

#Getting the details 
db01_ConnectStatus=$(echo > /dev/tcp/${db_ip}/${db_port} >/dev/null 2>&1 && echo 1 || echo 0) 2>&1
db02_ConnectStatus=$(echo > /dev/tcp/${db2_ip}/${db2_port} >/dev/null 2>&1 && echo 1 || echo 0) 2>&1

if ((${db01_ConnectStatus} == 0)) && ((${db02_ConnectStatus} == 0))
then
	echo "ERROR:: BOTH THE DB's ARE NOT ACCESSABLE [ DB01 :: IP-${db_ip} PORT-${db_port} STATUS-${db01_ConnectStatus} DB02 :: IP-${db2_ip} PORT-${db2_port} STATUS-${db02_ConnectStatus} ]"
        exit 0
fi

#mysqladmin -u${db_user} -p${db_pwd} -P${db_port} -h${db_ip} flush-hosts
#mysqladmin -u${db_user} -p${db_pwd} -P${db2_port} -h${db2_ip} flush-hosts

echo "$(getTime) ***********************************TDR UPLOADING PROCESS STARTING With the Following Parameters************************************"
echo "TDR_UPLOAD Table Prefx		= "${tdrfile_upload_table_prefix}
echo "TDR_UPLOAD Table Columns	= "${tdrfile_upload_table_columns}
echo "TDR_UPLOAD Source File Path       = "${tdrfile_source_path}
echo "TDR_UPLOAD Backup File Path       = "${tdrfile_output_path}
echo "TDR File Prefix          	= "${tdrfile_prefix}${cdrFileIndex}
echo "TDR File Postfix         	= "${tdrfile_postfix}
echo "TDR Field Delimiter	= "${tdrfile_field_delimiter}
echo "TDR Line Delimiter	= "${tdrfile_line_delimiter}
echo "TDR_UPLOAD Retry Count      	= "${tdrfile_upload_retry_counter}
echo "DB01 TDR Upload Failed Path 	= "${db1_tdr_upload_failure_path}
echo "DB02 TDR Upload Failed Path 	= "${db2_tdr_upload_failure_path}
echo 

tdrfile_upload_file_prefix_length=$(expr $tdrfile_prefix : '.*')

tdrfile_counter=0
tmpFileName=""
today_date=$(date '+%d_%m_%Y')
ystrday_date=$(date --date='1 days ago' '+%d_%m_%Y')

echo "$tdrfile_source_path - ${tdrfile_prefix}${cdrFileIndex}-*${tdrfile_postfix}"
for fileName in $(find $tdrfile_source_path -maxdepth 1 -name "${tdrfile_prefix}${cdrFileIndex}-*${tdrfile_postfix}")
do
	/usr/bin/dos2unix ${fileName}
	dbInstanceToken=0
	dbFileUploadStatusFLAG="00"
	db1UploadStatus=false
	db2UploadStatus=false
        tdrfile_counter=$((tdrfile_counter + 1))
	tdr_file_basename=$(basename ${fileName})

	#dsc_track-2020-08-07.17.09.log*
        tdr_date=$(echo ${tdr_file_basename} | awk -v OFS='_' -F'-' '{print $2,$3,$4}' | awk -v OFS='_' -F'.' '{print $1,$2,$3}')
        year=$(echo ${tdr_date} | awk -F"_" '{print $1}')
        month=$(echo ${tdr_date} | awk -F"_" '{print $2}')
        day=$(echo ${tdr_date} | awk -F"_" '{print $3}')
        hour=$(echo ${tdr_date} | awk -F"_" '{print $4}')

	#trd_upload_tablename_index=$(echo ${file} | awk -v OFS='_' -F'_' '{print $2}')
	#trd_upload_tablename=${tdrfile_upload_table_prefix}${trd_upload_tablename_index}
	#trd_upload_tablename=$(echo ${file} | awk -v OFS='_' -F'_' '{print $1,$2}')
	#trd_upload_tablename="DSC_TDR"

        echo "$(getTime) __________TDR_UPLOAD_PROCESSING :: TDR_FILE - ${fileName} TDR_DATE - ${tdr_date} TDR_TABLE - ${trd_upload_tablename}__________"
        
	fileSize=$(du -h ${fileName} | awk '{print $1}')
	cdrFileDBUploader ${db_ip} ${db_port} ${db_user} ${db_pwd} ${db_name} ${trd_upload_tablename}
	cdrFileDBUploader ${db2_ip} ${db2_port} ${db_user} ${db_pwd} ${db2_name} ${trd_upload_tablename}
	
	if ((${dbInstanceToken} == 1))
	then
		dbFileUploadStatusFLAG='11'
	fi

	if [[ ${dbFileUploadStatusFLAG} = 10 ]]
	then
		db1UploadStatus=true
	elif [[ ${dbFileUploadStatusFLAG} = 01 ]]
        then
                db2UploadStatus=true
	elif [[ ${dbFileUploadStatusFLAG} = 11 ]]
        then
		db1UploadStatus=true
                db2UploadStatus=true
	fi
	
	mkdir -p ${tdrfile_output_path}
        echo "$(getTime) TDR File :: ${fileName} UPLOAD STATUS - DB01 :: ${db1UploadStatus}, DB02 :: ${db2UploadStatus}"
        if ($db1UploadStatus) && (${db2UploadStatus})
        then
                echo "$(getTime) Processing of ${fileName} is Completed."
                file_date=${day}_${month}_${year}
                file_dir=${tdrfile_output_path}/${tdrfile_prefix}${cdrFileIndex}_${file_date}
		echo ${file_dir}
                if [ $file_date = $today_date ]
                then
                        if [ ! -d "$file_dir" ]
                        then
                                mkdir -p $file_dir
                        fi
                        echo "$(getTime) Moving ${fileName} From $tdrfile_source_path to $file_dir"
                        mv ${fileName} ${tmpFileName} $file_dir
                elif [ $file_date = $ystrday_date ]
                then
                        if [ -e "${file_dir}.zip" ]
                        then
                                mkdir -p $file_dir
                                echo "$(getTime) Moving ${fileName} From $tdrfile_source_path to $file_dir"
                                mv ${fileName} ${tmpFileName} $file_dir
                                cd ${tdrfile_output_path}
                                zip -rq ${file_dir}.zip ${tdrfile_prefix}${cdrFileIndex}_${file_date}
                                rm -rf $file_dir
                                cd -
                        else
                                mkdir -p $file_dir
                                echo "$(getTime) Moving ${fileName} From $tdrfile_source_path to $file_dir"
                                mv ${fileName} ${tmpFileName} $file_dir
                        fi
                else
                        mkdir -p $file_dir
                        echo "$(getTime) Moving ${fileName} From $tdrfile_source_path to $file_dir"
                        mv ${fileName} ${tmpFileName} $file_dir
                        cd ${tdrfile_output_path}
                        zip -rq ${file_dir}.zip ${tdrfile_prefix}${cdrFileIndex}_${file_date}
                        rm -rf $file_dir
                        cd -
                fi                
        elif !($db1UploadStatus) && !(${db2UploadStatus})
        then
                echo "$(getTime) WARNING: TDR File Upload Failed in all the DB's."
                echo "$(getTime) Coping File ${fileName} into Upload Failed Path $db1_tdr_upload_failure_path."
                mkdir -p $db1_tdr_upload_failure_path
                cp ${fileName} ${tmpFileName} $db1_tdr_upload_failure_path
                echo "$(getTime) Moving TDR File ${fileName} into Upload Failed Path $db2_tdr_upload_failure_path."
                mkdir -p $db2_tdr_upload_failure_path
                mv ${fileName} ${tmpFileName} $db2_tdr_upload_failure_path
        elif !($db1UploadStatus)
        then
                echo "$(getTime) WARNING: TDR File Upload Failed in the DB With IP $db_ip."
                echo "$(getTime) Moving File ${fileName} into Upload Failed Path $db1_tdr_upload_failure_path."
                mkdir -p $db1_tdr_upload_failure_path
                mv ${fileName} ${tmpFileName} $db1_tdr_upload_failure_path
        elif !(${db2UploadStatus})
        then
                echo "$(getTime) WARNING: TDR File Upload Failed in the DB With IP $db2_ip."
                echo "$(getTime) Moving File ${fileName} into Upload Failed Path $db2_tdr_upload_failure_path."
                mkdir -p $db2_tdr_upload_failure_path
                mv ${fileName} ${tmpFileName} $db2_tdr_upload_failure_path
        fi
        echo
done

#echo "$(getTime) Changing the Path to SUB CDR Backup Path $tdrfile_output_path."
cd $tdrfile_output_path
ystrday_dir=${tdrfile_output_path}/${tdrfile_prefix}${cdrFileIndex}_${ystrday_date}
if [ -d "$ystrday_dir" ]
then
        zip -rq ${tdrfile_prefix}${cdrFileIndex}_${ystrday_date}.zip ${tdrfile_prefix}${cdrFileIndex}_${ystrday_date}
        rm -rf ${tdrfile_prefix}${cdrFileIndex}_${ystrday_date}
fi
echo "$(getTime) CDR Backuping Completed, Changing the Path to Home Path."
cd -

if (($tdrfile_counter == 0))
then
        echo "$(getTime) There is No CDR Files to Process."
else
#	tdr_tble_value_update ${db_ip} ${db_port} ${db_user} ${db_pwd} ${db_name} ${trd_upload_tablename} 1
#	tdr_tble_value_update ${db2_ip} ${db2_port} ${db_user} ${db_pwd} ${db2_name} ${trd_upload_tablename} 2
	echo "$(getTime) Number of Files Processed = $tdrfile_counter"
fi
echo "$(getTime) *************************************************CDR UPLOADING PROCESS COMPLETED***************************************************"
echo
