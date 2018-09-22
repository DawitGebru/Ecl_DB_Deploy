#!/bin/bash
TIMESTAMP=`date +%Y%m%d.%H%M%S`
exec > /esupport/migration/uvcheck.$TIMESTAMP.log
exec 2>&1

echo "`date`: started uvbackup check"
find /u2/eclipse |  egrep -v "DATA.30|OVER.30|.Type30|modules|.zip" > /esupport/migration/backup.list
/u2/uv/bin/uvbackup -f -v -cmdfil /esupport/migration/backup.list -limit 1 -notag > /dev/null
echo "`date`: completed uvbackup check"

