#Set Variables
INPUTFILE=./gpg_param
TMPPUBRING=/tmp/gpg_pub_ring.tmp
TMPSECRING=/tmp/gpg_sec_ring.tmp
GPGHOME="--homedir /root/.gnupg/"
GPGPARAM="$GPGHOME --no-options --batch"

#Generate the key files
gpg $GPGPARAM --gen-key $INPUTFILE

#Import the key files
gpg $GPGPARAM --status-fd 2 --logger-fd 2 --verbose --import $TMPPUBRING $TMPSECRING
