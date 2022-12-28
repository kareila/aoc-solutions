#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 8
# https://adventofcode.com/2022/day/8

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = qq(
# 30373
# 25512
# 65332
# 33549
# 35390
# );
# @lines = grep { length $_ } split "\n", $lines;

my @rows;
my @cols;

foreach my $l (@lines) {
    push @rows, [ split '', $l ];
}

for ( my $i=0; $i < length $lines[0]; $i++ ) {
    push @cols, [ map { substr $_, $i, 1 } @lines ];
}

# For part 1, the question is how many trees on the grid can be seen from the outside.
# That means we need to track which trees we saw, not just how many along each line.

my $idx_visible = sub {
    my @a = @_;
    my @idx;
    my $h;

    for ( my $i=0; $i < scalar @a; $i++ ) {
        if ( ! defined $h || $a[$i] > $h ) {
            $h = $a[$i];
            push @idx, $i;
        }
    }
    return \@idx;   # list of index numbers of visible trees
};

my $check_edge = sub {
    my ( $data, $reverse ) = @_;
    my @result;

    foreach my $d (@$data) {
        my @a = $reverse ? reverse @$d : @$d;
        my $res = $idx_visible->( @a );
        $res = [ map { $#a - $_ } @$res ] if $reverse;  # counting backwards
        push @result, $res;
    }
    return \@result;
};

# to track the grid, use a 'rowval-colval' key format to keep things flat
my %seen;

my $map_set = sub {
    my ( $data, $keysub ) = @_;
    foreach my $rev ( qw( 0 1 ) ) {
        my $e = $check_edge->( $data, $rev );
        my $i = 0;
        foreach my $d (@$e) {
            $seen{ $keysub->( $i, $_ ) } = 1 foreach @$d;
            $i++;
        }
    }
};

$map_set->( \@rows, sub { sprintf "%s-%s", $_[0], $_[1] } );  # top to bottom
$map_set->( \@cols, sub { sprintf "%s-%s", $_[1], $_[0] } );  # left to right

# use Data::Dumper;
# warn Dumper [ sort keys %seen ];

printf "Part 1: %s\n", scalar keys %seen;


# For part 2, the question is how many trees can we see from the top of each tree.
# Ignore all the outer ones, since they will always have zero trees on one side.

my $tree_height = sub {
    my ( $x, $y ) = @_;
    return $cols[$x]->[$y];
};

my $score_tree = sub {
    my ( $x, $y ) = @_;

    my $max_x = scalar @cols - 1;
    my $max_y = scalar @rows - 1;

    return 0 if $x == 0 || $x == $max_x;
    return 0 if $y == 0 || $y == $max_y;

    # look up
    my $t_u = 0;
    for ( my $i = $y-1; $i >= 0; $i-- ) {
        $t_u++;
        last if $tree_height->( $x, $i ) >= $tree_height->( $x, $y );
    }

    # look down
    my $t_d = 0;
    for ( my $i = $y+1; $i <= $max_y; $i++ ) {
        $t_d++;
        last if $tree_height->( $x, $i ) >= $tree_height->( $x, $y );
    }

    # look left
    my $t_l = 0;
    for ( my $i = $x-1; $i >= 0; $i-- ) {
        $t_l++;
        last if $tree_height->( $i, $y ) >= $tree_height->( $x, $y );
    }

    # look right
    my $t_r = 0;
    for ( my $i = $x+1; $i <= $max_x; $i++ ) {
        $t_r++;
        last if $tree_height->( $i, $y ) >= $tree_height->( $x, $y );
    }

    return $t_u * $t_d * $t_l * $t_r;
};

my $highscore = 0;

for ( my $x=0; $x < scalar @cols; $x++ ) {
    for ( my $y=0; $y < scalar @rows; $y++ ) {
        my $s = $score_tree->( $x, $y );
        $highscore = $s if $s > $highscore;
    }
}

printf "Part 2: %s\n", $highscore;
