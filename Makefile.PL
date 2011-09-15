use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'gmc4-as',
    VERSION_FROM => 'gmc4-as.pl',
    PREREQ_PM => {
	'warnings' => 0,
	'Getopt::Std' => 0,
	'lib' => 0,
	'strict' => 0,
	'Exporter' => 0,
    },
    AUTHOR => 'Jasper Lievisse Adriaanse <jasper@humppa.nl>',
    ABSTRACT => 'Simple non-optimizing assembler for GMC-4',
    PL_FILES =>
    {
	'gmc4-as.pl'
    },
);
