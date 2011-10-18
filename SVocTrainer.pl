#!/usr/bin/perl

# Copyright 2010, 2011 by LLynx, dermesser

#    This file is part of SVocTrainer.
#
#    SVocTrainer is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    SVocTrainer is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with SVocTrainer.  If not, see <http://www.gnu.org/licenses/>.

use warnings;
use strict;

use Term::ReadLine;

my $correct = "!correct";
my $term = Term::ReadLine->new('SVocTrainer');
my $OUT = $term->OUT || \*STDOUT;
my $autohistory = exists $term->Features()->{'autohistory'};
my $inp;
my $ask_off;
my $ans_off;
my @wrongList = ( -1 ); # -1 or any other invalid (negative) number
my @vocs;
my $ix;
my $vocFile;
my @order;
my @mode;
my $num = 0;
my $numinfile = '';


sub readline_noaddhistory($)
{
	return $term->readline($_[0]);
}

sub readline_addhistory($)
{
	my $inp = $term->readline($_[0]);
	$term->addhistory($inp) if not $autohistory and $inp =~ m/\S/;
	return $inp;
}

sub contains( $@ ) ## returns 1 if the second parameter as array contains the first parameter (all strings), else it returns 0
{
	my $elem = shift @_;
	my @list = @_;
	for my $i (0 .. scalar @list - 1 )
	{
		if ( lc( $list[$i] ) eq lc( $elem ) )
		{
			return 1;
		}
	}
	return 0;
}

sub contains_num( $@ ) # same as contains(), but with numbers
{
	my $elem = shift @_;
	my @list = @_;
	for my $i ( 0..scalar @list - 1 )
	{
		if ( $list[$i] == $elem )
		{
			return 1;
		}
	}
	return 0;
}


######## Begin of actual program

for my $i ( 1 .. scalar @ARGV - 1 )
{
	$ARGV[$i] = lc substr $ARGV[$i], 0, 1;
}

my $l = scalar @ARGV; # $l is the number of given arguments
my $m = $ARGV[1]; # $ARGV[1] is the mode (t/w/d)

if ( not ( ( $l == 4 and $m eq 't' ) or ( $l == 3 and $m eq 'd' ) or ( $l == 2 and $m eq 'w' ) ) ) # If the number of arguments isn't correct (in relation to the chosen mode), ask again
{
	$inp = readline_noaddhistory("Wrong number of parameters! Please type all arguments correct again: > ");
	@mode = split ' ',$inp;
	$ARGV[0] = shift @mode;
} elsif ( $ARGV[1] eq 't' and $ARGV[3] eq 'b' ) # Training mode and bidirectionality isn't good.
{	
	$inp = readline_noaddhistory("Wrong number of parameters! Please type all arguments correct again: > ");
	@mode = split ' ',$inp;
	$ARGV[0] = shift @mode;
} else
{
	@mode = @ARGV[1, 2, 3];
}


