#!/usr/bin/perl
#
# Copyright (c) 2011 Jasper Lievisse Adriaanse <jasper@humppa.nl>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Simple, non-optimizing, compiler for gmc4 assembler

use warnings;
use strict;
use lib;
use Getopt::Std;
use GMC4::Opcodes;

my %opt;
my %config = (
	noaddress 	=> '0',
	pernibble 	=> '0',
	includecode	=> '0',
	version 	=> '0.1'
);

sub parse_args
{
	getopts('achn', \%opt);

	# Do not print the leading addresses in the the ouput
	$config{noaddress} = '1' if defined($opt{a});

	# Print the output one nibble per line, CALL\nSND\netc
	$config{pernibble} = '1' if defined($opt{n});

	# Inlucde the original code as comments
	$config{includecode} = '1' if defined($opt{c});

	usage() if (defined($opt{h}));
}

sub usage
{
	print STDERR << "EOF";
GMC4-assembler $config{version}
Jasper Lievisse Adriaanse, 2011
usage: $0 [-achn] sourcefile
    -a		: Don't print leading memory addresses
    -c		: Inlucde the original code as comments
    -h		: Show this (help) message
    -n		: Print one nibble per line
EOF
	exit;
}

sub emitter
{
	my ($address, $instruction) = @_;

	if (!$config{noaddress}){
		printf("%02x = %s\n", $address, $instruction);
	} else {
		printf("%s\n", $instruction);
	}
}

parse_args();
