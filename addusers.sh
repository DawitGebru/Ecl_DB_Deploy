TIMESTAMP=`date +%Y%m%d.%H%M%S`
ECLIPSEHOME=/u2/eclipse

echo "`date`: backing up /etc/passwd to /etc/passwd.$TIMESTAMP"
cp /etc/passwd /etc/passwd.$TIMESTAMP

for USER in `cat passwd | awk -F":" '{print $1}' | sort`
do
        echo "Creating OS user account for: $USER"
        useradd -G eclipse $USER
        ln -sf $ECLIPSEHOME/.profile /home/$USER/.bash_profile
        # The next line sets the users' password to NULL
        usermod -p "" $USER
        # The next line will optionally force all users to change their password at the first login
        chage -d 0 $USER
done

