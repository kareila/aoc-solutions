#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 23
# https://adventofcode.com/2022/day/23

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# ....#..
# ..###.#
# #...#.#
# .#...##
# #.###..
# ##.#.##
# .#..#..
# );
# @lines = grep { length $_ } split "\n", $lines;
#
# # Smaller example:
# $lines = q(
# .....
# ..##.
# ..#..
# .....
# ..##.
# .....
# );
# @lines = grep { length $_ } split "\n", $lines;

# let's try using a hash today since the area expands in arbitrary directions?
my %rows;
my $init_rows = sub {
    %rows = ();
    my $y = 0;
    foreach my $l (@lines) {
        my @x = split '', $l;
        for ( my $i=0; $i < @x; $i++ ) {
            $rows{"$y,$i"} = $x[$i];
        }
        $y++;
    }
};
$init_rows->();

# we also want to be able to convert the hash to an array,
# for debugging display but also to compute min_rectangle
my $row_array = sub {
    # first loop: split the hash keys into a dimensional structure
    my %y;
    my ( $min_x, $min_y );
    foreach my $k ( keys %rows ) {
        my ( $j, $i ) = split ',', $k;
        $y{$j} //= [];
        push @{ $y{$j} }, $i;
        $min_x = $i unless defined $min_x && $min_x < $i;
        $min_y = $j unless defined $min_y && $min_y < $j;
    }
    # second loop: create a zero-origin array containing the hash values
    my @a;
    my $max_x;
    foreach my $j ( sort { $a <=> $b } keys %y ) {
        foreach my $i ( sort { $a <=> $b } @{ $y{$j} } ) {
            my ( $x, $y ) = ( $i - $min_x, $j - $min_y );
            $a[$y]->[$x] = $rows{"$j,$i"};
            $max_x = $x unless defined $max_x && $max_x > $x;
        }
    }
    # third loop: pad all array rows to have equal length
    for ( my $j = 0; $j < @a; $j++ ) {
        for ( my $i = 0; $i <= $max_x; $i++ ) {
            $a[$j]->[$i] //= '.';
        }
    }
    return @a;
};

