#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 17
# https://adventofcode.com/2022/day/17

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
my $line = $lines[0];  # only one super long line today
chomp $line;

# Example data:
# $line = q(>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>);

my $jet_values = $line;
my $jet_index = 0;

my @rocks = (
"
..####.
","
...#...
..###..
...#...
","
....#..
....#..
..###..
","
..#....
..#....
..#....
..#....
","
..##...
..##...
"
);
my $rock_index = 0;
my $shifted = 0;
my $dropped = 0;
my $width = 7;
$width--;   # index from zero
my @rows;

my $set_value = sub {
    my ( $x, $y, $v ) = @_;
    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
    return if $x > $width;   # out of bounds
    $rows[$y]->[$x] = $v;
};

my $point_value = sub {
    my ( $x, $y ) = @_;
    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
    return unless $rows[$y];     # ugh, this would auto-vivify an empty row
    return $rows[$y]->[$x];      # going off the grid is merely undefined
};

my $can_go_down = sub {
    my ( $x, $y ) = @_;
    return 0 if $y - 1 < 0;  # floor
    return 0 if $point_value->( $x, $y - 1 ) eq '#';  # rock
    return 1;
};

my $can_go_left = sub {
    my ( $x, $y ) = @_;
    return 0 if $x - 1 < 0;  # wall
    return 0 if $point_value->( $x - 1, $y ) eq '#';  # rock
    return 1;
};

my $can_go_right = sub {
    my ( $x, $y ) = @_;
    return 0 if $x + 1 > $width;  # wall
    return 0 if $point_value->( $x + 1, $y ) eq '#';  # rock
    return 1;
};

my $scan_current_rock = sub {
    $rock_index = 0 if $rock_index >= scalar @rocks;  # wrap around
    my $r = $rocks[$rock_index];
    return grep { length $_ } split "\n", $r;
};

my $new_rock = sub {
    # add 3 empty rows
    push @rows, [ split '', '.......' ] foreach ( 1..3 );
    # convert the string pattern into array values, building up from y=0
    push @rows, [ split '' ] foreach reverse $scan_current_rock->();
};

my $rock_data = sub {
    # returns some attributes that describe the current rock
    my @r = $scan_current_rock->();
    my $h = scalar @r;   # rock height

    my ( @left_edge, @right_edge, @bottom_edge );

    foreach my $row (@r) {
        my $le = index $row, '#';
        die "Something went wrong in rock_data" if $le == -1;
        push @left_edge, $le + $shifted;
        my $re = index reverse($row), '#';
        push @right_edge, $width - $re + $shifted;
    }

    # THE SECOND (+) ROCK HAS BOTTOM EDGES IN THE MIDDLE...
    my @col = split '', $r[-1];
    my @mid = @r > 1 ? split '', $r[-2] : ();

    for ( my $i=0; $i <= $#col; $i++ ) {
        push @bottom_edge, [ 0, $i + $shifted ] if $col[$i] eq '#';
        push @bottom_edge, [ 1, $i + $shifted ]
            if @mid && $mid[$i] eq '#' && $col[$i] eq '.';
    }
    die "Bottom edge not found?" unless @bottom_edge;

    my $t = $#rows - $dropped;   # y value of top edge

    return { b => \@bottom_edge, l => \@left_edge, r => \@right_edge, h => $h, t => $t };
};

my $shift_rock_left = sub {
    my $edges = $rock_data->();
    my $height = $edges->{h};
    my $top = $edges->{t};
    my $ok = 1;
    my $i;

    # can every point on the left edge move left?
    for ( $i=0; $i < $height; $i++ ) {
        my $left = $edges->{l}->[$i];
        my $y = $top - $i;
        die "Something went wrong in shift_rock_left"
            unless $point_value->( $left, $y ) eq '#';
        $ok &&= $can_go_left->( $left, $y );
    }
    return unless $ok;

    # update the position values
    for ( $i=0; $i < $height; $i++ ) {
        my $left  = $edges->{l}->[$i];
        my $right = $edges->{r}->[$i];
        my $y = $top - $i;

        # move the left edge one space to the left
        $set_value->( $left - 1, $y, '#' );
        # there is now a space where the right edge was
        $set_value->( $right, $y, '.' );
    }
    $shifted--;
};

