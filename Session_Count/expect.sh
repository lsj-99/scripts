#!/usr/bin/expect -f
set ip [lindex $argv 0]
set place [lindex $argv 1]

spawn ssh $ip lsof|grep VOD|grep mpg|grep /$place |cut -d / -f3 |sort|uniq -c|sort -n

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