#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 18
# https://adventofcode.com/2022/day/18

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# 2,2,2
# 1,2,2
# 3,2,2
# 2,1,2
# 2,3,2
# 2,2,1
# 2,2,3
# 2,2,4
# 2,2,6
# 1,2,5
# 3,2,5
# 2,1,5
# 2,3,5
# );
# @lines = grep { length $_ } split "\n", $lines;

my @grid;

my $set_value = sub {
    my ( $x, $y, $z ) = @_;
    return if $x < 0 || $y < 0 || $z < 0;  # ugh, this would index the last value of the array
    $grid[$x]->[$y]->[$z] = 1;  # boolean
};

my $point_value = sub {
    my ( $x, $y, $z ) = @_;
    return 0 if $x < 0 || $y < 0 || $z < 0;  # ugh, this would index the last value of the array
    return 0 unless $grid[$x];           # ugh, this would auto-vivify an empty row
    return 0 unless $grid[$x]->[$y];     # ugh, this would auto-vivify an empty row
    return $grid[$x]->[$y]->[$z] ? 1 : 0;  # boolean
};

# populate @grid
foreach (@lines) {
    my ( $x, $y, $z ) = split /,/;
    $set_value->( $x, $y, $z );
}

# check each value's six neighbors for exposed faces
my $count = 0;
foreach (@lines) {
    my ( $x, $y, $z ) = split /,/;
    $count++ unless $point_value->( $x - 1, $y - 0, $z - 0 );
    $count++ unless $point_value->( $x + 1, $y + 0, $z + 0 );
    $count++ unless $point_value->( $x - 0, $y - 1, $z - 0 );
    $count++ unless $point_value->( $x + 0, $y + 1, $z + 0 );
    $count++ unless $point_value->( $x - 0, $y - 0, $z - 1 );
    $count++ unless $point_value->( $x + 0, $y + 0, $z + 1 );
}

printf "Part 1: %s\n", $count;


# calculate upper and lower bounds in all dimensions
# I thought I could assume 1's for minimums here, but I was wrong...
my ( $min_x, $min_y, $min_z, $max_x, $max_y, $max_z );

foreach (@lines) {
    my ( $x, $y, $z ) = split /,/;
    $min_x = $x unless defined $min_x && $x > $min_x;
    $min_y = $y unless defined $min_y && $y > $min_y;
    $min_z = $z unless defined $min_z && $z > $min_z;
    $max_x = $x unless defined $max_x && $x < $max_x;
    $max_y = $y unless defined $max_y && $y < $max_y;
    $max_z = $z unless defined $max_z && $z < $max_z;
}

$count = 0;

my %visited;
my $was_visited = sub { $visited{ join ',', @_  } };
my $set_visited = sub { $visited{ join ',', @_  } = 1 };

# start searching at max and go down in all directions until you hit a dead end
# (add one to get past the edge of the surface)
search( $max_x + 1, $max_y + 1, $max_z + 1 );

sub search {
    no warnings 'recursion';  # hush
    my ( $x, $y, $z ) = @_;
    return if $x < $min_x - 1 || $x > $max_x + 1;
    return if $y < $min_y - 1 || $y > $max_y + 1;
    return if $z < $min_z - 1 || $z > $max_z + 1;
    return if $was_visited->( $x, $y, $z );  # already been here
    $set_visited->( $x, $y, $z );

    my @faces = ( [ $x - 1, $y - 0, $z - 0 ], [ $x + 1, $y + 0, $z + 0 ],
                  [ $x - 0, $y - 1, $z - 0 ], [ $x + 0, $y + 1, $z + 0 ],
                  [ $x - 0, $y - 0, $z - 1 ], [ $x + 0, $y + 0, $z + 1 ] );

    foreach my $f ( @faces ) {
        if ( $point_value->( @$f ) ) {
            # we found a surface!
            $count++;
        } else {
            search( @$f );
        }
    }
}

printf "Part 2: %s\n", $count;