my $min_rectangle = sub {
    my @rows = $row_array->();

    # top edge
    while (1) {
        last if grep { ( $_ // '' ) eq '#' } @{ $rows[0] };
        shift @rows;
    }

    # bottom edge
    while (1) {
        last if grep { ( $_ // '' ) eq '#' } @{ $rows[-1] };
        pop @rows;
    }

    # left edge
    while (1) {
        my @left = map { $_->[0] } @rows;
        last if grep { ( $_ // '' ) eq '#' } @left;
        map { shift @$_ } @rows;
    }

    # right edge
    while (1) {
        my @right = map { $_->[-1] } @rows;
        last if grep { ( $_ // '' ) eq '#' } @right;
        map { pop @$_ } @rows;
    }

    return @rows;
};

# die sprintf "%s\n", join "\n", map { join '', @$_ } ( $min_rectangle->() );

my $set_value = sub {
    my ( $x, $y, $v ) = @_;
    $rows{"$y,$x"} = $v;
};

my $point_value = sub {
    my ( $x, $y ) = @_;
    return $rows{"$y,$x"} // '.';
};

my %adj_occ_cache;

my $get_adjacent_dirs_occupied = sub {
    my ( $x, $y ) = @_;
    my %adj;

    # caching this speeds up our code by about 35-40%
    return $adj_occ_cache{"$y,$x"} if $adj_occ_cache{"$y,$x"};

    $adj{NW}++ if $point_value->( $x - 1, $y - 1 ) eq '#';
    $adj{NE}++ if $point_value->( $x + 1, $y - 1 ) eq '#';
    $adj{SW}++ if $point_value->( $x - 1, $y + 1 ) eq '#';
    $adj{SE}++ if $point_value->( $x + 1, $y + 1 ) eq '#';

    $adj{N}++ if $point_value->( $x, $y - 1 ) eq '#';
    $adj{S}++ if $point_value->( $x, $y + 1 ) eq '#';

    $adj{W}++ if $point_value->( $x - 1, $y ) eq '#';
    $adj{E}++ if $point_value->( $x + 1, $y ) eq '#';

    $adj_occ_cache{"$y,$x"} = \%adj;
    return \%adj;
};

my $n_rule = sub {
    my ( $x, $y ) = @_;
    my $adj = $get_adjacent_dirs_occupied->( $x, $y );
    my $dir = sprintf "%s,%s", $y - 1, $x;
    return ( ! $adj->{N} && ! $adj->{NE} && ! $adj->{NW} ) ? $dir : '';
};

my $s_rule = sub {
    my ( $x, $y ) = @_;
    my $adj = $get_adjacent_dirs_occupied->( $x, $y );
    my $dir = sprintf "%s,%s", $y + 1, $x;
    return ( ! $adj->{S} && ! $adj->{SE} && ! $adj->{SW} ) ? $dir : '';
};

my $w_rule = sub {
    my ( $x, $y ) = @_;
    my $adj = $get_adjacent_dirs_occupied->( $x, $y );
    my $dir = sprintf "%s,%s", $y, $x - 1;
    return ( ! $adj->{W} && ! $adj->{NW} && ! $adj->{SW} ) ? $dir : '';
};

my $e_rule = sub {
    my ( $x, $y ) = @_;
    my $adj = $get_adjacent_dirs_occupied->( $x, $y );
    my $dir = sprintf "%s,%s", $y, $x + 1;
    return ( ! $adj->{E} && ! $adj->{NE} && ! $adj->{SE} ) ? $dir : '';
};

my $rules = [ $n_rule, $s_rule, $w_rule, $e_rule ];
my $first_rule = 0;

my $list_rules = sub {
    my @r = ( @$rules, @$rules );
    return @r[ $first_rule .. $first_rule + 3 ];
};

my $list_elves = sub {
    return grep { $rows{$_} eq '#' } keys %rows;
};

my $propose_moves = sub {
    my %choices;
    my %collisions;
    my @rules = $list_rules->();

    foreach my $elf ( $list_elves->() ) {
        my ( $y, $x ) = split ',', $elf;
        my $adj = $get_adjacent_dirs_occupied->( $x, $y );
        next unless values %$adj;  # do nothing

        foreach my $rule ( @rules ) {
            if ( my $choice = $rule->( $x, $y ) ) {
                if ( exists $choices{$choice} || exists $collisions{$choice} ) {
                    # someone else also made the same choice
                    delete $choices{$choice};
                    $collisions{$choice}++;
                } else {
                    $choices{$choice} = $elf;
                }
                last;  # no second choices
            }
        }
    }
    # advance $first_rule for the next round
    $first_rule = ( $first_rule + 1 ) % scalar @$rules;
    return \%choices;
};

my $apply_choices = sub {
    my $moves = $propose_moves->();

    while ( my ( $new, $old ) = each %$moves ) {
        my ( $yo, $xo ) = split ',', $old;
        $set_value->( $xo, $yo, '.' );
        my ( $yn, $xn ) = split ',', $new;
        $set_value->( $xn, $yn, '#' );
    }

    %adj_occ_cache = ();
    return scalar keys %$moves;
};

my $num_empty_tiles = sub {
    my $count = 0;
    foreach ( $min_rectangle->() ) {
        $count += scalar grep { ( $_ // '' ) ne '#' } @$_;
    }
    return $count;
};

$apply_choices->() foreach ( 1 .. 10 );

printf "Part 1: %s\n", $num_empty_tiles->();


# pick up where we left off
my $round = 10;
my $last_num_changed;

until ( defined $last_num_changed && $last_num_changed == 0 ) {
    $last_num_changed = $apply_choices->();
    $round++;
    warn "Round $round...\n" unless $round % 100;
}

printf "Part 2: %s\n", $round;

# elapsed time: approx. 17 seconds for both parts together
