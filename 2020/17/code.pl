#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 17
# https://adventofcode.com/2020/day/17

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# .#.
# ..#
# ###
# /;
# @lines = grep { length $_ } split "\n", $lines;

# This is very similar to 2022 Day 23, but in three dimensions.

my %cube;
my $init_cube = sub {
    %cube = ();
    my ( $y, $z ) = ( 0, 0 );
    foreach my $l (@lines) {
        my @x = split '', $l;
        for ( my $i=0; $i < @x; $i++ ) {
            $cube{"$i,$y,$z"} = $x[$i];
        }
        $y++;
    }
};
$init_cube->();

my $set_value = sub {
    my $v = pop;
    $cube{ join ',', @_ } = $v;
};

my $point_value = sub {
    return $cube{ join ',', @_ } // '.';
};

my %adj_cache;

my $get_adjacent_dirs_active = sub {
    my ( $x, $y, $z ) = @_;
    my %adj;

    return $adj_cache{"$x,$y,$z"} if $adj_cache{"$x,$y,$z"};

    foreach ( [ $x - 1, $y - 1, $z - 1 ], [ $x - 1, $y - 1, $z + 1 ],
              [ $x + 1, $y - 1, $z - 1 ], [ $x + 1, $y - 1, $z + 1 ],
              [ $x - 1, $y + 1, $z - 1 ], [ $x - 1, $y + 1, $z + 1 ],
              [ $x + 1, $y + 1, $z - 1 ], [ $x + 1, $y + 1, $z + 1 ],
              [ $x + 0, $y - 1, $z - 1 ], [ $x + 0, $y - 1, $z + 1 ],
              [ $x + 0, $y + 1, $z - 1 ], [ $x - 0, $y + 1, $z + 1 ],
              [ $x - 1, $y + 0, $z - 1 ], [ $x - 1, $y + 0, $z + 1 ],
              [ $x + 1, $y + 0, $z - 1 ], [ $x + 1, $y + 0, $z + 1 ],
              [ $x - 1, $y - 1, $z + 0 ], [ $x + 1, $y - 1, $z + 0 ],
              [ $x - 1, $y + 1, $z + 0 ], [ $x + 1, $y + 1, $z + 0 ],
              [ $x + 0, $y - 1, $z + 0 ], [ $x + 0, $y + 1, $z + 0 ],
              [ $x - 1, $y + 0, $z + 0 ], [ $x + 1, $y + 0, $z + 0 ],
              [ $x + 0, $y + 0, $z - 1 ], [ $x + 0, $y + 0, $z + 1 ] ) {

        $adj{ join ',', @$_ } = $point_value->( @$_ ) eq '#' ? 1 : 0;
    }

    $adj_cache{"$x,$y,$z"} = \%adj;
    return \%adj;
};

my $list_active = sub { grep { $cube{$_} eq '#' } keys %cube };

my $num_active = sub { scalar $list_active->() };

my $state_changes = sub {
    my ( @activate, @deactivate, %inactive_check );

    foreach my $act_pt ( $list_active->() ) {
        my $adj = $get_adjacent_dirs_active->( split ',', $act_pt );

        unless ( { 2=>1, 3=>1 }->{ scalar grep { $_ } values %$adj } ) {
            push @deactivate, $act_pt;
        }
        $inactive_check{$_}++ foreach grep { ! $adj->{$_} } keys %$adj;
    }

    # the values of %inactive_check already contain the number of active neighbors!
    @activate = grep { $inactive_check{$_} == 3 } keys %inactive_check;

    $set_value->( split( ',' ), '#' ) foreach @activate;
    $set_value->( split( ',' ), '.' ) foreach @deactivate;
    %adj_cache = ();  # invalidate cache after moves
};

$state_changes->() foreach ( 1 .. 6 );

printf "Part 1: %s\n", $num_active->();


# Another dimension... another dimension... another dimension...

$init_cube = sub {
    %cube = ();
    my ( $y, $z ) = ( 0, 0 );
    foreach my $l (@lines) {
        my @x = split '', $l;
        for ( my $i=0; $i < @x; $i++ ) {
            $cube{"$i,$y,$z,0"} = $x[$i];
        }
        $y++;
    }
};
$init_cube->();

