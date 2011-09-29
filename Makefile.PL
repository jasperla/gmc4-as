use 5.008;
use ExtUtils::MakeMaker;

my @prog = ('gmc4-as.pl');

WriteMakefile(
    NAME => 'gmc4-as',
    VERSION_FROM => 'gmc4-as.pl',
    PREREQ_PM =>
    {
	'Exporter' => 0,
	'Getopt::Std' => 0,
	'lib' => 0,
	'strict' => 0,
	'warnings' => 0,
    },
    AUTHOR => 'Jasper Lievisse Adriaanse <jasper@humppa.nl>',
    ABSTRACT => 'Simple non-optimizing assembler for GMC-4',
    EXE_FILES => [ map "$_", @prog ],
);
