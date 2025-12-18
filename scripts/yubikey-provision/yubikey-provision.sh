#!/usr/bin/env bash

info="$(ykman info)"
echo "$info"

ykman config usb --enable u2f --enable fido2 --enable oath --enable piv --enable openpgp
ykman config usb --disable otp --disable hsmauth

if [[ "$info" =~ NFC ]]
then
  ykman config nfc --enable u2f --enable fido2 --enable oath --enable openpgp
  ykman config nfc --disable otp --disable piv --disable hsmauth
fi

echo "Set FIDO PIN"
ykman fido access change-pin

echo "Set OATH PIN"
ykman oath access change
