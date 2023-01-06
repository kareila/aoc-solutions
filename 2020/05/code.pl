#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 5
# https://adventofcode.com/2020/day/5

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data for part 1
# my $lines = qq/
# FBFBBFFRLR
# BFFFBBFRRR
# FFFBBBFRRR
# BBFFBBFRLL
# /;
# @lines = grep { length $_ } split "\n", $lines;

# we can use the same binary partitioning logic for both seat indices
my $find_index = sub {
    my ( $code, $f ) = @_;  # either F/B or L/R section
    my $n = length $code;
    my @i = ( 0 .. ( 2 ** $n ) - 1 );

    for ( my $c=0; $c < $n; $c++ ) {
        my $l = substr $code, $c, 1;  # look at the nth character in the code
        my $div = scalar @i / 2;      # half the current length of @i

        # keep only the half of @i that the code character says to keep
        @i = ( $f->{$l} ) ? @i[ 0 .. $div - 1 ] : @i[ $div .. $#i ];
    }
    return $i[0];  # only one position remaining
};

my $find_row_index = sub { $find_index->( $_[0], { F => 1, B => 0 } ) };
my $find_col_index = sub { $find_index->( $_[0], { L => 1, R => 0 } ) };

my $seat_id = sub {
    my ( $line ) = @_;
    my ( $r, $c ) = ( $line =~ /^([FB]+)([LR]+)$/ );
    return 8 * $find_row_index->( $r ) + $find_col_index->( $c );
};

my %used_ids;  # for Part 2
my $highest_id = 0;

foreach my $l ( @lines ) {
    my $id = $seat_id->( $l );
    $used_ids{$id} = 1;
    $highest_id = $id if $id > $highest_id;
}

printf "Part 1: %s\n", $highest_id;


my $find_empty_seat = sub {
    my @all_seat_ids = ( $seat_id->( 'FFFFFFFLLL' ) .. $seat_id->( 'BBBBBBBRRR' ) );

    foreach my $id ( @all_seat_ids ) {
        my ( $prev, $next ) = ( $id - 1, $id + 1 );
        return $id if ! $used_ids{$id} && $used_ids{$prev} && $used_ids{$next};
    }
};

printf "Part 2: %s\n", $find_empty_seat->();
