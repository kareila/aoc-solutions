#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 12
# https://adventofcode.com/2021/day/12

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# start-A
# start-b
# A-c
# A-b
# b-d
# A-end
# b-end
# /;
# @lines = grep { length $_ } split "\n", $lines;

# This is describing a list of links between nodes, forming a network.
# The first task is to count all the possible paths from the start to
# the end. Nodes named in uppercase can be visited multiple times.

my %links;

my $parse_line = sub {
    my ( $l ) = @_;
    return unless $l;
    my $pat = qr/^([^-]+)-([^-]+)$/;
    my ( $n1, $n2 ) = ( $l =~ $pat );
    die "Parse error" unless $n2;

    unless ( $n2 eq 'start' || $n1 eq 'end' ) {  # can't reverse these
        $links{$n1} //= [];
        push @{ $links{$n1} }, $n2;
    }

    unless ( $n1 eq 'start' || $n2 eq 'end' ) {  # can't reverse these
        $links{$n2} //= [];
        push @{ $links{$n2} }, $n1;
    }
};

$parse_line->($_) foreach @lines;

my @paths;

# Here (and elsewhere) I use non-local subroutines when needed for recursion.
sub map_paths {
    my ( $path, $visited ) = @_;
    $path //= [ 'start' ];
    $visited //= {};

    # Where are we?
    my $cur_pos = $path->[-1];

    # Have we reached the end?
    if ( $cur_pos eq 'end' ) {
        push @paths, $path;
        return;
    }

    # Are we attempting to revisit a "small" cave?
    if ( $cur_pos =~ /^[a-z]+$/ && $visited->{ $cur_pos } ) {
        return;  # dead end
    }

    # Note that we have visited this position.
    $visited->{ $cur_pos }++;

    # Branch out in all directions.
    foreach ( @{ $links{ $cur_pos } } ) {
        map_paths( [ @$path, $_ ], { %$visited } );
    }
}

map_paths();

printf "Part 1: %s\n", scalar @paths;


# Now we're allowed to visit one small (lowercase) cave twice.
@paths = ();

sub map_paths_2 {
    my ( $path, $visited, $small_ok ) = @_;
    $path //= [ 'start' ];
    $visited //= {};
    $small_ok //= 1;

    # Where are we?
    my $cur_pos = $path->[-1];

    # Have we reached the end?
    if ( $cur_pos eq 'end' ) {
        push @paths, $path;
        return;
    }

    # Are we attempting to revisit a "small" cave?
    if ( $cur_pos =~ /^[a-z]+$/ && $visited->{ $cur_pos } ) {
        if ( $small_ok ) {
            $small_ok = 0;
        } else {
            return;  # dead end
        }
    }

    # Note that we have visited this position.
    $visited->{ $cur_pos }++;

    # Branch out in all directions.
    foreach ( @{ $links{ $cur_pos } } ) {
        map_paths_2( [ @$path, $_ ], { %$visited }, $small_ok );
    }
}

map_paths_2();

printf "Part 2: %s\n", scalar @paths;