my $shift_rock_right = sub {
    my $edges = $rock_data->();
    my $height = $edges->{h};
    my $top = $edges->{t};
    my $ok = 1;
    my $i;

    # can every point on the right edge move right?
    for ( $i=0; $i < $height; $i++ ) {
        my $right = $edges->{r}->[$i];
        my $y = $top - $i;
        die "Something went wrong in shift_rock_right"
            unless $point_value->( $right, $y ) eq '#';
        $ok &&= $can_go_right->( $right, $y );
    }
    return unless $ok;

    # update the position values
    for ( $i=0; $i < $height; $i++ ) {
        my $left  = $edges->{l}->[$i];
        my $right = $edges->{r}->[$i];
        my $y = $top - $i;

        # move the right edge one space to the right
        $set_value->( $right + 1, $y, '#' );
        # there is now a space where the left edge was
        $set_value->( $left, $y, '.' );
    }
    $shifted++;
};

my $move_rock_down = sub {
    my $edges = $rock_data->();
    my $height = $edges->{h};
    my $top = $edges->{t};
    my $y = $top - $height + 1;   # location of bottom row of rock
    my $ok = 1;

    # can every point on the bottom edge move down?
    foreach my $p ( @{ $edges->{b} } ) {
        my ( $offset, $x ) = @$p;
        die "Something went wrong in move_rock_down"
            unless $point_value->( $x, $y + $offset ) eq '#';
        $ok &&= $can_go_down->( $x, $y + $offset );
    }
    return 0 unless $ok;

    my @r = $scan_current_rock->();
    my $i = scalar @r - 1;

    # update the position values (for the entire rock, not just the edges)
    for ( my $j = $y; $j <= $top; $j++ ) {
        my @row = split '', $r[$i--];
        for ( my $s=0; $s < @row; $s++ ) {
            next if $row[$s] eq '.';
            my $x = $s + $shifted;
            die "Something went wrong in move_rock_down"
                unless $point_value->( $x, $j ) eq '#';
            $set_value->( $x, $j, '.' );
            $set_value->( $x, $j - 1, '#' );
        }
    }
    $dropped++;
    return 1;  # we need to know if this moved successfully
};

# Cycle detection: at some point the jet pattern will repeat, and we can skip ahead.
# Since the first cycle starts from a flat surface, we only count levels the second time.
# (Used in Part 2.)
my $step = 0;
my $cycle;
my $skip_ahead = 0;

my $jet_action = sub {
    if ( $jet_index >= length $jet_values ) {
        $jet_index = 0;  # loop the pattern
        # store cycle info if we don't have it yet
        unless ( $skip_ahead ) {
            if ( defined $cycle ) {
                $cycle = [ $step - $cycle->[0], scalar @rows - $cycle->[1] ];
                $skip_ahead = 1;
            } else {
                $cycle = [ $step, scalar @rows ];
            }
        }
    }
    my $jet = substr $jet_values, $jet_index++, 1;
    return $shift_rock_left->()  if $jet eq '<';
    return $shift_rock_right->() if $jet eq '>';
    die "Invalid jet value $jet";
};

my $rock_move = sub {
    $step++;
    $new_rock->();
# warn sprintf "%s\n\n", join "\n", map { join  '', @$_ } reverse @rows[-20 .. -1];

    # drop as far as we can
    while (1) {
        $jet_action->();
        last unless $move_rock_down->();
    }

    # remove dead airspace
    while (1) {
        last unless join( '', @{ $rows[-1] } ) eq '.......';
        pop @rows;
    }

    $shifted = 0;
    $dropped = 0;
    $rock_index++;
};

# debugging time! thx https://www.reddit.com/r/adventofcode/comments/zo81kq/2022_day_17_part_1_heights_of_the_tower/
$file = "heights.txt";   # correct level heights for each rock using example input
open $fh, $file or die "No file named $file found.\n";
@lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# # foreach my $n ( 1 .. 2022 ) {
# #     die $n unless scalar @rows == $lines[ $n - 1 ];
# #     warn scalar @rows unless $n % 100;

$rock_move->() foreach ( 1 .. 2022 );

printf "Part 1: %s\n", scalar @rows;


# # Timing this, the straightforward approach takes 187 sec for 1000000 rocks.
# # It would take almost SIX YEARS to compute 1000000000000.
# #
# # Would it be possible to detect a repeating state programmatically?

my $levels = 0;

my $simulate = sub {
    my ( $end ) = @_;
    $rock_move->() until $skip_ahead;

    # $cycle->[0] is number of steps elapsed in each cycle
    # $cycle->[1] is number of levels added in each cycle

    my $skipped_n = int( $end / $cycle->[0] ) - 2;  # we already did 2 cycles
    $levels = $skipped_n * $cycle->[1];
    my $skip = $cycle->[0] * $skipped_n + $step;
    my $rest = $end - $skip;  # how many steps are left after the last cycle completes
    $rock_move->() foreach ( 1 .. $rest );
};

# $simulate->(2022);  # YES this returns the same answer
$simulate->(1000000000000);

printf "Part 2: %s\n", scalar @rows + $levels;
