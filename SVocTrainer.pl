#!/usr/bin/perl

# Copyright 2010 LLynx, Der Messer

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
use Switch;

my $inp;
my @vocl1;
my @vocl2;
my $vocl1r;
my $vocl2r;
my @wrongList = (-1); # -1 or any other invalid number
my $ix;

print "\nPlease insert \"trainer l1\" for a test of l1 or \"trainer l2\" for a test of l2 to the first line of your database. 
Or input \"dic l1\" for a dictionary look-up of l1 or \"dic l2\" for a look-up of l2: > ";

$inp = <STDIN>;
chomp $inp;
my @mode = split(" ",$inp);

my $num = 0;
while ($inp = <>)
{
	chomp $inp;
	if (not ($inp =~ m/#.*/))
	{
		( $vocl1[$num], $vocl2[$num] ) = split( "=",$inp);
		++$num;
	}
}

print("\n$num correct records processed.");

switch($mode[1])
{
	case "l2"
	{
		print "\ndirection: l1 -> l2\n\n";
		$vocl1r = \@vocl1;
		$vocl2r = \@vocl2;
	}
	case "l1"
	{
		print "\ndirection: l2 -> l1\n\n";
		$vocl1r = \@vocl2;
		$vocl2r = \@vocl1;
	}
}

switch($mode[0])
{
	case "trainer" 
	{
		print "\nmode: vocabulary test\n";
		
		for (my $i = 0; $i < $num; ++$i) # has to be this type of loop because of the backsteps
		{
			print(($i+1) . "/$num: $vocl1r->[$i] ?  > ");
			$inp = <STDIN>;
			chomp $inp;
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
	case "dic"
	{
		print "\nmode: dictionary look-up\nEnter !exit to leave the program." ;

		$inp = "foo";
		while ($inp ne "!exit")
		{
			print "\nEnter a regular expression to search for: > ";
			$inp = <STDIN>;
			chomp $inp;

			print "\nResults:\n";

			my $count = 0;
			for my $i (0..(scalar(@$vocl2r) - 1))
			{
				if ($vocl2r->[$i] =~ m/.*$inp.*/)
				{
					++$count;
					print "$vocl1[$i] = $vocl2[$i]\n";
				}
			}

			print "\nFound $count matches\n";
		}
	}
}
print "\n";
