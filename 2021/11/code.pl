#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 11
# https://adventofcode.com/2021/day/11

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# 5483143223
# 2745854711
# 5264556173
# 6141336146
# 6357385478
# 4167524645
# 2176841721
# 6882881134
# 4846848554
# 5283751526
# /;
# @lines = grep { length $_ } split "\n", $lines;

my @rows;
my $init_rows = sub { @rows = (); push @rows, [ split '', $_ ] foreach @lines };
$init_rows->();

my $point_value = sub {
    my ( $x, $y, $v ) = @_;
    return if $x < 0 || $y < 0; # ugh, this would index the last value of the array
    return unless $rows[$y]; # ugh, this would auto-vivify an empty row

    $rows[$y]->[$x] = $v if defined $v;
    return $rows[$y]->[$x];  # going off the grid is merely undefined
};

my $keyval = sub { join '-', @_ };
my %has_flashed;

sub process_flash {
    my ( $x, $y ) = @_;

    # set the value of this point to 0 and keep track of its flash state
    $point_value->( $x, $y, 0 );
    $has_flashed{ $keyval->( $x, $y ) } = 1;

    # increase the energy level of all adjacent octopi by 1, including diagonally
    foreach my $i ( $x - 1, $x, $x + 1 ) {
        foreach my $j ( $y - 1, $y, $y + 1 ) {
            next if $has_flashed{ $keyval->( $i, $j ) };  # already flashed, no-op

            my $v = $point_value->( $i, $j );
            next unless defined $v;  # off the grid
            $point_value->( $i, $j, ++$v );
            process_flash( $i, $j ) if $v > 9;
        }
    }
}

my $on_every = sub {
    my ( $sub ) = @_;

    my $i_max = scalar @{ $rows[0] };
    my $j_max = scalar @rows;

    for ( my $i=0; $i < $i_max; $i++ ) {
        for ( my $j=0; $j < $j_max; $j++ ) {
            my $v = $point_value->( $i, $j );
            $sub->( $i, $j, $v );
        }
    }
};

my $num_flashes = 0;

my $do_step = sub {
    %has_flashed = ();

    # First, the energy level of each octopus increases by 1.
    $on_every->( sub { my ($i,$j,$v) = @_; $point_value->( $i, $j, ++$v ) } );

    # Then, any octopus with an energy level greater than 9 flashes.
    $on_every->( sub { my ($i,$j,$v) = @_; process_flash( $i, $j ) if $v > 9 } );

    $num_flashes += scalar keys %has_flashed;
};

$do_step->() foreach ( 1 .. 100 );

printf "Part 1: %s\n", $num_flashes;


$init_rows->();

my $total_count = scalar @{ $rows[0] } * scalar @rows;
my $step = 0;

while (1) {
    $do_step->($step++);
    last if scalar keys %has_flashed == $total_count;
}

printf "Part 2: %s\n", $step;
