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

my $inp;
my @vocl1;
my @vocl2;
my $vocl1r;
my $vocl2r;
my @wrongList = (-1); # -1 or any other invalid (negative) number
my $ix;
my $vocFile;
my @order;
my @mode;
my $num = 0;

sub readnchomp # this subroutine reads and chomps at the same time via STDIN
{
	my $input = <STDIN>;
	chomp $input;
	return $input;
}

sub contains($@) # Returns 1 if the second paramter as array contains the first parameter (all strings), else it returns 0.
{
	my $elem = shift @_;
	my @list = @_;
	for my $i (0..scalar(@list)-1)
	{
		if ( lc($list[$i]) eq lc($elem) )
		{
			return 1;
			exit;
		}
	}
	return 0;
}



######## Begin of actual program

for my $i ( 1 .. ( scalar @ARGV - 1 ) )
{
	$ARGV[$i] = lc substr $ARGV[$i], 0, 1;
}

if ( not ( ( ( scalar @ARGV == 4 and ($ARGV[1] eq "t" ) ) or ( scalar @ARGV == 3 and ($ARGV[1] eq "d" ) ) ) or ( scalar @ARGV == 2 and $ARGV[1] eq "w" ) ))
{
	print "Wrong number of parameters! Please type all arguments correct again: >";
	$inp = readnchomp();
	@mode = split " ",$inp;	
	$ARGV[0] = shift @mode;
} else
{
	@mode = @ARGV[1, 2, 3];
}
if ( $mode[0] ne "w" ) # only read vocabulary from file if another mode than "[w]rite" is chosen
{
	open( $vocFile, $ARGV[0] ) or die "Couldn't read $ARGV[0]";

	while ( $inp = <$vocFile> )
	{
		chomp $inp;
		if ( $inp =~ m/^\s*([^=#]*[^=#\s])\s*=\s*([^=#]*[^=#\s]).*$/ )
		{
			( $vocl1[$num], $vocl2[$num] ) = ( lc($1),lc($2) );
			++$num;
		}
	}

	close $vocFile;
	print("\n$num correct records read and processed.\n");
}

if ( $mode[0] eq "t" )
{
	print "\nmode: vocabulary test\n";

	# generation of the @order array
	if ( $mode[2] eq "l" )
	{
		for my $i ( 0..( $num - 1 ) )
		{
			$order[$i] = $i;
		}

		print "order: linear\n";
	}
	elsif ( $mode[2] eq "r" )
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

		print "order: random\n";
	}

	if ( $mode[1] == 2 )
	{
		print "direction: l1 -> l2\n\n";
		$vocl1r = \@vocl1;
		$vocl2r = \@vocl2;
	}
	elsif ( $mode[1] == 1 )
	{
		print "direction: l2 -> l1\n\n";
		$vocl1r = \@vocl2;
		$vocl2r = \@vocl1;
	}


	for ( my $i = 0; $i < $num; ++$i ) # has to be this type of loop because of the backstep if an answer wasn't correct
	{
		$ix = $order[$i];
		print( ( $i+1 ) . "/$num (#$ix): $vocl1r->[$ix] ?  > " );
		$inp = readnchomp();
		if ( $inp eq "svtexit" )
		{
			die("Aborted on request!\n\n");
		}
		if ( contains(lc($inp),split("/",$vocl2r->[$ix]) ) )
		{
			print "Correct!\n";
		}
		else
		{
			print "Wrong! Correct was: $vocl2r->[$ix]\n";

			if ( ( $wrongList[0] != $ix ) )
			{
				unshift @wrongList, $ix;
			}
			--$i; # answer wasn't correct, so the user should enter it again
		}
	}

	pop @wrongList;

	my $correctNum = $num - scalar @wrongList;
	printf( "\nYou knew %i out of %i, which are %i percent.\n\n", $correctNum, $num, $correctNum / $num * 100 );

	while (scalar @wrongList > 0)
	{
		for ( my $i = scalar @wrongList - 1; $i >= 0; --$i )
		{
			$ix = $wrongList[$i];
			print "$vocl1r->[$ix] ?  > ";
			$inp = readnchomp();
			if ( contains(lc($inp),split("/",$vocl2r->[$ix]) ) )
			{
				print "Correct!\n";
				splice @wrongList, $i, 1;
			}
			else
			{
				print "Wrong! Correct was: $vocl2r->[$ix]\n";
			}
		}
	}
}
elsif ( $mode[0] eq "d" )
{
	print "\nmode: dictionary look-up (languages: $mode[1])\n\nEnter nothing to leave the program.";

	while ( 1 ) # loop is terminated with last
	{
		print "\n\nEnter a regular expression to search for: > ";
		$inp = readnchomp();
		last if ( $inp eq "" ); # exit loop if input was empty
		print "\nResults:\n";

		my $count = 0;

		if ( $mode[1] eq "b" or $mode[1] == 1)
		{
			for my $i ( 0..( scalar @vocl1  - 1 ) )
			{
				if ( $vocl1[$i] =~ m/.*$inp.*/ )
				{
					++$count;
					print "$vocl1[$i] = $vocl2[$i]\n";
				}
			}
		}
		if ( $mode[1] eq "b" or $mode[1] == 2)
		{
			for my $i ( 0..( scalar @vocl2 - 1 ) )
			{
				if ( $vocl2[$i] =~ m/.*$inp.*/ )
				{
					++$count;
					print "$vocl1[$i] = $vocl2[$i]\n";
				}
			}
		}
		print "\nFound $count matches\n";
	}
}

print "\n";

if ( $mode[0] eq "w" )
{
	print("Mode: Write\nTerminate this process and save the vocabulary by typing an empty line!\n");
	if ( not ( -e $ARGV[0] ) )
	{
		die("File to write in doesn't exist. Please create an (empty) file by typing 'echo > FILENAME'\n\n");
	}

	my @l1 = ("000");
	my @l2 = ("000");
	my $i = 0;
	my $j = 1;
	while ( $l1[$i-1] ne "" )
	{
		print("[w]rite mode: $j/l1  > ");
		$l1[$i] = readnchomp();

		if ( not ( ( $l1[$i] =~ m/^#.*/ ) or ( $l1[$i] eq "" ) ) )# if it isn't a comment and it isn't a terminate line (empty line), write a "=" at the end of line.
		{
			$l1[$i] .= "=";
		}

		if ( $l1[$i] =~ m/^#.*/ )#If it is a comment, write nothing in the related array element of @l2 (else there is an error around line 255)
		{

			$l2[$i] = "";

		}
		elsif ( ($l1[$i] ne "") and not( $l1[$i] =~ m/^#.*/ ) )#If it isn't a comment and it isn't an empty line (terminate line), ask second column/2. language
		{
			
			print("[w]rite mode: $j/l2  > ");
			$l2[$i] = readnchomp();

		}
		++$i;
		++$j;
	}
	$j = 0;
	$i -= 1; # else the last entry with "" is counted too
	
	print("$i records read!\n");
	open(my $writeFile,">",$ARGV[0]) or die("Open of $ARGV[0] not possible: $!");
	
	print($writeFile "### This file was created by SVocTrainer (c) 2010, 2011 Der Messer & LLynx");

	for $j (0..($i-1))
	{
		print($writeFile "$l1[$j]" . "$l2[$j]" . "\n");
	}
	
	close($writeFile) or die("File couldn't be closed!");
	print("Vocabulary written succesful into $ARGV[0]!\n\n");
}

