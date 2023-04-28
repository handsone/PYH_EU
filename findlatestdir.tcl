#!/bin/expect
#

set var1 [lindex $argv 0]
#set var2 [lindex $argv 0]
#puts $var1
#puts $var2

set timeout 120
spawn sftp INT_FHGW@cdsftp.arraycomm.com  
expect {
"yes/no" { send "yes\r"; exp_continue}
"password:" { send "BGygAgRdaztC\r" }
}


expect { 
"sftp>" 
{
    send "ls  -lt $var1 \r";
}
}

expect {
"sftp>"
{
send "exit \r"
}
}
expect eof

