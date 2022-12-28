#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 13
# https://adventofcode.com/2022/day/13

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# [1,1,3,1,1]
# [1,1,5,1,1]
#
# [[1],[2,3,4]]
# [[1],4]
#
# [9]
# [[8,7,6]]
#
# [[4,4],4,4]
# [[4,4],4,4,4]
#
# [7,7,7,7]
# [7,7,7]
#
# []
# [3]
#
# [[[]]]
# [[]]
#
# [1,[2,[3,[4,[5,6,7]]]],8,9]
# [1,[2,[3,[4,[5,6,0]]]],8,9]
# );
# @lines = split "\n", $lines;

my $parse_line = sub {
    my @elements = split ',', $_[0];
    my @p = [];  # top level

    foreach ( @elements ) {
        my @c = split '';

        while ( $c[0] eq '[' ) {
            shift @c;
            push @p, [];  # add another level
        }

        # numeric string accumulator
        my $n = '';

        while ( @c && $c[0] ne ']' ) {
            $n .= shift @c;
        }

        # did we find a number value?
        push @{ $p[-1] }, $n if length $n;

        # anything left must be closing brackets
        while ( @c ) {
            shift @c;
            my $d = pop @p;         # close the current level...
            push @{ $p[-1] }, $d;   # ...and add it to the parent level
        }
    }
    return @{ $p[0] };  # ta-da!
};

my @pairs;

foreach my $l ( @lines ) {
    next unless $l;

    if ( ! @pairs || scalar @{ $pairs[-1] } == 2 ) {
        push @pairs, [];
    }

    push @{ $pairs[-1] }, $parse_line->($l);
}

sub check_pair {
    my ( $pl, $pr ) = @_;
    # break references to avoid modifying the inputs
    my @pl = @$pl;
    my @pr = @$pr;

    while (1) {
        # did either or both run out of items?
        return if @pl == 0 && @pr == 0;
        return 1 if @pl == 0;
        return 0 if @pr == 0;

        my ( $left, $right ) = ( shift @pl, shift @pr );

        # If both values are integers...
        if ( ! ref $left && ! ref $right ) {
            return 1 if $left < $right;
            return 0 if $left > $right;
            next;
        }

        # If both values are lists...
        if ( ref $left && ref $right ) {
            my $result = check_pair( $left, $right );
            return $result if defined $result;
            next;
        }

        # If exactly one value is an integer... which one is it?
        if ( ref $left ) {
            my $result = check_pair( $left, [$right] );
            return $result if defined $result;
        } else {
            my $result = check_pair( [$left], $right );
            return $result if defined $result;
        }
    }
    # returns 1 for right order, 0 for wrong order, undef for identical
}

my $total = 0;
my $i = 1;

foreach my $p ( @pairs ) {
    $total += $i if check_pair(@$p);
    $i++;
}

printf "Part 1: %s\n", $total;


my @all;

foreach my $l ( @lines ) {
    push @all, $parse_line->($l) if $l;
}

my @dividers = ( $parse_line->('[[2]]'), $parse_line->('[[6]]') );
my @sorted = @dividers;

# Take every data element and test it against every element of the sorted list
# from smallest to largest. When the test passes, it is in the right place.

foreach my $p ( @all ) {
    my $found = 0;
    for ( my $i=0; $i <= $#sorted; $i++ ) {
        my @q = ( $p, $sorted[$i] );
        next unless check_pair(@q);
        # if these are in the "right" order, do the list insertion here
        $found = 1;
        splice @sorted, $i, 1, @q;
        last;
    }
    # if not inserted, add it to the end of the list
    push @sorted, $p unless $found;
}

# Now search the sorted list for the locations of the divider packets.
my @idx_div;

foreach my $d ( @dividers ) {
    for ( my $i=0; $i <= $#sorted; $i++ ) {
        unless ( defined check_pair( $d, $sorted[$i] ) ) {
            push @idx_div, $i + 1;  # remember to count from 1, not 0
            last;
        }
    }
}

printf "Part 2: %s\n", $idx_div[0] * $idx_div[1];
