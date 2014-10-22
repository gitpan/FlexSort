package File::FlexSort;

use 5.006;
use strict;
use warnings;
use IO::File;
use IO::Zlib;
use Carp;

require Exporter;
#use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PeopleLink::Sort ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.75';


# Preloaded methods go here.



# Create a new sort object
sub new {

	my $type = shift;
	my $class = ref($type) || $type;

	### ARGUMENTS
	my $files_ref = shift;		# ref to array of files.
	my $index_ref = shift;		# ref to sub that will extract index value from line
	my $comp_ref = shift;		# ref to sub used to compare index values
								#	currently this is not used.

	### CREATE SKELETON OBJECT  
	my $self = { 	
				index => $index_ref,
				comparison => $comp_ref,
				num_files => 0
	};



	### CREATE A RECORD FOR EACH FILE.
	my $n = 0;
	foreach my $file(@{$files_ref}) {

			
		if ( my $fh = &open_file($file) ) {

			$self->{files}->[$n]->{fh} = $fh;				# Store object.	
			$self->{num_files} = $self->{num_files} + 1;	 	# Increase Count of open files
			
			# Get line and index for each file.
			$self->{files}->[$n]->{line}  = &get_line($fh);	
			$self->{files}->[$n]->{index} = &get_index($self->{files}->[$n]->{line}, $self->{index});
			$n++;

		} else {
			carp "Error. Unable to open file, $file. Continuing anyway.\n";
		}

	}	
	
	### Now that the first records are complete for each file, SORT THEM.
	### Create a sorted arrays based on the index values of each file.
	### INITIAL SORT $self->{sorted}->hash

	my $array_ref = $self->{files};
	
	my %shash;
	$n = 0;
	foreach my $a_ref ( @{$self->{files}} ) {
		$shash{$n} = $a_ref->{index};
		$n++;
	}


	$n=0;
	foreach my $index ( sort { $shash{$a} <=> $shash{$b} } keys %shash ) {
		$self->{sorted}->[$n] = $self->{files}->[$index];
		$n++;
	}

	undef $self->{files};
	
	return bless $self, $class

}	# END SUB New() 



sub open_file {

	my $file = shift;
	my $fh;

	if ( $file =~ /\.(z|gz)$/ ) { 			# Files matching .z .gz or .zip
		$fh = IO::Zlib->new("$file", "rb");
	} else {
		$fh = new IO::File "< $file"
	}

	return undef if (!$fh);

	return $fh;

}		
		

sub get_line {
	
	my $fh = shift;
	my $line = <$fh>;

	if ($line) {
		$line =~ s/\015?\012/\n/;	# This is necessary to fix CRLF problem
		chomp $line;
		return $line;
	} else {
		$fh->close;
		return undef;
	}	

}


sub get_index {

	# Given a line of code and 
	# a reference to code that extracts 
	# a value from the line 'get_index' will return
	# an index value that can be used to compare the lines.

	my $line = shift;
	my $index_code_ref = shift;

	my $index = $index_code_ref->($line);
	
	if ($index) {
		return $index
	} else {
		carp "Unable to return an index.  Continuing anyways.\n";
		return 0
	}

}


sub next_line {

	### Main method.  This returns the next line from the stack.
	
	my $self = shift;

	my $line = $self->{sorted}->[0]->{line} || return undef;


	# print "extracting ...", $line, "\n";	# Debugging purposes.
	

	# Re-populate LOW VALUE, i.e. $self->{sorted}->[0]
	if ( my $newline = get_line($self->{sorted}->[0]->{fh}) ) {
		$self->{sorted}->[0]->{line} = $newline;
		$self->{sorted}->[0]->{index} = get_index( $newline, $self->{index} );
	} else {
		shift @{$self->{sorted}};
		$self->{num_files}--;
	}
	
	### 
	### One Pass Bubble Sort of $self->{sorted}
	### We only need to find the new positions in the stack for 
	### the new index of the file.
	### 

	return $line if ($self->{num_files} <= 1);	 # Abandone sorting with only one file left.


	my $i = 0;
	while ( $self->{sorted}->[$i]->{index} > $self->{sorted}->[$i+1]->{index} ) {
			
		# Swap elements
		my $place_holder = $self->{sorted}->[$i];
		$self->{sorted}->[$i] = $self->{sorted}->[$i+1];
		$self->{sorted}->[$i+1] = $place_holder;

		$i++;
		last if ($i > $self->{num_files} - 2);	# Condition so that 

	}

	return $line;

}


