#!/usr/bin/expect -f
set ip [lindex $argv 0]
set command [lindex $argv 1]

spawn ssh $ip $command

expect {
        -re "Are you sure you want to continue.*\? $" {
        exp_send "yes\n"
        exp_continue
}
"password:" {
        exp_send "castis\n"
        expect eof
}
}