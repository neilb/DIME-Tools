use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DIME::Tools',
    'VERSION_FROM'	=> 'lib/DIME/Tools.pm', # finds $VERSION
);
