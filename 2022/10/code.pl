#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 10
# https://adventofcode.com/2022/day/10

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = qq(
# addx 15
# addx -11
# addx 6
# addx -3
# addx 5
# addx -1
# addx -8
# addx 13
# addx 4
# noop
# addx -1
# addx 5
# addx -1
# addx 5
# addx -1
# addx 5
# addx -1
# addx 5
# addx -1
# addx -35
# addx 1
# addx 24
# addx -19
# addx 1
# addx 16
# addx -11
# noop
# noop
# addx 21
# addx -15
# noop
# noop
# addx -3
# addx 9
# addx 1
# addx -3
# addx 8
# addx 1
# addx 5
# noop
# noop
# noop
# noop
# noop
# addx -36
# noop
# addx 1
# addx 7
# noop
# noop
# noop
# addx 2
# addx 6
# noop
# noop
# noop
# noop
# noop
# addx 1
# noop
# noop
# addx 7
# addx 1
# noop
# addx -13
# addx 13
# addx 7
# noop
# addx 1
# addx -33
# noop
# noop
# noop
# addx 2
# noop
# noop
# noop
# addx 8
# noop
# addx -1
# addx 2
# addx 1
# noop
# addx 17
# addx -9
# addx 1
# addx 1
# addx -3
# addx 11
# noop
# noop
# addx 1
# noop
# addx 1
# noop
# noop
# addx -13
# addx -19
# addx 1
# addx 3
# addx 26
# addx -30
# addx 12
# addx -1
# addx 3
# addx 1
# noop
# noop
# noop
# addx -9
# addx 18
# addx 1
# addx 2
# noop
# noop
# addx 9
# noop
# noop
# noop
# addx -1
# addx 2
# addx -37
# addx 1
# addx 3
# noop
# addx 15
# addx -21
# addx 22
# addx -6
# addx 1
# noop
# addx 2
# addx 1
# noop
# addx -10
# noop
# noop
# addx 20
# addx 1
# addx 2
# addx 2
# addx -6
# addx -11
# noop
# noop
# noop
# );
# @lines = grep { length $_ } split "\n", $lines;

# "during the first cycle" cycle is 1, so no defined zero value
my @cycle = ( undef );
my $x = 1;

my $programs = {
    'noop' => sub { push @cycle, $x },
    'addx' => sub { push @cycle, $x, $x; $x += $_[0] }
};

my $parse_line = sub {
    my ( $do, $arg ) = split ' ', $_[0];
    return $programs->{$do}->($arg);
};

$parse_line->($_) foreach @lines;  # results saved in @cycle

my $sum = 0;

for ( my $i = 20; $i <= 220; $i += 40 ) {
    $sum += $i * $cycle[$i];
}

printf "Part 1: %s\n", $sum;


shift @cycle;  # drop the undef to keep display in sync

my ( $crt_i, @crt_row, @crt_values ) = ( 0 );

my $advance_row = sub {
        push @crt_values, [ @crt_row ];   # save the current row
        @crt_row = ();                    # reset for next row
        $crt_i = 0;                       # reset for next row
};

foreach my $x ( @cycle ) {
    my %sprite = map { $_ => 1 } ( $x - 1 .. $x + 1 );
    push @crt_row, ( $sprite{$crt_i++} ? '#' : '.' );
    $advance_row->() if $crt_i == 40;   # new row every 40 pixels
}

my $output = join "\n", map { join '', @$_ } @crt_values;

printf "Part 2:\n%s\n", $output;