sub dump {
	
	# Dump the contents of the file to either STDOUT or FILE.
	# Default: <STDOUT>

	my $self = shift;
	my $file = shift;
	my $line;

	

	if ($file) {
		open( FILE, ">$file" );
		
		while ( $line = $self->next_line ) {
			print FILE "$line\n";
		}

		close FILE;
	
	} else {

		while ( $line = $self->next_line ) {
			print "$line\n";
		}
			
	}

}
	

	


# Autoload methods go after =cut, and are processed by the autosplit program.

1;






__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

File::FlexSort - Perl extension for merging and processing data 
distributed over ordered files.

=head1 SYNOPSIS

File::FlexSort provides an easy way to merge, parse, process and analyze data
that exists in many files with an existing order.  Because flex sort takes 
advantages of the existing order, the processing should be both quick and frugal
with memory resources.


  use File::FlexSort;
  
  my $sort = new File::FlexSort( 
                \@file_list,             # Anonymous array of path/files 
                \&index_extract_function 
  );


  my $line = $sort->next_line;  # Retrieves the next line for porcessing
  print "$line\n";

  $sort->dump( [file] ); 	# Dumps remaining records in sorted order
                          # to a file.            Default: <STDOUT>


=head1 DESCRIPTION

File::FlexSort is a hopefully straight forward solution for situations where one 
wishes to merge data files with all ready ordered records. An example might 
application server logs which record events chronilogically from a cluster.  If we 
want to examine, process or merge several files but retain the chronological order,
then flexsort is for you.

Here's how it works ...

As arguments, FlexSort takes a reference to an anonymous array of filepaths/names 
and a reference to a subroutine that extracts an index value.  The anonymous array
of the filenames are the files to be sorted with the subroutine determining the
sort order. When passed a line (i.e. a scalar) from one of the files, the user 
supplied subroutine must return a numeric index value associated with the line.  
The records are then culled in ascending based on the index values.  In the future, 
File::FlexSort will likely become more flexible to live up to it's name.

More detail ...

For each file FlexSort opens a IO::File or IO::Zlib object.  ( FS handles mixed 
compressed and uncompressed files seamlessly by detecting for files with .z or .gz 
extensions. )  Initially the first line is indexed acording to the subroutine.  A 
stack is created based on these values.  

When the function 'next_line' is called, FlexSort returns the line with the lowest 
index value.  FlexSort then replenishes the stack, reads a new line from the 
corresponding file and places it in the proper position for the next call to 
'next_line'.

Additional Notes: 
- A stable sort is implemented, i.e. a single file is read until its index is no longer the lowest value. 
- If the file ends in .z or .gz then the file is opened with IO::Zlib, instead.

 
=head1 EXAMPLE

   # This program does looks at files found 
   # in /logfiles, returns the records of the
   # files sorted by the date  in mm/dd/yyyy
   # format

  use File::Recurse;
  use File::FlexSort;

  recurse { push(@files, $_) } "/logfiles";

  my $fs = new File::FlexSort(\@files, \&index_sub);
	
  while (my $line = $fs->next_line) {
    .
	.	some operations on $line
	.
  }


  sub index_sub{

    # Use this to extract a date of
    # the form mm-dd-yyyy.
	 
    my $line = shift;

    # Be cautious that only the date will be
    # extracted. 
    $line =~ /(\d{2})-(\d{2})-(\d{4})/;
 
    return "$3$1$2";  # Index is an interger, yyyymmdd
                      # Lower number will be read first.

  }	
	

=head1 TODO

	Implement a generic test/comparison function to replace text/numeric comparison.
	Implement a configurable record seperator.
	Allow for optional deletion of duplicate entries.


=head1 EXPORT

None by default.


=head1 AUTHOR

Chris Brown, E<lt>chris.brown@cal.berkeley.edu<gt>

Copyright(c) 2002 Christopher Brown.  All rights reserved.  
This program is free software; you can redistribute it and/or modify it under 
the terms of the License, distributed with PERL.  Not intended for evil purposes.  
Yadda, yadda, yadda ...


=head1 SEE ALSO

L<perl>. L<IO::File>. L<IO::Zlib>.  L<Compress::Zlib>.

=cut
