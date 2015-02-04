#!/bin/bash
#rm sip_users.conf
#rm voicemail_users.conf
#rm extensions_local.conf

echo "SIP generator"

#echo "Input first extension ex: 100"
read -p "Input first extension:" first
first=${first:-100}
echo $first
#read first

read -p "Input step:" step
step=${step:-1}
echo $step

read -p "Input last extension:" last
last=${last:-199}
echo $last

read -p "Input extensions group:" group
group=${group:-local_users}
echo ${group}


read -p "Input extensions number plan dialplan:" exten
exten=${exten:-XXX}
echo $exten


read -p "Input context:" context
context=${context:-from-users}
echo $context


echo "["$context"]" >> voicemail.conf

touch users.txt
echo > users.txt
echo "users and secret" >> users.txt
echo ";--------------------------------" >> users.txt
echo ";--------------------------------" >> users.txt

echo "["$group"]""(!)" >> sip.conf

echo "type = peer" >> sip.conf
echo "host = dynamic" >> sip.conf
echo "dtmfmode = rfc2833" >> sip.conf
echo ";insecure = port,invite" >> sip.conf
echo "nat = auto_force_rport" >> sip.conf
echo "call-limit=2" >> sip.conf
echo "qualify = yes" >> sip.conf
echo "context = "$context >> sip.conf
echo "disallow=all" >> sip.conf
echo "allow=g722" >> sip.conf
echo "allow=ulaw" >> sip.conf
echo "allow=alaw" >> sip.conf
echo "allow=g729" >> sip.conf
echo ";----------------------------" >> sip.conf
echo ";----------------------------" >> sip.conf
echo "  " >> sip.conf

echo ";Local Dialplan" >> extensions.conf
echo ";----------------------------" >> extensions.conf
echo "  " >> extensions.conf
echo "["$context"]" >> extensions.conf
echo ";-------HINTS--------" >> extensions.conf
echo "  " >> extensions.conf


while [ $first -le $last ]
do
echo "["$first"]""("$group")" >> sip.conf
echo "username="$first |tee -a sip.conf users.txt
echo "secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1) |tee -a sip.conf users.txt
echo "callerid=\"$first"\" "<"$first">" >> sip.conf
echo "mailbox="$first"@"$context >> sip.conf
echo ";----------------------------" | tee -a sip.conf users.txt
echo "  " | tee -a sip.conf users.txt

echo $first" => "$first", User "$first"," >> voicemail.conf


echo "exten => "$first",hint,SIP/"$first  >> extensions.conf

first=`expr $first + $step`
done



echo ";---------EOF-----------------" >> sip.conf
echo ";---------EOF-----------------" >> voicemail.conf
echo "DONE"

echo "  " >> extensions.conf

echo "exten => _"$exten",1,NoOp(Call from \${CALLERID(num)} to \${EXTEN})"  >> extensions.conf
echo "exten => _"$exten",n,Set(TARGETNO=\${EXTEN})" >> extensions.conf
echo "exten => _"$exten",n,MixMonitor(\${STRFTIME(\${EPOCH},,%Y/%m/%d/local/%H:%M:%S)}-\${CALLERID(num)}-\${EXTEN}-\${UNIQUEID}.wav)" >> extensions.conf
echo "exten => _"$exten",n,Dial(SIP/\${EXTEN},40,Tt)" >> extensions.conf
echo "exten => _"$exten",n,Goto(s-\${DIALSTATUS},1)" >> extensions.conf
echo "exten => s-NOANSWER,1,VoiceMail(\${TARGETNO},u)" >> extensions.conf
echo "exten => s-BUSY,1,VoiceMail(\${TARGETNO},b)" >> extensions.conf
echo "exten => s-ANSWER,1,Hangup()" >> extensions.conf
echo "exten => s-.,1,Goto(s-NOANSWER,1)" >> extensions.conf
echo "exten => _"$exten",n,Hangup" >> extensions.conf


echo ";----------------------------" >> extensions.conf
echo "  " >> extensions.conf

echo "DONE"
