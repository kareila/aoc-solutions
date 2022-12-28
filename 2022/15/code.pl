#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 15
# https://adventofcode.com/2022/day/15

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# Sensor at x=2, y=18: closest beacon is at x=-2, y=15
# Sensor at x=9, y=16: closest beacon is at x=10, y=16
# Sensor at x=13, y=2: closest beacon is at x=15, y=3
# Sensor at x=12, y=14: closest beacon is at x=10, y=16
# Sensor at x=10, y=20: closest beacon is at x=10, y=16
# Sensor at x=14, y=17: closest beacon is at x=10, y=16
# Sensor at x=8, y=7: closest beacon is at x=2, y=10
# Sensor at x=2, y=0: closest beacon is at x=2, y=10
# Sensor at x=0, y=11: closest beacon is at x=2, y=10
# Sensor at x=20, y=14: closest beacon is at x=25, y=17
# Sensor at x=17, y=20: closest beacon is at x=21, y=22
# Sensor at x=16, y=7: closest beacon is at x=15, y=3
# Sensor at x=14, y=3: closest beacon is at x=15, y=3
# Sensor at x=20, y=1: closest beacon is at x=15, y=3
# );
# @lines = grep { length $_ } split "\n", $lines;

my $rownum = 2000000;
# $rownum = 10;  # for example data

my $limit = 4000000;  # for Part 2
# $limit = 20;  # for example data

# At first this looks like another grid mapping problem, but (a) the
# areas are potentially huge (cf. "the row where y=2000000"), and (b)
# x/y values are allowed to be negative, but array indices aren't.
#
# Instead, let's consider a set of subroutines, where each subroutine,
# given a y, will return a range of x values covered at that y by one sensor.

my $m_dist = sub {
    my ( $x1, $y1, $x2, $y2 ) = @_;

    # calculate the Manhattan distance for any two points
    return abs( $x1 - $x2 ) + abs( $y1 - $y2 );
};

my $find_x = sub {
    my ( $x1, $y1, $d, $y2 ) = @_;

    # $d = abs( $x1 - $x2 ) + abs( $y1 - $y2 );
    my $x_diff = $d - abs( $y1 - $y2 );
    return if $x_diff < 0;  # not in range
    return ( $x1, $x1 ) if $x_diff == 0;  # no change in x

    # save ourselves some grief by putting the smaller number first
    return sort { $a <=> $b } ( $x1 + $x_diff, $x1 - $x_diff );
};

my $sub_sensor = sub {
    my ( $x, $y, $x2, $y2 ) = @_;
    my $dist = $m_dist->(@_);

    return sub { $find_x->( $x, $y, $dist, $_[0] ) };
};

my @sensors;
my %beacons;

foreach my $l ( @lines ) {
    next unless $l;
    my ( $x1, $y1 ) = ( $l =~ / x=([-]?\d+), y=([-]?\d+):/ );
    my ( $x2, $y2 ) = ( $l =~ / x=([-]?\d+), y=([-]?\d+)$/ );
    push @sensors, [ $y1, $sub_sensor->( $x1, $y1, $x2, $y2 ) ];

    # we also need to track known beacon positions (x2,y2) for Part 1 at least
    $beacons{$y2}->{$x2} = 1;
}

# optimize performance ordering for @sensors - saves about 1.5 sec overall
@sensors = map { $_->[1] } sort { $a->[0] <=> $b->[0] } @sensors;

my $result;
my @coverage;

my $check_coverage = sub {
    my ( $y ) = @_;
    my $count = 0;
    while ( @coverage ) {
        my ( $x1, $x2 ) = splice @coverage, 0, 2;
#         foreach my $x ( $x1 .. $x2 ) {
#             next if $beacons{$y}->{$x};
#             $count++;
#         }
# Never mind that, this way is INSANELY faster:
        $count += $x2 - $x1 + 1;
        foreach my $b ( keys %{ $beacons{$y} } ) {
            next if $b < $x1 || $b > $x2;
            $count--;  # don't count covered positions that DO contain a beacon
        }
    }
    return $count;
};

my $do_search = sub {
    my ( $j ) = @_;
    @coverage = ();

    foreach my $s ( @sensors ) {
        my @x = $s->($j);

        next unless @x;  # this will have two elements if it's defined at all

        if ( @coverage ) {
            # insert @x in such a way that odd elements stay sorted
            for ( my $i=0; $i < $#coverage; $i += 2 ) {
                my @v = @coverage[ $i .. $i + 1 ];
                next if $x[0] > $v[0];
                splice @coverage, $i, 2, @x, @v;
                @x = ();
                last;
            }
        }
        push @coverage, @x if @x;
    }

    # @coverage is a list of ordered segments, needs to be condensed
    for ( my $i=1; $i < $#coverage; $i += 2 ) {
        next if $coverage[ $i + 1 ] - $coverage[$i] > 1;  # has a gap!
        my $s = ( $coverage[$i] > $coverage[ $i + 2 ] ) ? $i + 1 : $i;
        splice @coverage, $s, 2;
        $i -= 2;  # because we spliced without stopping
    }

    # now @coverage is condensed, do something with it
    return $check_coverage->($j);
};

$result = $do_search->( $rownum );

printf "Part 1: %s\n", $result;


$check_coverage = sub {
    my ( $y ) = @_;
    return if scalar @coverage == 2;  # no gaps

    # find the gap
    my $x = $coverage[1] + 1;
    return 4000000 * $x + $y;
};

# slight timing cheat - answer seems to be on the higher end of j, so run backwards
# n.b. still takes about 15-20 seconds to run on my system
for ( my $j = $limit; $j >= 0; $j-- ) {
    $result = $do_search->($j);
    last if defined $result;
}

printf "Part 2: %s\n", $result;
