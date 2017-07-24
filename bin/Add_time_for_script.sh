#!/bin/bash
if [ $# -eq 0 ]
then
	echo "";
	echo "Usage: Add_time_for_script.sh script";
	echo ""
        exit
fi

separator=`printf '*%.0s' {1..80}`

sed -i "1i#!/bin/bash\necho \"${separator}Start at:\`date '+%Y/%m/%d  %H:%M:%S'\`$separator\"" $1

echo "echo \"${separator}End at:\`date '+%Y/%m/%d  %H:%M:%S'\`$separator\"" >> $1

chmod 755 $1
