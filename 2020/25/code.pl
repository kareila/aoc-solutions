#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 25
# https://adventofcode.com/2020/day/25

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# 5764801
# 17807724
# /;
# @lines = grep { length $_ } split "\n", $lines;

# We're not told which key belongs to which device, but I guess they're interchangeable?
my @keys = @lines;
my $modulus = 20201227;

my $loop_step = sub {
    my ( $val, $subject, $num_times ) = @_;
    foreach ( 1 .. $num_times // 1 ) {
        $val *= $subject;
        $val %= $modulus;
    }
    return $val;
};

my %loop_size;

foreach my $k (@keys) {
    my $init_subject = 7;
    my $num_loops = 0;
    my $answer = 1;

    until ( $answer == $k ) {
        $answer = $loop_step->( $answer, $init_subject );
        $num_loops++;
    }

    $loop_size{$k} = $num_loops;

    # n.b. on the real data the loop sizes are in the millions, takes about 5 sec
    # for both, but we only need one - so let's just bail out after solving once
    last;
}

my $encryption_key = $loop_step->( 1, $keys[1], $loop_size{ $keys[0] } );

printf "Part 1: %s\n", $encryption_key;

# There is no Part 2!  Merry Christmas!
