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

use warnings;
use strict;

package GMC4::Opcodes;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	%OPCODES_SINGLE
	%OPCODES_MEM
	%OPCODES_CAL
);

# Lookup table for matching mnemonics to instructions
our %OPCODES_SINGLE = (
	'KA' => '0',
	'AO' => '1',
	'CH' => '2',
	'CY' => '3',
	'AM' => '4',
	'MA' => '5',
	'M+' => '6',
	'M-' => '7',
);

# Lookup table for matching an opcode that needs an address operand,
# or two in case of JUMP
our %OPCODES_MEM = (
	'TIA' => '8',
	'AIA' => '9',
	'TIY' => 'A',
	'AIY' => 'B',
	'CIA' => 'C',
	'CIY' => 'D',
	'JUMP' => 'F',
);

# Operands in this table are used with CAL, we add CAL itself here too
# so it can also be checked for valid spelling (not CALL!)
our %OPCODES_CAL = (
	'CAL'  => 'E',
	'RSTO' => 'E0',
	'SETR' => 'E1',
	'RSTR' => 'E2',
	'CMPL' => 'E4',
	'CHNG' => 'E5',
	'SIFT' => 'E6',
	'ENDS' => 'E7',
	'ERRS' => 'E8',
	'SHTS' => 'E9',
	'LONS' => 'EA',
	'SUND' => 'EB',
	'TIMR' => 'EC',
	'DSPR' => 'ED',
	'DEM-' => 'EE',
	'DEM+' => 'EF',
);

1;