$get_adjacent_dirs_active = sub {
    my ( $x, $y, $z, $w ) = @_;
    my %adj;

    return $adj_cache{"$x,$y,$z,$w"} if $adj_cache{"$x,$y,$z,$w"};

    foreach ( [ $x - 1, $y - 1, $z - 1, $w + 0 ], [ $x - 1, $y - 1, $z + 1, $w + 0 ],
              [ $x + 1, $y - 1, $z - 1, $w + 0 ], [ $x + 1, $y - 1, $z + 1, $w + 0 ],
              [ $x - 1, $y + 1, $z - 1, $w + 0 ], [ $x - 1, $y + 1, $z + 1, $w + 0 ],
              [ $x + 1, $y + 1, $z - 1, $w + 0 ], [ $x + 1, $y + 1, $z + 1, $w + 0 ],
              [ $x + 0, $y - 1, $z - 1, $w + 0 ], [ $x + 0, $y - 1, $z + 1, $w + 0 ],
              [ $x + 0, $y + 1, $z - 1, $w + 0 ], [ $x - 0, $y + 1, $z + 1, $w + 0 ],
              [ $x - 1, $y + 0, $z - 1, $w + 0 ], [ $x - 1, $y + 0, $z + 1, $w + 0 ],
              [ $x + 1, $y + 0, $z - 1, $w + 0 ], [ $x + 1, $y + 0, $z + 1, $w + 0 ],
              [ $x - 1, $y - 1, $z + 0, $w + 0 ], [ $x + 1, $y - 1, $z + 0, $w + 0 ],
              [ $x - 1, $y + 1, $z + 0, $w + 0 ], [ $x + 1, $y + 1, $z + 0, $w + 0 ],
              [ $x + 0, $y - 1, $z + 0, $w + 0 ], [ $x + 0, $y + 1, $z + 0, $w + 0 ],
              [ $x - 1, $y + 0, $z + 0, $w + 0 ], [ $x + 1, $y + 0, $z + 0, $w + 0 ],
              [ $x + 0, $y + 0, $z - 1, $w + 0 ], [ $x + 0, $y + 0, $z + 1, $w + 0 ],

              [ $x - 1, $y - 1, $z - 1, $w - 1 ], [ $x - 1, $y - 1, $z + 1, $w - 1 ],
              [ $x + 1, $y - 1, $z - 1, $w - 1 ], [ $x + 1, $y - 1, $z + 1, $w - 1 ],
              [ $x - 1, $y + 1, $z - 1, $w - 1 ], [ $x - 1, $y + 1, $z + 1, $w - 1 ],
              [ $x + 1, $y + 1, $z - 1, $w - 1 ], [ $x + 1, $y + 1, $z + 1, $w - 1 ],
              [ $x + 0, $y - 1, $z - 1, $w - 1 ], [ $x + 0, $y - 1, $z + 1, $w - 1 ],
              [ $x + 0, $y + 1, $z - 1, $w - 1 ], [ $x - 0, $y + 1, $z + 1, $w - 1 ],
              [ $x - 1, $y + 0, $z - 1, $w - 1 ], [ $x - 1, $y + 0, $z + 1, $w - 1 ],
              [ $x + 1, $y + 0, $z - 1, $w - 1 ], [ $x + 1, $y + 0, $z + 1, $w - 1 ],
              [ $x - 1, $y - 1, $z + 0, $w - 1 ], [ $x + 1, $y - 1, $z + 0, $w - 1 ],
              [ $x - 1, $y + 1, $z + 0, $w - 1 ], [ $x + 1, $y + 1, $z + 0, $w - 1 ],
              [ $x + 0, $y - 1, $z + 0, $w - 1 ], [ $x + 0, $y + 1, $z + 0, $w - 1 ],
              [ $x - 1, $y + 0, $z + 0, $w - 1 ], [ $x + 1, $y + 0, $z + 0, $w - 1 ],
              [ $x + 0, $y + 0, $z - 1, $w - 1 ], [ $x + 0, $y + 0, $z + 1, $w - 1 ],

              [ $x - 1, $y - 1, $z - 1, $w + 1 ], [ $x - 1, $y - 1, $z + 1, $w + 1 ],
              [ $x + 1, $y - 1, $z - 1, $w + 1 ], [ $x + 1, $y - 1, $z + 1, $w + 1 ],
              [ $x - 1, $y + 1, $z - 1, $w + 1 ], [ $x - 1, $y + 1, $z + 1, $w + 1 ],
              [ $x + 1, $y + 1, $z - 1, $w + 1 ], [ $x + 1, $y + 1, $z + 1, $w + 1 ],
              [ $x + 0, $y - 1, $z - 1, $w + 1 ], [ $x + 0, $y - 1, $z + 1, $w + 1 ],
              [ $x + 0, $y + 1, $z - 1, $w + 1 ], [ $x - 0, $y + 1, $z + 1, $w + 1 ],
              [ $x - 1, $y + 0, $z - 1, $w + 1 ], [ $x - 1, $y + 0, $z + 1, $w + 1 ],
              [ $x + 1, $y + 0, $z - 1, $w + 1 ], [ $x + 1, $y + 0, $z + 1, $w + 1 ],
              [ $x - 1, $y - 1, $z + 0, $w + 1 ], [ $x + 1, $y - 1, $z + 0, $w + 1 ],
              [ $x - 1, $y + 1, $z + 0, $w + 1 ], [ $x + 1, $y + 1, $z + 0, $w + 1 ],
              [ $x + 0, $y - 1, $z + 0, $w + 1 ], [ $x + 0, $y + 1, $z + 0, $w + 1 ],
              [ $x - 1, $y + 0, $z + 0, $w + 1 ], [ $x + 1, $y + 0, $z + 0, $w + 1 ],
              [ $x + 0, $y + 0, $z - 1, $w + 1 ], [ $x + 0, $y + 0, $z + 1, $w + 1 ],

              [ $x + 0, $y + 0, $z + 0, $w - 1 ], [ $x + 0, $y + 0, $z + 0, $w + 1 ] ) {

        $adj{ join ',', @$_ } = $point_value->( @$_ ) eq '#' ? 1 : 0;
    }

    $adj_cache{"$x,$y,$z,$w"} = \%adj;
    return \%adj;
};

$state_changes->() foreach ( 1 .. 6 );

printf "Part 2: %s\n", $num_active->();
