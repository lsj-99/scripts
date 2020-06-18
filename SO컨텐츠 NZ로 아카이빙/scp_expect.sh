#!/usr/bin/expect -f
set list [lindex $argv 0]
set ip [lindex $argv 1]
spawn scp /home/castis/20150312/$list $ip:/home/castis/temp
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
interact