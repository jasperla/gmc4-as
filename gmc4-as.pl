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
use lib 'lib/';
use Getopt::Std;
use GMC4::Opcodes;
use vars qw($VERSION);

$VERSION = '0.1';

my %opt;
my %config = (
    no_address 	 => '0',
    per_nibble 	 => '0',
    include_code => '0',
    dry_run      => '0',
    version 	 => $VERSION,
    author       => 'Jasper Lievisse Adriaanse',
    contact      => 'jasper@humppa.nl',
    year         => '2011'
);

my $sourcefile;
my @source;		# The actual source (in memory) on which we operate.
my @instructions;	# The translated instructions, ready for the emitter.

sub parse_args
{
	getopts('achln', \%opt);

	# Do not print the leading addresses in the the ouput
	$config{no_address} = '1' if defined($opt{a});

	# Print the output one nibble per line, CALL\nSND\netc
	$config{per_nibble} = '1' if defined($opt{n});

	# Inlucde the original code as comments
	$config{include_code} = '1' if defined($opt{c});

	# Don't try to emit the instructions, just validate the input
	$config{dry_run} = '1' if defined($opt{n});

	usage() if (defined($opt{h}) or !defined($ARGV[0]));

	$sourcefile = $ARGV[0];
}

sub usage
{
	print STDERR << "EOF";
GMC4-assembler $config{version}
$config{author} <$config{contact}>, $config{year}
usage: $0 [-achn] sourcefile
    -a		: Do not print leading memory addresses
    -c		: Inlucde the original code as comments
    -h		: Show this (help) message
    -l		: Print one nibble per line
    -n		: Don\'t compile, just check the syntax.
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
			$mnemonic_valid = '1' if (defined($OPCODES_SINGLE{$m}));
			next if ($mnemonic_valid);

			# Then check for opcodes which need a memory operand
			$mnemonic_valid = '1' if (defined($OPCODES_MEM{$m}));
			next if ($mnemonic_valid);

			# Check for valid CAL operands
			$mnemonic_valid = '1' if (defined($OPCODES_CAL{$m}));
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

# We know that the code that got this far is good enough to be translated
# to machine instructions.
sub translator
{
	my (@source) = @_;
	# We build a new array based on @source, so we can later pass this
	# to emitter() in one go. Instead of calling emmitter() for every
	# translated line.
	my @instructions;

	foreach my $line (@source) {
		my @line = split(/ /, $line);
		foreach my $m (@line) {
			if (defined($OPCODES_SINGLE{$m})) {
				push(@instructions, $OPCODES_SINGLE{$m});
			} elsif (defined($OPCODES_MEM{$m})) {
				push(@instructions, $OPCODES_MEM{$m});
			} elsif (defined($OPCODES_CAL{$m})) {
				# We have CAL in %OPCODES_CAL, but we don't want
				# to emit 'E', so skip that, so silently eat it.
				if ($m ne "CAL") {
					push(@instructions, $OPCODES_CAL{$m});
				}
			} else {
				# It's just an address, so split it and add them
				# individually.
				my @address = split(//, $m);
				foreach (@address) {
					push(@instructions, $_);
				}
			}
		}
	}

	return @instructions;
}

# Depending on options passed to the script, format and emit the
# instructions.
sub emitter
{
	my (@instructions) = @_;

	if (!$config{no_address}){
		my $address = undef;
		my $line = "";
		my $arg_needed = '0';
		my $saved_instruction;

		printf("Address  Instruction\n" . "-" x 20 . "\n");

		foreach my $instruction (@instructions) {
			$line = "";
			if ($arg_needed) {
				$arg_needed = '0';
				$address += 2;
				$line = $saved_instruction . $instruction;
			} elsif (instruction_needs_arg($instruction)) {
			# If an argument is needed, set the flag, save the
			# instruction and process the next instruction.
				$arg_needed = '1';
				$saved_instruction = $instruction;
				next;
			} else {
				# Just increment the address and print the
				# instruction.
				if (!defined($address)) {
					$address = '0';
				} else {
					$address += 1;
				}
				$line = $instruction;
			}

			printf("0x%0x\t %s\n", $address, $line);
		}
	} else {
		printf("Instructions:\n" . "-" x 20 . "\n");
		foreach my $instruction (@instructions) {
			printf("%s\n", $instruction);
		}
	}
}

# Return true if an instruction needs an argument. This makes the emitter()
# a lot easier to write.
sub instruction_needs_arg
{
	my $instruction = shift;

	# We only need to look at %rOPCODES_MEM or for something that
	# translates to 'CAL'. XXX: This hardcodes CAL/E..
	my %rOPCODES_MEM = reverse %OPCODES_MEM;

	if (defined($rOPCODES_MEM{$instruction}) or $instruction eq 'E') {
		return 1;
	} else {
		return 0;
	}
}

parse_args();

@source = reader($sourcefile);

# If we did all we had to, just exit.
if (@source && $config{dry_run}){
	exit 0;
}

@instructions = translator(@source);

emitter(@instructions);
