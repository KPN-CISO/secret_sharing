#!static_bin/bash
#
# Script: generate_key.sh
# 
# This script generates a new gpg keypair

set +v

# Check pwd
CURDIR="$PWD"
MYNAME="${0##*/}"

if [ ! -e "$CURDIR/$MYNAME" ]
then
 echo "Please run $0 the directory where it is installed with ./$MYNAME"
 exit
fi

# Set all variables
BASEDIR="$CURDIR"
BINDIR="$CURDIR/static_bin"
WORKDIR="$BASEDIR/work"
GPGDIR="$WORKDIR/gpghome"
GPG="$BINDIR/gpg2"
GPG_AGENT="$BINDIR/gpg-agent"
PINENTRY="$BINDIR/pinentry-tty"
SHA512SUM="$BINDIR/sha512sum"
DF="$BINDIR/df"
RM="$BINDIR/rm"
KILL="$BINDIR/kill"
GREP="$BINDIR/grep"
MKDIR="$BINDIR/mkdir"

GPGENV="$WORKDIR/gpgenv"

# Check if the workdir is a tmpfs
CHECK=`"$DF" "$WORKDIR" | "$GREP" -c "^tmpfs "`
if [ "$CHECK" != "1" ]
then
 echo "Please mount tmpfs on $WORKDIR with the command:"
 echo "mount -o size=10M -t tmpfs tmpfs \"$WORKDIR\""
 exit
fi
"$MKDIR" -p "$GPGDIR"

# Start gpg-agent
"$GPG_AGENT" --daemon --pinentry-prog "$PINENTRY" --write-env-file "$GPGENV"
source "$GPGENV"
GPG_AGENT_PID=`cut -d ":" -f 2 "$GPGENV"`
"$RM" "$GPGENV"
export GPG_AGENT_INFO

# Start gpg to actually generate the key
"$GPG" --homedir "$GPGDIR" --gen-key

# Kill gpg-agent
"$KILL" $GPG_AGENT_PID

# Give instructions to the user
echo ""
echo "Key has been generated and stored in a gpg database, use ./start_gpg.sh"
echo "instead of gpg2 to access the keys in the database. All commandline options"
echo "given to ./start_gpg.sh are passed to gpg2."
