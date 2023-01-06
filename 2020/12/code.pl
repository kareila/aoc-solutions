#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 12
# https://adventofcode.com/2020/day/12

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# F10
# N3
# F7
# R90
# F11
# /;
# @lines = grep { length $_ } split "\n", $lines;

my %pos = ( facing => 0, 'y' => 0, 'x' => 0 );

my $do_instruction = sub {
    my ( $line ) = @_;
    my ( $op, $num ) = ( $line =~ /^(\w)(\d+)$/ );
    die "Parse error" unless $op;

    $pos{'x'} += $num if $op eq 'E' || $op eq 'F' && $pos{facing} == 0;
    $pos{'y'} -= $num if $op eq 'S' || $op eq 'F' && $pos{facing} == 90;
    $pos{'x'} -= $num if $op eq 'W' || $op eq 'F' && $pos{facing} == 180;
    $pos{'y'} += $num if $op eq 'N' || $op eq 'F' && $pos{facing} == 270;

    $pos{facing} += $num if $op eq 'R';
    $pos{facing} -= $num if $op eq 'L';
    $pos{facing} += 360 if $pos{facing} < 0;
    $pos{facing} -= 360 if $pos{facing} >= 360;
};

$do_instruction->($_) foreach @lines;

my $m_dist = sub {
    my ( $x1, $y1, $x2, $y2 ) = @_;

    # calculate the Manhattan distance for any two points
    return abs( $x1 - $x2 ) + abs( $y1 - $y2 );
};

printf "Part 1: %s\n", $m_dist->( 0, 0, $pos{'x'}, $pos{'y'} );


my %wpt = ( 'y' => 1, 'x' => 10 );
%pos = ( 'y' => 0, 'x' => 0 );  # reset, no facing

$do_instruction = sub {
    my ( $line ) = @_;
    my ( $op, $num ) = ( $line =~ /^(\w)(\d+)$/ );
    die "Parse error" unless $op;

    $wpt{'x'} += $num if $op eq 'E';
    $wpt{'y'} -= $num if $op eq 'S';
    $wpt{'x'} -= $num if $op eq 'W';
    $wpt{'y'} += $num if $op eq 'N';

    if ( $op eq 'F' ) {
        foreach ( 1 .. $num ) {
            $pos{'y'} += $wpt{'y'};
            $pos{'x'} += $wpt{'x'};
        }
    }

    my ( $x, $y ) = ( $wpt{'x'}, $wpt{'y'} );

    if ( $op eq 'R' && $num == 90 || $op eq 'L' && $num == 270 ) {
        $wpt{'y'} = 0 - $x;
        $wpt{'x'} = 0 + $y;
    }

    if ( $op eq 'R' && $num == 270 || $op eq 'L' && $num == 90 ) {
        $wpt{'y'} = 0 + $x;
        $wpt{'x'} = 0 - $y;
    }

    if ( $op eq 'R' && $num == 180 || $op eq 'L' && $num == 180 ) {
        $wpt{'y'} = 0 - $y;
        $wpt{'x'} = 0 - $x;
    }
};

$do_instruction->($_) foreach @lines;

printf "Part 2: %s\n", $m_dist->( 0, 0, $pos{'x'}, $pos{'y'} );
