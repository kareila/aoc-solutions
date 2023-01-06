#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 23
# https://adventofcode.com/2020/day/23

# This is quite similar to 2022 Day 20, but we can use
# a more simple linked list instead of doubly-linked.

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/389125467/;
# @lines = grep { length $_ } split "\n", $lines;

@lines = split '', $lines[0];  # nine integers

my ( $low_value, $high_value ) = ( sort { $a <=> $b } @lines )[0,-1];

# Simplest possible representation: list of next values indexed to current value.
# (I did try implementing this as a hash, but performance was about 50% slower.)
my @next;
my $current_cup;

my $init_data = sub {
    my $num_cups = scalar @lines;
    @next = ();

    for ( my $i=0; $i < $num_cups; $i++ ) {
        last unless defined $lines[$i];
        $next[ $lines[$i] ] = $lines[ $i + 1 ] // $lines[0];
    }
    $current_cup = $lines[0];
};

$init_data->();

my $cup_move = sub {
    my $m = $current_cup;
    my $n = $next[$m];
    my $o = $next[$n];
    my $p = $next[$o];
    my $q = $next[$p];

    # remove n,o,p
    $next[$m] = $q;

    # select destination
    my %held = map { $_ => 1 } ( $n, $o, $p );
    my $val = $current_cup;
    my $try = sub { return ( $_[0] - 1 ) < $low_value ? $high_value : ( $_[0] - 1 ) };
    my $d;

    until ( defined $d ) {
        $val = $try->( $val );
        next if $held{ $val };
        $d = $val;
    }
    my $e = $next[$d];

    # old order: m -> n -> o -> p -> q, d -> e
    # new order: d -> n -> o -> p -> e, m -> q
    @next[ $d, $p ] = ( $n, $e );

    $current_cup = $next[ $current_cup ];
};

my $print_order = sub {
    my ( $val ) = @_;
    die unless $val;
    my $s = $val;
    my $n = $next[$val];

    until ( $n == $val ) {
        $s .= $n;
        $n  = $next[$n];
    }
    return $s;
};

my $print_order_after = sub { return substr $print_order->($_[0]), 1 };

$cup_move->() foreach (1..100);

printf "Part 1: %s\n\n", $print_order_after->(1);


# Now we need to add more cups, up to a million, following our initial order.
# Our cup_move logic won't change, but we'll need to adjust the setup steps.

$init_data = sub {
    my $num_cups = $_[0];
    die "invalid number of cups" unless defined $num_cups && $num_cups > @lines;
    @next = ( 1 .. $num_cups );
    push @next, $lines[0];
    $next[0] = undef;

    for ( my $i=0; $i < $num_cups; $i++ ) {
        last unless defined $lines[$i];
        $next[ $lines[$i] ] = $lines[ $i + 1 ] // $i + 2;
    }
    $current_cup = $lines[0];
};

$high_value = 1000000;

$init_data->( $high_value );

foreach my $t ( 1 .. 10000000 ) {
    $cup_move->();
    warn sprintf "%s moves remaining...\n", 10000000 - $t unless $t % 500000;
}

my $find_stars = sub {
    my $n = 1;
    my $a = $next[$n];
    my $b = $next[$a];

    return $a * $b;
};

printf "\nPart 2: %s\n", $find_stars->();

# elapsed time: approx. 30 seconds