if ( $mode[0] ne 'w' ) # only read vocabulary from file if another mode than "write" is chosen
{
	open( $vocFile, $ARGV[0] ) or die "Couldn't read $ARGV[0]";

	while ( $inp = <$vocFile> )
	{
		chomp $inp;
		if ( $inp =~ m/^\s*([^=#]*[^=#\s])\s*=\s*([^=#]*[^=#\s]).*$/ )
		{
#                                      l1 l2
			$vocs[$num] = [$1,$2];
			$num++;
		}
	}

	close $vocFile;
	print $OUT "\n$num correct records read and processed.\n";
}

if ( $mode[0] eq 't' )
{
	print $OUT "\nmode: vocabulary test\n";

	# generation of the @order array. This algorithm makes sure that the generation of the order is fast and secure
	if ( $mode[2] eq 'l' )
	{
		for my $i ( 0..( $num - 1 ) )
		{
			$order[$i] = $i;
		}

		print $OUT "order: linear\n";
	}
	elsif ( $mode[2] eq 'r' )
	{
		my @a;
		my $rand;

		for my $i ( 0..( $num - 1 ) )
		{
			$a[$i] = $i;
		}

		for my $i ( 0..( $num - 1 ) )
		{
			$rand = sprintf( "%u", rand scalar @a );
			$order[$i] = $a[$rand];
			splice( @a, $rand, 1 );
		}

		print $OUT "order: random\n";
	}

	if ( $mode[1] == 2 )
	{
		print $OUT "direction: l1 -> l2\n\n";
		($ask_off,$ans_off) = (0,1);
	}
	elsif ( $mode[1] == 1 )
	{
		print $OUT "direction: l2 -> l1\n\n";
		($ask_off,$ans_off) = (1,0);
	}


	for ( my $i = 0; $i < $num; ++$i ) # has to be this type of loop because of the backstep in case of a wrong answer
	{
		$ix = $order[$i];
		if ( $mode[2] eq 'r' )
		{
			$numinfile = '(#'. ($ix + 1) . ')';
		} 
		$inp = readline_addhistory( ( $i+1 ) . "/$num $numinfile: $vocs[$ix]->[$ask_off] ?  > " );

###### OPcodes exec.

		if ( $inp eq '!status' )
		{
			$i == 0 ? $i = 1 : 0; # necessary to avoid illegal division by zero in the next two lines
			printf($OUT "You gave " . ( (scalar @wrongList) - 1 ) . " wrong answers which are %d %%\n",( (scalar @wrongList - 1) / $i ) * 100);
			printf($OUT "You gave " . ( $i - ( (scalar @wrongList) - 1 ) ) . " correct answers which are %d %%\n",( ( $i - ( scalar @wrongList - 1 ) ) / $i ) * 100);
			print $OUT "You have to answer " . ( $num - $i ) . " words ($num words were read)\n\n";
			$inp = "!OPCODE_ASKED";# See some lines above. This value marks an answer not as 'wrong' which avoids the increment of the fail-counter
			--$i;# If !status was called, repeat the word
		}

##############################################

		if ( $inp eq '!edit' )
		{
			print $OUT "You chose edit mode. If you save the changed vocabulary, all comments will be lost! Press ^C to abort immediately.\nIf you type nothing, the word will be untouched.\n";

			$inp = readline_addhistory("Change: $vocs[$ix]->[$ask_off] ? > ");
			$vocs[$ix]->[$ask_off] = $inp if ( $inp ne '' );

			$inp = readline_addhistory("Change: $vocs[$ix]->[$ans_off] ? > ");
			$vocs[$ix]->[$ans_off] = $inp if ( $inp ne '' );

			open(my $writeFile,">","$ARGV[0]");

			print $writeFile "### This file was created by SVocTrainer (c) 2010, 2011 Der Messer & LLynx\n";

			for my $j ( 0..($num-1) )
			{
				print $writeFile "$vocs[$j]->[0]=$vocs[$j]->[1]\n";
			}

			close($writeFile);

			$inp = "!OPCODE_ASKED";
			$i--;
		}			

########################################

		if ( $inp eq '!exit' )
		{
			print $OUT "\nAborted on request!\n\n";
			exit;
		}


		if ( contains( lc( $inp ), split( '/', lc( $vocs[$ix]->[$ans_off] ) ) ) || $inp eq $correct)
		{
			print $OUT "Correct!\n\n";

###### /Opcodes
		} elsif ( $inp ne "!OPCODE_ASKED" ) 
		{
			print $OUT "Wrong! Correct was: $vocs[$ix]->[$ans_off]\n";

			if ( ( $wrongList[0] != $ix ) )
			{
				unshift @wrongList, $ix;
			}
			--$i; # answer wasn't correct, so the user should enter it again
		}
	}

	pop @wrongList;

	my $correctNum = $num - scalar @wrongList;
	printf($OUT "\nYou knew %i out of %i, which are %i percent.\n\n", $correctNum, $num, $correctNum / $num * 100);

	while (scalar @wrongList > 0)
	{
		for ( my $i = scalar @wrongList - 1; $i >= 0; --$i )
		{
			$ix = $wrongList[$i];
			$inp = readline_addhistory("$vocs[$ix]->[$ask_off] ?  > ");
			if ( contains( lc( $inp ), split( '/', lc( $vocs[$ix]->[$ans_off] ) ) ) )
			{
				print $OUT "Correct!\n";
				splice @wrongList, $i, 1;
			}
			else
			{
				print $OUT "Wrong! Correct was: $vocs[$ix]->[$ans_off]\n";
			}
		}
	}
}
elsif ( $mode[0] eq 'd' )
{
	print $OUT "\nmode: dictionary look-up (languages: $mode[1])\n\nEnter nothing to leave the program.";

	while ( 1 ) # loop is terminated with last
	{
		my @found;
		$inp = readline_addhistory("\n\nEnter a regular expression to search for: > ");
		last if ( $inp eq '' ); # exit loop if input was empty
		print $OUT "\nResults:\n";

		my $count = 0;

		if ( $mode[1] eq 'b' or $mode[1] == 1)
		{
			for my $i ( 0..( $num  - 1 ) )
			{
				if ( $vocs[$i]->[0] =~ m/$inp/ )
				{
					++$count;
					push @found,$i;
					print $OUT "$vocs[$i]->[0] = $vocs[$i]->[1]\n";
				}
			}
		}
		if ( $mode[1] eq 'b' or $mode[1] == 2)
		{
			for my $i ( 0..( $num - 1 ) )
			{
				if ( $vocs[$i]->[1] =~ m/$inp/ and not contains_num($i,@found) )
				{
					++$count;
					print $OUT "$vocs[$i]->[0] = $vocs[$i]->[1]\n";
				}
			}
		}
		print $OUT "\nFound $count matches\n";
	}
}

print $OUT "\n";

if ( $mode[0] eq 'w' )
{
	print $OUT "mode: write\nSave the vocabulary and quit SVT by typing an empty line!\n";
	if ( not ( -e $ARGV[0] ) )
	{
		print $OUT "File $ARGV[0] will be generated!\n\n";
	} else
	{
		print $OUT "Warning! Vocabulary will be concatenated to file $ARGV[0]! To abort immediately, press ^C!\n\n";
	}

	my @l1 = ( "000" );
	my @l2 = ( "000" );
	my $i = 0;
	my $j = 1;
	while ( $l1[$i-1] ne '' )
	{
		$l1[$i] = readline_addhistory(" $j/l1  > ");

		if ( not ( ( $l1[$i] =~ m/^#.*/ ) or ( $l1[$i] eq '' ) ) ) # if it isn't a comment and it isn't a terminate line (empty line), write a '=' at the end of line
		{
			$l1[$i] .= '=';
		}

		if ( $l1[$i] =~ m/^#.*/ ) # if it is a comment, write nothing in the related array element of @l2 
		{

			$l2[$i] = '';

		}
		elsif ( ($l1[$i] ne '') and not( $l1[$i] =~ m/^#.*/ ) ) # if it isn't a comment and it isn't an empty line (terminate line), ask second column/2. language
		{

			$l2[$i] = readline_addhistory(" $j/l2  > ");
			print $OUT "\n";

		}
		++$i;
		++$j;
	}
	$j = 0;
	$i -= 1; # else the last entry with '' is counted too

	print $OUT "\n$i records read!\n";
	open( my $writeFile, '>>', $ARGV[0]) or die("Open of $ARGV[0] not possible: $!");

	print $writeFile "### This file was created by SVocTrainer (c) 2010, 2011 Der Messer & LLynx\n";

	for $j (0..($i-1))
	{
		print $writeFile "$l1[$j]" . "$l2[$j]" . "\n";
	}

	close $writeFile;
	print $OUT "Vocabulary written succesful into $ARGV[0]!\n\n";
}

