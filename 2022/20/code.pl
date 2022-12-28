#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 20
# https://adventofcode.com/2022/day/20

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# 1
# 2
# -3
# 3
# -2
# 0
# 4
# );
# @lines = grep { length $_ } split "\n", $lines;

my $inc = sub { return ( $_[0] + 1 > $#lines ) ? 0 : $_[0] + 1 };
my $dec = sub { return ( $_[0] - 1 < 0 ) ? $#lines : $_[0] - 1 };

my @links;

my $init_links = sub {
    my $node_val = $_[0];  # operation to perform on given value (for Part 2)
    @links = ();

    for ( my $i=0; $i < @lines; $i++ ) {
        my $next = $inc->($i);
        my $prev = $dec->($i);
        push @links, [ $node_val->( $lines[$i] ), $next, $prev ];
    }
};

$init_links->( sub { $_[0] } );

# Reduce the distance to travel by taking the modulus of the array length.
# Doesn't affect the example but makes a big difference with the real data.
my $factor = sub { abs( $_[0] ) % $#links };

my $shift_node = sub {
    my ( $n ) = @_;
    return if $n->[0] == 0;

    if ( $n->[0] > 0 ) {
        foreach ( 1 .. $factor->( $n->[0] ) ) {
            my $o = $links[ $n->[1] ];
            my $p = $links[ $o->[1] ];
            my $m = $links[ $n->[2] ];

            # m-n-o-p becomes m-o-n-p; six links need to update
            $m->[1] = $n->[1];  # now points to o instead of n
            $p->[2] = $o->[2];  # now points to n instead of o
            $o->[2] = $n->[2];  # now points to m instead of n
            $n->[1] = $o->[1];  # now points to p instead of o
            $o->[1] = $p->[2];  # o next is old val of o prev
            $n->[2] = $m->[1];  # n prev is old val of n next
        }
    } else {
        foreach ( 1 .. $factor->( $n->[0] ) ) {
            my $o = $links[ $n->[2] ];
            my $p = $links[ $o->[2] ];
            my $m = $links[ $n->[1] ];

            # p-o-n-m becomes p-n-o-m; six links need to update
            $m->[2] = $n->[2];  # now points to o instead of n
            $p->[1] = $o->[1];  # now points to n instead of o
            $o->[1] = $n->[1];  # now points to m instead of n
            $n->[2] = $o->[2];  # now points to p instead of o
            $o->[2] = $p->[1];  # o prev is old val of o next
            $n->[1] = $m->[2];  # n next is old val of n prev
        }
    }
};

# This gets us the right answer, but it's a bit slow (about 6 sec).
# We can do better by shifting n once instead of shifting it by one
# N times. After much trial and error, the below works and is faster,
# as long as we always remember to use the array length modulus:

$shift_node = sub {
    my ( $n ) = @_;
    return if $n->[0] % $#links == 0;
    # bail out if we don't move, AND ALSO if we wrap back to our current position!

    if ( $n->[0] > 0 ) {

        # First, find the new insertion point for n. Call it q - r.
        my $q = $links[ $n->[1] ];
        $q = $links[ $q->[1] ] foreach ( 2 .. $factor->( $n->[0] ) );
        my $r = $links[ $q->[1] ];

        # Next, remove n from between m and o by pointing them at each other.
        my $o = $links[ $n->[1] ];
        my $m = $links[ $n->[2] ];

        my $n_next = $m->[1];  # n
        my $n_prev = $o->[2];  # n

        $m->[1] = $n->[1];  # now points to o instead of n
        $o->[2] = $n->[2];  # now points to m instead of n

        # Then point q and r at n instead of each other.
        my $next_from_q = $q->[1];  # r
        my $prev_from_r = $r->[2];  # q

        $q->[1] = $n_next;  # q next is old val of m next
        $r->[2] = $n_prev;  # r prev is old val of o prev

        # Finally, update n to point to its new neighbors.
        $n->[1] = $next_from_q;  # n next is old val of q next; now points to r instead of o
        $n->[2] = $prev_from_r;  # n prev is old val of r prev; now points to q instead of m

    } else {  # the same thing but backwards (and in high heels?)

        # First, find the new insertion point for n. Call it q - r.
        my $q = $links[ $n->[2] ];
        $q = $links[ $q->[2] ] foreach ( 2 .. $factor->( $n->[0] ) );
        my $r = $links[ $q->[2] ];

        # Next, remove n from between m and o by pointing them at each other.
        my $o = $links[ $n->[2] ];
        my $m = $links[ $n->[1] ];

        my $n_prev = $m->[2];  # n
        my $n_next = $o->[1];  # n

        $m->[2] = $n->[2];  # now points to o instead of n
        $o->[1] = $n->[1];  # now points to m instead of n

        # Then point q and r at n instead of each other.
        my $prev_from_q = $q->[2];  # r
        my $next_from_r = $r->[1];  # q

        $q->[2] = $n_prev;  # q prev is old val of m prev
        $r->[1] = $n_next;  # r next is old val of o next

        # Finally, update n to point to its new neighbors.
        $n->[2] = $prev_from_q;  # n prev is old val of q prev; now points to r instead of o
        $n->[1] = $next_from_r;  # n next is old val of r next; now points to q instead of m

    }
};

# This can be rewritten to be more concise at the expense of some legibility:

$shift_node = sub {
    my ( $n ) = @_;
    return if $n->[0] % $#links == 0;

    my $d1 = $n->[0] > 0 ? 1 : 2;
    my $d2 = $n->[0] > 0 ? 2 : 1;

    my ( $o, $m, $q ) = ( $links[ $n->[$d1] ], $links[ $n->[$d2] ], $links[ $n->[$d1] ] );
    $q = $links[ $q->[$d1] ] foreach ( 2 .. $factor->( $n->[0] ) );
    my $r = $links[ $q->[$d1] ];

    ( $m->[$d1], $o->[$d2], $q->[$d1], $r->[$d2], $n->[$d1], $n->[$d2] ) =
     ( $n->[$d1], $n->[$d2], $m->[$d1], $o->[$d2], $q->[$d1], $r->[$d2] );
};

$shift_node->($_) foreach @links;

# use Data::Dumper;
# die Dumper \@links;
#
# my $j = 0;
# for ( my $i=0; $i <= $#links; $i++ ) {
#     printf "%s\n", $links[$j]->[0];
#     $j = $links[$j]->[1];
# }

# find the node with value 0
my $find_origin = sub {
    foreach my $n ( @links ) {
        return $n if ( $n->[0] == 0 );
    }
};

my $sum_coordinates = sub {
    my $n = $find_origin->();
    my $sum = 0;

    for ( my $i=1; $i <= 3000; $i++ ) {
        $n = $links[ $n->[1] ];
        $sum += $n->[0] if $i == 1000;
        $sum += $n->[0] if $i == 2000;
        $sum += $n->[0] if $i == 3000;
    }
    return $sum;
};

printf "Part 1: %s\n\n", $sum_coordinates->();


my $decrypt = 811589153;
$init_links->( sub { $_[0] * $decrypt } );

# Multiplying by this large number makes a naive algorithm very angry, but
# our original shift_node code can handle it in a little over a minute, and
# with the new and improved version, it only takes a few seconds!

foreach my $i ( 1 .. 10 ) {
    warn sprintf "Round %2s of 10...\n", $i;
    $shift_node->($_) foreach @links;
}

printf "\nPart 2: %s\n", $sum_coordinates->();

# elapsed time: approx. 10 seconds for both parts together
