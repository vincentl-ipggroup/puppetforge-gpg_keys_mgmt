#!/bin/bash

PT_gpg_name=gpg_test-$(date +%Y%m%d%H%M%S)
PT_gpg_path=/root
PT_gpg_type=rsa
PT_gpg_length=4096
PT_gpg_comment=''
PT_gpg_email=''
PT_gpg_expire=3y
PT_gpg_passphrase=''
PT_owner=root
PT_tmpdir=/tmp

#Define Functions
fct_usage() {
echo "Usage: $(basename $0) -n <gpg_name> -p <gpg_path> -o <owner> [-t <gpg_type>] [-l <gpg_length>] [-e <gpg_expire>]" 
echo -e "       [-c <gpg_comment>] [-m <gpg_email>] [-k <gpg_passphrase>] [-d <tmpdir>]\n"
echo "        -n: Name of your gpg key"
echo "        -p: Absolute Path to store your key (without the .gnupg folder part)"
echo "        -o: Owner of your key"
echo "        -t: Type of your key                  (Default: rsa)"
echo "        -l: Length of your key                (Default: 2048 | Max dsa:3072/rsa:4096)"
echo "        -e: Expiration of your key in d,w,m,y (Default: 0 - never)"
echo "        -c: Comment                           (Default: auto-generated)"
echo "        -m: eMail associate                   (Default: none)"
echo "        -k: Passphrase/Key of your key        (Default: none)"
echo "        -d: Temporary folder                  (Default: /tmp)"
echo -e "\n    Example: $(basename $0) -n gpg_test -p /root -o root -t dsa -l 3072 -e 10w -d /var/tmp"
echo "    Please refer to the GPG man for more information on the type, length, expire options"
exit 5
}

fct_exit() {
RC=${1:-0}
#rm -f $TMPPUBRING $TMPSECRING $INPUTFILE >/dev/null 2>&1
if [ $RC -ge 20 ] || [ $RC == 0 ]
then
	chown -R $uidgid $GPGHOME >/dev/null 2>&1
fi
exit $RC
}

#Retrieve Options
while getopts n:p:o:t:l:e:c:m:k:d:?h name
do
    case $name in
    n)  gpg_name="$OPTARG"
        ;;  
    p)  gpg_path="$OPTARG"
        ;;  
    o)  owner="$OPTARG"
        ;;  
    t)  gpg_type="$OPTARG"
        ;;  
    l)  gpg_length="$OPTARG"
        ;;  
    e)  gpg_expire="$OPTARG"
        ;;  
    c)  gpg_comment="$OPTARG"
        ;;  
    m)  gpg_email="$OPTARG"
        ;;  
    k)  gpg_passphrase="$OPTARG"
        ;;  
    d)  tmpdir="$OPTARG"
        ;;  
    *)  fct_usage
        ;;
    esac
done

# Assigned Puppet Task variables
gpg_name=${gpg_name:-$PT_gpg_name}
gpg_path=${gpg_path:-$PT_gpg_path}
gpg_type=${gpg_type:-$PT_gpg_type}
gpg_type=${gpg_type:-rsa}
gpg_length=${gpg_length:-$PT_gpg_length}
gpg_length=${gpg_length:-2048}
gpg_comment=${gpg_comment:-$PT_gpg_comment}
gpg_email=${gpg_email:-$PT_gpg_email}
gpg_expire=${gpg_expire:-$PT_gpg_expire}
gpg_expire=${gpg_expire:-0}
gpg_passphrase=${gpg_passphrase:-$PT_gpg_passphrase}
owner=${owner:-$PT_owner}
tmpdir=${tmpdir:-$PT_tmpdir}
tmpdir=${tmpdir:-/tmp}

#Check required commands
CUT=/usr/bin/cut
SED=/usr/bin/sed
if [ ! -f $CUT ] || [ ! -f $SED ]
then
	AWK=/usr/bin/awk
	if [ ! -f $AWK ]
	then
		echo "This program required at least the following commands:"
		echo " - cut & sed"
		echo " - awk"
		fct_exit 8
	fi
fi
#Check the Variables
if [ -z "${gpg_name}" ] || [ -z "${gpg_path}" ] || [ -z "${owner}" ]
then
	echo "Missing required parameter"
	fct_usage
fi

if [ ! -d $tmpdir ]
then
	if [ ! -d /tmp ]
	then
		echo "$tmpdir & /tmp are not available as tmpdir folder"
		fct_exit 2
	else
		echo "$tmpdir is not available as tmpdir folder, substitued by /tmp"
		tmpdir=/tmp
	fi
fi

