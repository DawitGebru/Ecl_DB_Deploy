#!/bin/bash
TIMESTAMP=`date +%Y%m%d.%H%M%S`
SOURCE_HOST=192.168.1.5
exec > /esupport/migration/rsync.$TIMESTAMP.log
exec 2>&1


echo "`date`: started rsync"
rsync -av --stats --progress $SOURCE_HOST:/u2/eclipse/ /u2/eclipse/              
rsync -av --stats --progress $SOURCE_HOST:/u2/pdw/ /u2/pdw/              
rsync -av --stats --progress $SOURCE_HOST:/u2/MITS/ /u2/MITS/              
rsync -av --stats --progress $SOURCE_HOST:/u2/kore_temp/ /u2/kore_temp/              
rsync -av --stats --progress $SOURCE_HOST:/etc /esupport/migration/
rsync -av --stats --progress $SOURCE_HOST:/home /esupport/migration/
rsync -av --stats --progress $SOURCE_HOST:/u2/vsifax/lib/images /esupport/migration/
rsync -av --stats --progress $SOURCE_HOST:/usr/spool/uv /esupport/migration/
echo "`date`: completed rsync"



#chown -R eclipse:eclipse /u2/eclipse


tail /esupport/migration/rsync.$TIMESTAMP.log | mail -s "`hostname` data transfer complete" dgebru@epicor.com

