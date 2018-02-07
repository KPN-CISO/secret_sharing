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

GPGENV="$WORKDIR/gpgenv"

# Check if the workdir is a tmpfs
CHECK=`"$DF" "$WORKDIR" | "$GREP" -c "^tmpfs "`
if [ "$CHECK" != "1" ]
then
 echo "Please mount tmpfs on $WORKDIR with the command:"
 echo "mount -o size=10M -t tmpfs tmpfs \"$WORKDIR\""
 exit
fi

# Start gpg-agent
"$GPG_AGENT" --daemon --pinentry-prog "$PINENTRY" --write-env-file "$GPGENV"
source "$GPGENV"
GPG_AGENT_PID=`cut -d ":" -f 2 "$GPGENV"`
"$RM" "$GPGENV"
export GPG_AGENT_INFO

# Start gpg with the supplied parameters
"$GPG" --homedir "$GPGDIR" "$@"

# Kill gpg-agent
"$KILL" $GPG_AGENT_PID

