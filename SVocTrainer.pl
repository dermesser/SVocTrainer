#!/usr/bin/perl

# Copyright 2010 LLynx, dermesser

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
my @wrongList = (-1); # -1 or any other invalid number
my $ix;

sub readnchomp        # this subroutine reads and chomps at the same time via STDIN
{
	my $input = <STDIN>;
	chomp($input);
	return $input;
}

print "\nPlease type \"mode language\", where \"mode\" is either \[t\]rainer or \[d\]ictionary and
\"language\" is either l1 or l2. (The parameter \"language\" is only needed in trainer mode and can be left out in dictionary mode.) > ";

$inp = readnchomp();
my @mode = split(" ",$inp);

my $num = 0;
while ($inp = <>)
{
	chomp($inp);
	if (not (($inp =~ m/#.*/) or ($inp =~ m/^$/)))
	{
		( $vocl1[$num], $vocl2[$num] ) = split( "=",$inp);
		++$num;
	}
}

print("\n$num correct records processed.");

if (($mode[0] eq "t" or $mode[0] eq "trainer") and ($mode[1] eq "l2" or $mode[1] eq "2"))
{
	print "\ndirection: l1 -> l2\n\n";
	$vocl1r = \@vocl1;
	$vocl2r = \@vocl2;
}
elsif (($mode[0] eq "t" or $mode[0] eq "trainer") and ($mode[1] eq "l1" or $mode[1] eq "1"))
{
	print "\ndirection: l2 -> l1\n\n";
	$vocl1r = \@vocl2;
	$vocl2r = \@vocl1;
}

if ($mode[0] eq "trainer" or $mode[0] eq "t" )
{
	print "\nmode: vocabulary test\n";

	for (my $i = 0; $i < $num; ++$i) # has to be this type of loop because of the backstep if an answer wasn't correct
	{
		print(($i+1) . "/$num: $vocl1r->[$i] ?  > ");
		$inp = readnchomp();
		if ( lc($inp) eq lc($vocl2r->[$i]) )
		{
			print "Correct!\n";
		}
		else
		{
			print "Wrong! Correct was: $vocl2r->[$i]\n";
			if (not ($wrongList[0] == $i))
			{
				unshift @wrongList, $i;
			}
			--$i;
		}
	}

	print "\nYou knew " . ($num - (scalar @wrongList) + 1) . " out of " . ($num) . "\n\n";

	while (scalar @wrongList > 1)
	{
		for (my $i = (scalar @wrongList) - 2; $i >= 0; --$i)
		{
			$ix = $wrongList[$i];
			print "$vocl1r->[$ix] ?  > ";
			$inp = <STDIN>;
			chomp $inp;
			if ( lc($inp) eq lc($vocl2r->[$ix]) )
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
elsif ($mode[0] eq "dictionary" or $mode[0] eq "d" )
{
	print "\nmode: dictionary look-up\nEnter nothing to leave the program." ;

	while (1) # loop is terminated with last
	{
		print "\nEnter a regular expression to search for: > ";
		$inp = readnchomp();
		last if ($inp eq ""); # exit loop if input was empty
		print "\nResults:\n";

		my $count = 0;
		for my $i (0..(scalar(@vocl1) - 1))
		{
			if ($vocl1[$i] =~ m/.*$inp.*/ )
			{
				++$count;
				print "$vocl1[$i] = $vocl2[$i]\n";
			}
		}
		for my $i (0..(scalar(@vocl2) - 1))
		{
			if ($vocl2[$i] =~ m/.*$inp.*/ )
			{
				++$count;
				print "$vocl2[$i] = $vocl1[$i]\n";
			}
		}
		print "\nFound $count matches\n";
	}
}

print "\n";

