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
BINDIR="$BASEDIR/static_bin"
WORKDIR="$BASEDIR/work"
GPGDIR="$WORKDIR/gpghome"
GPG="$BINDIR/gpg2"
SHA512SUM="$BINDIR/sha512sum"
OPENSSL="$BINDIR/openssl"
DD="$BINDIR/dd"
SPLIT="$BINDIR/split"
ZIP="$BINDIR/zip"
DF="$BINDIR/df"
GREP="$BINDIR/grep"
BASE64="$BINDIR/base64"

export OPENSSL_CONF="$BINDIR/openssl.cnf"

# Check if the workdir is a tmpfs
CHECK=`"$DF" "$WORKDIR" | "$GREP" -c "^tmpfs "`
if [ "$CHECK" != "1" ]
then
 echo "Please mount tmpfs on $WORKDIR with the command:"
 echo "mount -o size=10M -t tmpfs tmpfs \"$WORKDIR\""
 exit
fi

# Check usage
if [ -z "$1" ]
then
 echo "Usage: $MYNAME <key identifier>"
 exit
fi
KEY="$1"

# Export the keys
echo "Exporting keys"
"$GPG" --homedir "$GPGDIR" --armor --export-secret-keys "$KEY" > "$WORKDIR/private_key"
"$GPG" --homedir "$GPGDIR" --armor --export "$KEY" > "$WORKDIR/public_key"

# generate a new aes key
echo "Generating AES key"
"$DD" if=/dev/urandom bs=1 count=24 | "$BASE64" > "$WORKDIR/aeskey"

# Encrypt the keys with the generated aes key
echo "Encrypting keys"
"$OPENSSL" aes256 -e -kfile "$WORKDIR/aeskey" -in "$WORKDIR/private_key" -out "$WORKDIR/private_key.aes"
"$OPENSSL" aes256 -e -kfile "$WORKDIR/aeskey" -in "$WORKDIR/public_key" -out "$WORKDIR/public_key.aes"

# Split everything in 3 parts
echo "Splitting keys"
"$SPLIT" -n 3 -a 1 --numeric-suffixes=1 "$WORKDIR/aeskey" "$WORKDIR/aeskey.split."
"$SPLIT" -n 3 -a 1 --numeric-suffixes=1 "$WORKDIR/private_key.aes" "$WORKDIR/private_key.aes.split."
"$SPLIT" -n 3 -a 1 --numeric-suffixes=1 "$WORKDIR/public_key.aes" "$WORKDIR/public_key.aes.split."

cd "$WORKDIR"

# Hash everything so we can verify on extraction
echo "Generating hashes"
"$SHA512SUM" private_key* public_key* aeskey* >  hashes.sha512

# Generate the sets
echo "Creating SET1"
"$ZIP" set1.zip private_key.aes.split.1 private_key.aes.split.2 public_key.aes.split.2 public_key.aes.split.3 aeskey.split.3 aeskey.split.1 hashes.sha512
echo "Creating SET2"
"$ZIP" set2.zip private_key.aes.split.2 private_key.aes.split.3 public_key.aes.split.3 public_key.aes.split.1 aeskey.split.1 aeskey.split.2 hashes.sha512
echo "Creating SET3"
"$ZIP" set3.zip private_key.aes.split.3 private_key.aes.split.1 public_key.aes.split.1 public_key.aes.split.2 aeskey.split.2 aeskey.split.3 hashes.sha512

# Ecrypt the sets with personal passwords
for((COUNT=1;COUNT<=3;COUNT++))
do
 KEY1=""
 KEY2=" "
 while [ "$KEY1" != "$KEY2" ]
 do
  echo -n "Key for SET $COUNT: "
  read -s KEY1
  echo ""
  echo -n "Re-type the Key for SET $COUNT: "
  read -s KEY2
  echo ""
  if [ "$KEY1" != "$KEY2" ]
  then
   echo "Provided keys did not match, try again"
  fi
 done
 "$OPENSSL" aes256 -e -k "$KEY1" -in set$COUNT.zip -out set$COUNT.zip.aes
done

# Instruct the user
echo ""
echo "The following files have been generated:"
ls -l "$WORKDIR"/set[1-3].zip.aes
echo ""
echo "Distribute them over the corresponding media."

