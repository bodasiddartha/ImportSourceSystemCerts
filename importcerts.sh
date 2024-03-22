read -p "Enter the <hostname>:<port> of the source system (port is 443 for HTTPS): " HOSTNAME1;
HOSTNAME=$( echo "$HOSTNAME1" |cut -d\: -f1 )
PORT=$( echo "$HOSTNAME1" |cut -d\: -f2 )
#echo $HOSTNAME
#echo $PORT;

keytool -printcert -sslserver "$HOSTNAME":"$PORT" -rfc > all.cer

if grep -q "error" <<< cat all.cer; then
#echo "Some error has occured, please cat on all.cer file to see the actual error"
cat all.cer;
exit 1;
fi

read -p "Enter the truststore/keystore path: " TRUSTSTORE;
if [ ! -f $TRUSTSTORE ]; then
echo "Please provide the explicit path including the filename"
exit 1;
fi

if  ! grep -q ".jks" <<< "$TRUSTSTORE"  &&  ! grep -q "cacert" <<< "$TRUSTSTORE"; then
echo "Please enter the explicit path including the file name(to cacerts or truststore/keystore)"
exit 1;
fi
read -s -p "Enter the password for the above provided file: " TRUSTSTOREPASS;
echo ""
read -p "Enter any aliasname: " ALIASNAME;

#echo $HOSTNAME;
#echo $TRUSTSTORE;
#echo $TRUSTSTOREPASS;
#echo $ALIASNAME;

#keytool -printcert -sslserver "$HOSTNAME":443 -rfc > all.cer
i=1;
for l in $(cat all.cer)
do
if [ '-----BEGIN' != "$l" ] && [ 'CERTIFICATE-----' != "$l" ] && [ '-----END' != "$l" ]; then
echo "$l" >> cert.cer
fi
if [ '-----BEGIN' == $l ]; then
echo '-----BEGIN CERTIFICATE-----' > cert.cer
fi
if [ '-----END' == $l ]; then
echo '-----END CERTIFICATE-----' >> cert.cer
#cat cert.cer
keytool -import -file cert.cer -noprompt -alias ""$ALIASNAME"_"$i"" -keystore "$TRUSTSTORE" -storepass "$TRUSTSTOREPASS";
i=$(($i+1));
fi
done
rm all.cer cert.cer
