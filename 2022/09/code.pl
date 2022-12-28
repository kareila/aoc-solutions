#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 9
# https://adventofcode.com/2022/day/9

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = qq(
# R 4
# U 4
# L 3
# D 1
# R 4
# D 1
# L 5
# R 2
# );
# my $lines = qq(
# R 5
# U 8
# L 8
# D 3
# R 17
# D 10
# L 25
# U 20
# );
# @lines = grep { length $_ } split "\n", $lines;

my $move = sub {
    my ( $point, $dir ) = @_;
    my $moves = { L => [ -1, 0 ], R => [ 1, 0 ], D => [ 0, -1 ], U => [ 0, 1 ] };

    $point->{'x'} += $moves->{$dir}->[0];
    $point->{'y'} += $moves->{$dir}->[1];
};

my @snake;   # list of points from head to tail

my $init_snake = sub {
    my ( $num ) = @_;     # number of points in the snake
    @snake = ();  # reset
    push @snake, { qw( x 0 y 0 ) } foreach ( 1 .. $num );
};

my %visited;
my $init_visited = sub { %visited = ( '0-0' => 1 ) };

my $mark_visited = sub {
    my $tail = $snake[-1];   # we only track the position of the tail
    $visited{ sprintf "%s-%s", $tail->{'x'}, $tail->{'y'} } = 1;
};

my $update = sub {
    my ( $dir, $i ) = @_;
    $i //= 1;

    my $head = $snake[$i - 1];  # relative to current segment
    my $tail = $snake[$i - 0];  # current segment

    $move->( $head, $dir ) if $i == 1;   # the head moves, all other segments just react

    # any valid move ends in 'x' or 'y' (but not both) being no more than 2 away

    if ( $head->{'y'} - 2 == $tail->{'y'} ) {
        # move up one and left or right as needed
        $move->( $tail, 'U' );
        $move->( $tail, 'L' ) if $tail->{'x'} > $head->{'x'};
        $move->( $tail, 'R' ) if $tail->{'x'} < $head->{'x'};
        $mark_visited->();
        return;
    }

    if ( $head->{'y'} + 2 == $tail->{'y'} ) {
        # move down one and left or right as needed
        $move->( $tail, 'D' );
        $move->( $tail, 'L' ) if $tail->{'x'} > $head->{'x'};
        $move->( $tail, 'R' ) if $tail->{'x'} < $head->{'x'};
        $mark_visited->();
        return;
    }

    if ( $head->{'x'} + 2 == $tail->{'x'} ) {
        # move left one and up or down as needed
        $move->( $tail, 'L' );
        $move->( $tail, 'D' ) if $tail->{'y'} > $head->{'y'};
        $move->( $tail, 'U' ) if $tail->{'y'} < $head->{'y'};
        $mark_visited->();
        return;
    }

    if ( $head->{'x'} - 2 == $tail->{'x'} ) {
        # move right one and up or down as needed
        $move->( $tail, 'R' );
        $move->( $tail, 'D' ) if $tail->{'y'} > $head->{'y'};
        $move->( $tail, 'U' ) if $tail->{'y'} < $head->{'y'};
        $mark_visited->();
        return;
    }
};

$init_visited->();
$init_snake->(2);

foreach my $l (@lines) {
    my ( $dir, $num ) = split ' ', $l;
    $update->( $dir ) foreach ( 1 .. $num );
}

printf "Part 1: %s\n", scalar %visited;


$init_visited->();
$init_snake->(10);

foreach my $l (@lines) {
    my ( $dir, $num ) = split ' ', $l;
    foreach ( 1 .. $num ) {
        foreach my $n ( 1 .. $#snake ) {
            $update->( $dir, $n );
        }
    }
}

printf "Part 2: %s\n", scalar %visited;
