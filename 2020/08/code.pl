#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 8
# https://adventofcode.com/2020/day/8

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = qq/
# nop +0
# acc +1
# jmp +4
# acc +3
# jmp -3
# acc -99
# acc +1
# jmp -4
# acc +6
# /;
# @lines = grep { length $_ } split "\n", $lines;

my ( $accum, $index, %visited ) = ( 0, 0 );
my $init_state = sub { $accum = 0; $index = 0; %visited = () };

my $programs = {
    'acc' => sub { $accum += $_[0]; $index++ },
    'jmp' => sub { $index += $_[0] },
    'nop' => sub { $index++ }
};

my $parse_line = sub {
    my ( $l ) = @_;
    my ( $do, $sign, $arg ) = ( $l =~ /^(\w{3}) ([-+])(\d+)$/ );
    return $programs->{$do}->( $sign eq '-' ? 0 - $arg : $arg );
};

while ( ! $visited{$index} ) {
    $visited{$index}++;
    $parse_line->( $lines[$index] );  # changes the value of $index
}

printf "Part 1: %s\n", $accum;


my $edit_line = sub {
    my ( $num ) = @_;
    my $l = $lines[$num];
    my $adjust = { qw( acc acc jmp nop nop jmp ) };
    my $is = substr $l, 0, 3;
    substr $l, 0, 3, $adjust->{$is};  # this modifies $l
    return $l if $lines[$num] ne $l;  # undef if unchanged
};

SEARCH:
for ( my $num=0; $num < @lines; $num++ ) {
    my $l = $edit_line->($num);
    next unless $l;

    # make a copy of @lines with the current $l modified
    my @version = @lines;
    $version[$num] = $l;

    # reset the program state
    $init_state->();

    while ( ! $visited{$index} ) {
        last SEARCH if $index >= @lines;
        $visited{$index}++;
        $parse_line->( $version[$index] );
    }
    # try the next instruction line if we hit a program loop instead of terminating
}

printf "Part 2: %s\n", $accum;
