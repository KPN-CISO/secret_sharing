#!static_bin/bash
#
# Script: verify_files.sh
#
# This script verifies all files based on sha512 hashes

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
SHA512SUM="$BINDIR/sha512sum"
CAT="$BINDIR/cat"
HASHFILE="$BASEDIR/verify_files.sha512"

# Verify ourselves
OFFSET="-9"
MYHASH=`"$CAT" "$CURDIR/$MYNAME" | while read -r LINE
do
 if [ "${LINE:$OFFSET}" != "#HASHLINE" ]
 then
  echo "$LINE"
 fi
done | "$SHA512SUM"`

HASHLINES=0
HASHLINES=`"$CAT" "$CURDIR/$MYNAME" | while read -r LINE
do
 if [ "${LINE:$OFFSET}" = "#HASHLINE" ]
 then
  HASHLINES=$((HASHLINES+1))
  echo -n " $HASHLINES"
 fi
done`
HASHLINES=${HASHLINES##* }

if [ "$MYHASH" = "98436cba77de7537211cba7adbb1cf01b3ce650b9bac2e761de5fd7dacdd9237841f733ac6b3e375b6f1a68e94ab4c0a98112e695b48dcf2778894a0ac691877  -" ] #HASHLINE
then
 echo "$MYNAME: OK"
else
 echo "$MYNAME: FAILED"
fi

if [ "$HASHLINES" != "1" ]
then
 echo "$HASHLINES hashlines detected in $CURDIR/$MYNAME, this should not happen, do not trust the results of this script"
fi

# Verify the hashfile
HASHFILEHASH=`"$CAT" "$HASHFILE" | "$SHA512SUM"`
if [ "$HASHFILEHASH" = "60f843c9b904c05fe81e066f8cd74ac6ac9eae1ea970a1f28bc5b886c80d5d74750dc1cd1f56306b9c42303c29ea3f2ea6357a8ec3c53f91b352eb1668e06156  -" ]
then
 echo "$HASHFILE: OK"
else 
 echo "$HASHFILE: FAILED"
fi

# Verify the rest of the files
"$SHA512SUM" -c "$HASHFILE"

