#!/bin/bash 
rm sip_users.conf 
rm voicemail_users.conf 
rm extensions_local.conf 

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


read -p "Input extensions dialplan:" exten
exten=${exten:-XXX}
echo $exten


read -p "Input context:" context
context=${context:-from-users}
echo $context 


echo "["$context"]" >> voicemail_users.conf 

echo "["$group"]""(!)" >> sip_users.conf

echo "type = friend" >> sip_users.conf
echo "host = dynamic" >> sip_users.conf
echo "dtmfmode = rfc2833" >> sip_users.conf
echo "insecure = port, invite" >> sip_users.conf
echo "nat = auto_force_rport" >> sip_users.conf
echo "call-limit=2" >> sip_users.conf
echo ";nat = no" >> sip_users.conf
echo "qualify = yes" >> sip_users.conf
echo "context = "$context >> sip_users.conf
echo "disallow=all" >> sip_users.conf
echo "allow=g722" >> sip_users.conf
echo "allow=ulaw" >> sip_users.conf
echo "allow=alaw" >> sip_users.conf
echo "allow=g729" >> sip_users.conf
echo ";----------------------------" >> sip_users.conf 
echo ";----------------------------" >> sip_users.conf 
echo "  " >> sip_users.conf 

while [ $first -le $last ] 
 do 
 echo "["$first"]""("$group")" >> sip_users.conf 
 echo "username="$first >> sip_users.conf 
 echo "secret="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1) >> sip_users.conf 
 echo "callerid=\"$first"\" "<"$first">" >> sip_users.conf 
 echo "mailbox="$first"@"$context >> sip_users.conf 
 echo ";----------------------------" >> sip_users.conf 
 echo "  " >> sip_users.conf 


echo $first" => "$first", User "$first"," >> voicemail_users.conf 



 first=`expr $first + $step` 
 done 
  


echo ";---------EOF-----------------" >> sip_users.conf 
echo ";---------EOF-----------------" >> voicemail_users.conf 
echo "DONE" 

echo "Local Dialplan" >> extensions_local.conf 
echo ";----------------------------" >> extensions_local.conf 
echo "  " >> extensions_local.conf 
echo "exten => _"$exten",1,NoOp(Call from \${CALLERID(num)} to \${EXTEN})"  >> extensions_local.conf 
echo "exten => _"$exten",n,Set(TARGETNO=\${EXTEN})" >> extensions_local.conf 
echo "exten => _"$exten",n,MixMonitor(\${STRFTIME(\${EPOCH},,%Y/%m/%d/local/%H:%M:%S)}-\${CALLERID(num)}-\${EXTEN}-\${UNIQUEID}.wav)" >> extensions_local.conf 
echo "exten => _"$exten",n,Dial(SIP/\${EXTEN},40,Tt)" >> extensions_local.conf 
echo "exten => _"$exten",n,Goto(s-\${DIALSTATUS},1)" >> extensions_local.conf 
echo "exten => s-NOANSWER,1,VoiceMail(\${TARGETNO},u)" >> extensions_local.conf 
echo "exten => s-BUSY,1,VoiceMail(\${TARGETNO},b)" >> extensions_local.conf 
echo "exten => s-ANSWER,1,Hangup()" >> extensions_local.conf 
echo "exten => s-.,1,Goto(s-NOANSWER,1)" >> extensions_local.conf 
echo "exten => _"$exten",n,Hangup" >> extensions_local.conf 


echo ";----------------------------" >> extensions_local.conf 
echo "  " >> extensions_local.conf 

echo "DONE" 