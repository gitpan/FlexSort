# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use IO::File;
ok(2);
use IO::Zlib;
ok(3);
use File::FlexSort;
ok(4);

my @files = ('file1.txt', 'file2.txt', 'file4.txt', 'file3.txt.gz', 'file5.txt.gz'); #  

my $sort = new File::FlexSort(\@files, \&index);

my $n = 0;
while (my $line = $sort->next_line) {
	# print "$line \n";
	$n++;
}


sub index {
	my $line = shift;
	# print "index .. $line";
	my @fields = split(/\t/, $line);
	return $fields[1];
}


ok($n, 36);
