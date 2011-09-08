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
#
# TODO: - Do not strip empty lines before checking the syntax, this makes
#         error reporting harder as we do not know the offending line.
#       - CAL SND: Illegal address: SND

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

my $sourcefile;
my @source;	# The actual source on which we operate.

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

	$sourcefile = $ARGV[0];
}

sub usage
{
	print STDERR << "EOF";
GMC4-assembler $config{version}
Jasper Lievisse Adriaanse, 2011
usage: $0 [-achn] sourcefile
    -a		: Do not print leading memory addresses
    -c		: Inlucde the original code as comments
    -h		: Show this (help) message
    -n		: Print one nibble per line
EOF
	exit;
}

# Read the file into memory and massage it a bit so it can be used
# for further actions.
sub reader
{
	my ($source) = @_;

	open(FH, '<', $source) or die "Could not open $source for reading.";
	@source = <FH>;
	close(FH);

	# First pass: remove comments and remove trailing spaces
	@source = strip_comments(@source);

	# Second pass: rudimentary syntax validation
	check_syntax(@source);

	return @source;
}

# Strip comments and remove empty lines.
sub strip_comments
{
	my (@source) = @_;
	my @new_source;

	foreach my $line (@source) {
		# Remove comments
		$line =~ s/\;.*//g;
		# Remove leading whitespace...
		$line =~ s/^\s+//;
		# ...remove trailing whitespace
		$line =~ s/\s+$//;
		if (!($line =~ /^$/)){
			push(@new_source, $line);
		}
	}

	return @new_source;
}

sub check_syntax
{
	my (@source) = @_;
	my ($err_msg,$mnemonic, $operand_needed, $prev_mnemonic);

	foreach my $line (@source) {
		my @line = split(/ /, $line);
		# No more than two instructions per line
		if (@line > 2) {
			$err_msg = sprintf("Line too long: %s", $line);
			goto err;
		}

		# Check for illegal instructions, skip to the end if we
		# found a mnemonic.
		foreach my $m (@line) {
			my $mnemonic_valid = '0';

			chomp($m);

			# First check the normal opcodes
			if (defined($OPCODES_SINGLE{$m})) {
				$mnemonic_valid = '1' 
			}
			next if ($mnemonic_valid);

			# Then check for opcodes which need a memory operand
			if (defined($OPCODES_MEM{$m})) {
				$mnemonic_valid = '1';
			}
			next if ($mnemonic_valid);

			# Check for valid CAL operands
			if (defined($OPCODES_CAL{$m})) {
				$mnemonic_valid = '1';
			}
			next if ($mnemonic_valid);

			# Everything that got here is either an address,
			# or an invalid mnemonic. All the valid two letter
			# mnemonics have already been recognized (and based on
			# the composition will not pass as valid addresses, thus
			# anything longer than 2 characters must be address,
			# or it is invalid.

			# Finally check for valid addresses
			if ($m =~ m/(^(A|B|C|D|E|F)$){1,2}|^([0-8]{1,2})$/){
				$mnemonic_valid = '1';
			} else {
				$err_msg = sprintf("Illegal address: %s", $m);
				goto err;			
			}

			if ($mnemonic_valid < 1){
				$err_msg = sprintf("Illegal mnemonic: %s", $m);
				goto err;
			}
		}

		# Certain opcodes require an argument, or rather, only
		# opcodes from OPCODES_SINGLE do not require an argument.
		foreach my $m (@line) {
			# By now we know that all opcodes encountered are valid
			# so if it is not in OPCODES_SINGLE it is in one of the
			# others and we know it needs an argument, or it is
			# an address.
			next if (defined($OPCODES_SINGLE{$m}));

			# Check if flag is set, if so, check if $m is
			# a valid member of %OPERANDS_CAL (minus CAL),
			# or of it is a valid address. If not, bail out.
			if ($operand_needed) {
				if (defined($OPCODES_CAL{$m}) or
				    $m =~ m/(^(A|B|C|D|E|F)$){1,2}|^([0-8]{1,2})$/){
					;
				} else {
					$err_msg = sprintf("Missing operand for: %s",
					    $prev_mnemonic);
					goto err;
				}

				# Now clear the flag and continue.
				$operand_needed = '0';
			} else {
				$operand_needed = '1';
			}

			# Save the previous mnemonic in case there is no operand
			# so we can prepare a better error message.
			$prev_mnemonic = $m;
		}
	}

	return;

err:
	print($err_msg . "\n");
	exit 1;
}

# Depending on options passed to the script, format and emit the
# instructions.
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

@source = reader($sourcefile);

