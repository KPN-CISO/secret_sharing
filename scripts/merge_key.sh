#!static_bin/bash
#
# Script: split_key.sh
#
# This script splits a key into parts usable for secret sharing

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
SHA512SUM="$BINDIR/sha512sum"
OPENSSL="$BINDIR/openssl"
MV="$BINDIR/mv"
CAT="$BINDIR/cat"
UNZIP="$BINDIR/unzip"
DF="$BINDIR/df"
GREP="$BINDIR/grep"
MKDIR="$BINDIR/mkdir"

export OPENSSL_CONF="$BINDIR/openssl.cnf"

# Check if the workdir is a tmpfs
CHECK=`"$DF" "$WORKDIR" | "$GREP" -c "^tmpfs "`
if [ "$CHECK" != "1" ]
then
 echo "Please mount tmpfs on $WORKDIR with the command:"
 echo "mount -o size=10M -t tmpfs tmpfs \"$WORKDIR\""
 exit
fi

cd "$WORKDIR"
PARTCOUNT=0

# Decrypt the sets with personal passwords
for((COUNT=1;COUNT<=3;COUNT++))
do
 if [ -r "set$COUNT.zip.aes" ]
 then
  KEY=""
  echo -n "Key for SET $COUNT: "
  read -s KEY
  echo ""

  "$OPENSSL" aes256 -d -k "$KEY" -in "set$COUNT.zip.aes" -out "set$COUNT.zip"
  if [ "$?" = "0" ]
  then
   echo "Decryption ok"
   PARTCOUNT=$(($PARTCOUNT+1))
  fi
 fi
done

echo "Succesfully decrypted $PARTCOUNT sets"
if [ "$PARTCOUNT" -lt 2 ]
then
 echo "Not enough sets avilable for key reconstruction."
 echo "Copy all available sets to $WORKDIR and try again."
 exit
fi

# Unzip the sets, rename hash file to something unique so we can check them all
for((COUNT=1;COUNT<=3;COUNT++))
do
 if [ -r "set$COUNT.zip" ]
 then
  echo "Unpacking SET$COUNT"
  "$UNZIP" -n "set$COUNT.zip"
  "$MV" "hashes.sha512" "hashes.sha512.$COUNT"
 fi
done

# Merge all parts
echo "Merging parts"
"$CAT" aeskey.split.1 aeskey.split.2 aeskey.split.3 > aeskey
"$CAT" private_key.aes.split.1 private_key.aes.split.2 private_key.aes.split.3 > private_key.aes
"$CAT" public_key.aes.split.1 public_key.aes.split.2 public_key.aes.split.3 > public_key.aes

# Decrypt the keys
echo "Decrypting keys"
"$OPENSSL" aes256 -d -kfile "$WORKDIR/aeskey" -in "$WORKDIR/private_key.aes" -out "$WORKDIR/private_key"
"$OPENSSL" aes256 -d -kfile "$WORKDIR/aeskey" -in "$WORKDIR/public_key.aes" -out "$WORKDIR/public_key"

FAILED=0
# Verify the hashes
for((COUNT=1;COUNT<=3;COUNT++))
do
 if [ -r "hashes.sha512.$COUNT" ]
 then
  echo "Verifying files in SET$COUNT"
  "$SHA512SUM" --quiet -c "hashes.sha512.$COUNT"
  if [ "$?" != "0" ]
  then
   FAILED=1
  fi
 fi
done

if [ "$FAILED" = "1" ]
then
 echo "Some files failed the hash verification, not importing key files"
 exit
fi

# Import them to the GPG keyring
echo "Importing keys"
"$MKDIR" -p "$GPGDIR"
"$GPG" --homedir "$GPGDIR" --import "$WORKDIR/public_key"
"$GPG" --homedir "$GPGDIR" --import "$WORKDIR/private_key"

# Give instructions to the user
echo ""
echo "Key has been imported into a gpg database, use ./start_gpg.sh"
echo "instead of gpg2 to access the keys in the database. All commandline options"
echo "given to ./start_gpg.sh are passed to gpg2."

