#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 14
# https://adventofcode.com/2020/day/14

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# mask = XXXXXXXXXXXXXXXXXXXXXXXXXXXXX1XXXX0X
# mem[8] = 11
# mem[7] = 101
# mem[8] = 0
# /;
# @lines = grep { length $_ } split "\n", $lines;
# the given example is just for one mask, but the actual input contains several...

# example for Part 2
# my $lines = q/
# mask = 000000000000000000000000000000X1001X
# mem[42] = 100
# mask = 00000000000000000000000000000000X0XX
# mem[26] = 1
# /;
# @lines = grep { length $_ } split "\n", $lines;

my $as_binary = sub {
    my ( $num ) = @_;
    my $max_place = 36;  # from the problem statement
    my $place = 1;
    my @col;

    until ( $num == 0 ) {
        my $mod = ( 2 ** $place );
        push @col, $num % $mod / ( 2 ** ( $place - 1 ) );
        $num -= $num % $mod;
        $place++;
    }

    until ( $place > $max_place ) {
        push @col, 0;
        $place++;
    }
    return join '', reverse @col;
};

my $as_decimal = sub {
    my ( $binnum ) = @_;
    my $len = length $binnum;
    my $number = 0;

    for ( my $i = 1; $i <= $len; $i++ ) {
        my $digit = substr $binnum, $len - $i, 1;
        my $mult = 2 ** ( $i - 1 );
        $number += $digit * $mult;
    }
    return $number;
};

my %mem;
my $active_mask;

my $apply_active_mask = sub {
    my ( $binnum ) = @_;
    my $len = length $binnum;

    for ( my $i=0; $i < $len; $i++ ) {
        my $bit = substr $active_mask, $i, 1;
        next if $bit eq 'X';
        substr $binnum, $i, 1, $bit;
    }
    return $binnum;
};

foreach my $l (@lines) {
    if ( $l =~ /^mask = (\S+)$/ ) {
        $active_mask = $1 and next;
    }
    die "No active mask" unless defined $active_mask;

    my ( $k, $v ) = ( $l =~ /^mem.(\d+). = (\d+)$/ );
    $mem{$k} = $apply_active_mask->( $as_binary->( $v ) );
}

my $sum = 0;
$sum += $as_decimal->($_) foreach values %mem;

printf "Part 1: %s\n", $sum;


%mem = ();

$apply_active_mask = sub {
    my ( $binnum ) = @_;
    my $len = length $binnum;
    my @float;  # keep track of where the X bits are

    for ( my $i=0; $i < $len; $i++ ) {
        my $bit = substr $active_mask, $i, 1;
        next if $bit eq '0';
        push @float, $i if $bit eq 'X';
        substr $binnum, $i, 1, $bit;
    }

    my @addresses = ( $binnum );

    # each float replacement will double the number of addresses
    foreach my $i ( @float ) {
        my @a;
        map { substr $_, $i, 1, '0' } @addresses;
        push @a, @addresses;
        map { substr $_, $i, 1, '1' } @addresses;
        push @a, @addresses;
        @addresses = @a;
    }
    return @addresses;
};

foreach my $l (@lines) {
    if ( $l =~ /^mask = (\S+)$/ ) {
        $active_mask = $1 and next;
    }
    die "No active mask" unless defined $active_mask;

    my ( $k, $v ) = ( $l =~ /^mem.(\d+). = (\d+)$/ );
    my @a = $apply_active_mask->( $as_binary->( $k ) );
    $mem{$_} = $v foreach @a;
}

$sum = 0;
$sum += $_ foreach values %mem;

printf "Part 2: %s\n", $sum;
