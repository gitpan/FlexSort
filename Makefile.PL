use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'File::FlexSort',
    'VERSION_FROM'	=> 'FlexSort.pm', # finds $VERSION
    'PREREQ_PM'		=> {IO::File => 1.08, IO::Zlib => 1.00}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'FlexSort.pm', # retrieve abstract from module
       AUTHOR     => 'Christopher Brown <Chris.Brown@alum.calberkeley.org>') : ()),
);