INPUTFILE=$tmpdir/gpg_inputfile.tmp.$$
TMPPUBRING=$tmpdir/gpg_pub_ring.tmp.$$
TMPSECRING=$tmpdir/gpg_sec_ring.tmp.$$
trap "rm ${INPUTFILE} ${TMPPUBRING} ${TMPSECRING} 2>/dev/null" 2 3 9 15


PASSWD=/etc/passwd

uidgid=$(grep "^${owner}:" $PASSWD | cut -d':' -f3,4)

if [ -z "${uidgid}" ]
then
	echo "${owner} not found in ${PASSWD}"
	fct_exit 3
fi

if [ ! -d "${gpg_path}" ]
then
	echo "${gpg_path} does not exit on the server"
	fct_exit 4
fi

GPGHOME=$gpg_path/.gnupg
if [ ! -d "${GPGHOME}" ]
then
	mkdir -p $GPGHOME >/dev/null
	chown $uidgid $GPGHOME
	GPGHOMEMAKE=1
fi
GPGHOMEDIR="--homedir ${GPGHOME}"
GPGPARAM="$GPGHOMEDIR --no-options --batch"

if [ -z "${gpg_comment}" ]
then
	COMMENT="GnuPG key automatically created by Puppet Task - $(date +%Y/%m/%d)"
else
	COMMENT="${gpg_comment}"
fi

if [ -z $gpg_email ]
then
	EMAIL=''
else
	EMAIL="Name-Email: ${gpg_email}"
fi

if [ -z $gpg_passphrase ]
then
	PASSPHRASE=''
else
	PASSPHRASE="passphrase: ${gpg_passphrase}"
fi

### Generate the GPG Key Input file
echo "# input file to generate GnuPG keys automatically
%echo Generating a standard key
Key-Type: ${gpg_type}
Key-Length: ${gpg_length}
Subkey-Type: rsa
Subkey-Length: 4096
Name-Real: ${gpg_name}
Name-Comment: ${COMMENT}
${EMAIL}
Expire-Date: ${gpg_expire}
${PASSPHRASE}
# the keyring files
%pubring $tmpdir/gpg_pub_ring.tmp.$$
%secring $tmpdir/gpg_sec_ring.tmp.$$
# perform key generation
%commit
%echo done" > $INPUTFILE

### Generate the keys and import them
#Restart the gpg-agent
GPGAGENT_INFO=$(ps -eo pid,command | grep gpg-agent | grep -Ev 'grep')
if [ ! -z $AWK ]
then
        GPGAGENT_CMD=$(echo $GPGAGENT_INFO | $AWK '{for(i=2;i<=NF;i++)}')
        GPGAGENT_PID=$(echo $GPGAGENT_INFO | $AWK '{print $1}')
else
        GPGAGENT_CMD=$(echo $GPGAGENT_INFO | $CUT -d' ' -f2-)
        GPGAGENT_PID=$(echo $GPGAGENT_INFO | $CUT -d' ' -f1)
fi
GPGAGENT_CMD=${GPGAGENT_CMD:-"gpg-agent --daemon --use-standard-socket"}
if [ ! -z "${GPGAGENT_PID}" ]
then
	kill -9 $GPGAGENT_PID >/dev/null 2>&1
fi
source <($GPGAGENT_CMD)

#Generate the key files
gpg $GPGPARAM --gen-key $INPUTFILE
if [ $? != 0 ]
then
	echo -e "\nError: Unable to generate the key, please check your options"
	fct_exit 10
fi
#Import the key files
gpg $GPGPARAM --status-fd 2 --logger-fd 2 --verbose --import $TMPPUBRING $TMPSECRING
if [ $? != 0 ]
then
	echo -e "\nError: Unable to import the new key"
	fct_exit 15
fi
#Retrieve the fingerprint
if [ ! -z $AWK ]
then
	FINGERPRINT=$(gpg -k $GPGHOMEDIR --with-fingerprint $gpg_name | grep fingerprint | $AWK -F'=' '{print $2}' | $AWK '{for(i=1;i<=NF;i++)}')
else
	FINGERPRINT=$(gpg -k $GPGHOMEDIR --with-fingerprint $gpg_name | grep fingerprint | $CUT -d'=' -f2- | $SED -e 's/ //g')
fi
if [ $(echo -n "${FINGERPRINT}" | wc -c) != 40 ]
then
	echo -e "\nError: Invalid Fingerprint - Unable to set the Trust level"
	fct_exit 20
fi
echo "${FINGERPRINT}:6" | gpg --import-ownertrust $GPGPARAM --yes
if [ $? != 0 ]
then
	echo -e "\nError: Failed to import-ownertrust - Unable to set the Trust level"
	fct_exit 25
fi

fct_exit 0
