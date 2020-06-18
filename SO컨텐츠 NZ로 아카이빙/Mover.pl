#!/usr/bin/perl

use File::Copy;

$dst_dir = '/home/castis/20150312';
$watch_dir = '/home/castis/20150312/temp';
$watch_interval_sec = 3;



while(1){
	
	@list = <$watch_dir/*>;

	foreach $file ( @list ){
		print "$file is found\n";
		$size = (stat $file)[7];

		if ( not exists $hash{$file} ){
			$hash{$file}{before} = 0;
			$hash{$file}{now} = $size;
		}else{
			$hash{$file}{before} = $hash{$file}{now};
			$hash{$file}{now} = $size;
		}

	}

	foreach $file ( keys %hash ){

		print "$file before size  : $hash{$file}{before}\n";
		print "$file current size : $hash{$file}{now}\n";
		
		if ( $hash{$file}{before} == $hash{$file}{now} ){
			print "$file is complete file\n";
			$complete{$file} = 1;
			delete $hash{$file};
		}
	}

	foreach $file ( keys %complete ){
		print "$file move to $dst_dir\n";
		move $file, $dst_dir;
		delete $complete{$file};
	}

	sleep $watch_interval_sec;
}
