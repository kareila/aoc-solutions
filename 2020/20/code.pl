#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 20
# https://adventofcode.com/2020/day/20

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# Tile 2311:
# ..##.#..#.
# ##..#.....
# #...##..#.
# ####.#...#
# ##.##.###.
# ##...#.###
# .#.#.#..##
# ..#....#..
# ###...#.#.
# ..###..###
#
# Tile 1951:
# #.##...##.
# #.####...#
# .....#..##
# #...######
# .##.#....#
# .###.#####
# ###.##.##.
# .###....#.
# ..#.#..#.#
# #...##.#..
#
# Tile 1171:
# ####...##.
# #..##.#..#
# ##.#..#.#.
# .###.####.
# ..###.####
# .##....##.
# .#...####.
# #.##.####.
# ####..#...
# .....##...
#
# Tile 1427:
# ###.##.#..
# .#..#.##..
# .#.##.#..#
# #.#.#.##.#
# ....#...##
# ...##..##.
# ...#.#####
# .#.####.#.
# ..#..###.#
# ..##.#..#.
#
# Tile 1489:
# ##.#.#....
# ..##...#..
# .##..##...
# ..#...#...
# #####...#.
# #..#.#.#.#
# ...#.#.#..
# ##.#...##.
# ..##.##.##
# ###.##.#..
#
# Tile 2473:
# #....####.
# #..#.##...
# #.##..#...
# ######.#.#
# .#...#.#.#
# .#########
# .###.#..#.
# ########.#
# ##...##.#.
# ..###.#.#.
#
# Tile 2971:
# ..#.#....#
# #...###...
# #.#.###...
# ##.##..#..
# .#####..##
# .#..####.#
# #..#.#..#.
# ..####.###
# ..#.#.###.
# ...#.#.#.#
#
# Tile 2729:
# ...#.#.#.#
# ####.#....
# ..#.#.....
# ....#..#.#
# .##..##.#.
# .#.####...
# ####.#.#..
# ##.####...
# ##..#.##..
# #.##...##.
#
# Tile 3079:
# #.#.#####.
# .#..######
# ..#.......
# ######....
# ####.#..#.
# .#...#.##.
# #.#####.##
# ..#.###...
# ..#.......
# ..#.###...
# /;
# @lines = split "\n", $lines;

my %tiles;  # input data

{
    my $current_tile;

    for ( my $i=0; $i < @lines; $i++ ) {
        next unless length $lines[$i];
        if ( $lines[$i] =~ /^Tile (\d+):$/ ) {
            $current_tile = $1;
            $tiles{ $current_tile } = [];
            next;
        }
        die "No current tile number" unless defined $current_tile;

        # we removed blank lines, so all other lines are layout data
        push @{ $tiles{ $current_tile } }, [ split '', $lines[$i] ];
    }
}

# First we need to match edges - eight per tile (including flipped).
# Corner pieces will have two edges that don't match any other edges.
# Explanation of edge values: clockwise 1-7 odds for face up,
# counterclockwise 2-8 evens for face down.
my %edges;

foreach my $t_id ( keys %tiles ) {
    my $t = $tiles{$t_id};
    $edges{$t_id} = {};

    # top edge
    $edges{$t_id}->{ join '', @{ $t->[0] } } = 1;
    $edges{$t_id}->{ join '', reverse @{ $t->[0] } } = 2;

    # right edge
    $edges{$t_id}->{ join '', map { $_->[-1] } @$t } = 3;
    $edges{$t_id}->{ join '', reverse map { $_->[-1] } @$t } = 8;

    # bottom edge
    $edges{$t_id}->{ join '', @{ $t->[-1] } } = 6;
    $edges{$t_id}->{ join '', reverse @{ $t->[-1] } } = 5;

    # left edge
    $edges{$t_id}->{ join '', map { $_->[0] } @$t } = 4;
    $edges{$t_id}->{ join '', reverse map { $_->[0] } @$t } = 7;
}

my %matches;

while ( my ( $t_id, $e ) = each %edges ) {
    foreach ( keys %$e ) {
        $matches{$_} //= [];
        push @{ $matches{$_} }, $t_id;
    }
}

# Now we know which edge patterns belong to which tiles,
# but each match is saved twice, for flipped and unflipped
# states, so our match values will be doubled.  We should do
# a reduction step so that we don't count everything twice.
# While we're at it, let's also remove the unmatched edges.

foreach my $e ( keys %matches ) {
    next unless exists $matches{$e};
    delete $matches{$e} if scalar @{ $matches{$e} } == 1;  # unmatched
    delete $matches{ scalar reverse $e };
}

# Construct a map of which tiles are adjacent to a given tile.
my %adjacent;

foreach my $v ( values %matches ) {
    foreach my $t_id ( @$v ) {
        $adjacent{$t_id} //= [];
        push @{ $adjacent{$t_id} }, grep { $_ != $t_id } @$v;
    }
}

# Part 1 says to get the IDs of the four corner tiles, which
# will be the ones with only two neighboring tiles.

my @corner_tiles = sort grep { scalar @{ $adjacent{$_} } == 2 } keys %adjacent;
my $product = 1;
$product *= $_ foreach @corner_tiles;

printf "Part 1: %s\n", $product;


# The next logical step is to assemble the tile layout according to IDs.
my $grid_size = sqrt scalar keys %tiles;
my %pos_tile;

{
    my %unused_tiles = map { $_ => 1 } keys %tiles;

    my $use_tile = sub {
        my ( $t, $p ) = @_;
        $pos_tile{$p} = $t;
        delete $unused_tiles{$t};
    };

    # DEBUG: use the same top left corner as the instructions: 1951
    my $start_tile = $corner_tiles[0];
    my $adj = [ sort @{ $adjacent{ $start_tile } } ];  # sort for consistent ordering
                                                       # to aid with future debugging
    $use_tile->( $start_tile, "0,0" );
    $use_tile->( $adj->[0],   "1,0" );
    $use_tile->( $adj->[1],   "0,1" );

    # Having one corner mapped out is enough to construct the rest of the layout.
    my $adj_ids = sub { grep { $unused_tiles{$_} } @{ $adjacent{ $_[0] } } };

    for ( my $j=1; $j < $grid_size; $j++ ) {
        for ( my $i=1; $i < $grid_size; $i++ ) {
            # Fill in the one other tile adjacent to both 1,0 and 0,1
            my %int;
            $int{$_}++ foreach $adj_ids->( $pos_tile{ join ',', $i-1, $j } );
            $int{$_}++ foreach $adj_ids->( $pos_tile{ join ',', $i, $j-1 } );
            my $t1 = { reverse %int }->{2};
            $use_tile->( $t1, join ',', $i, $j );

            next if ( $i == $grid_size - 1 ) || $j > 1;  # only for top edge

            # Find the one unused tile adjacent to 1,0 and put it at 2,0
            my $t2 = [ $adj_ids->( $pos_tile{ join ',', $i, $j-1 } ) ]->[0];
            $use_tile->( $t2, join ',', $i+1, $j-1 );
        }
        next if $j == $grid_size - 1;

        # Find the one unused tile adjacent to 0,1 and put it at 0,2
        my $t = [ $adj_ids->( $pos_tile{ join ',', 0, $j } ) ]->[0];
        $use_tile->( $t, join ',', 0, $j+1 );
    }
}

# Now comes the tricky part - filling in the tile data according to our layout.
# We have to determine the proper orientation of each tile AND make sure the
# flipped state of each tile is consistent with the other tiles already placed.
#
# To uniquely identify each tile's orientation, let's use the value of its "top".
# Start with the top left corner of the grid and assume the odds are clockwise.

my %orientation;

my $orient_tile = sub {
    my ( $x, $y ) = @_;
    my $t_id = $pos_tile{ join ',', $x, $y };
    return $orientation{ $t_id } if exists $orientation{ $t_id };

    my %e_vals = reverse %{ $edges{$t_id} };
    map { delete $e_vals{$_} } ( 2, 4, 6, 8 ) unless %orientation;
    my %t_edges = reverse %e_vals;

    # Gather the subset of edge matches that involve this tile.
    my %t_matches;

    while ( my ( $id, $e ) = each %edges ) {
        foreach ( keys %$e ) {
            next unless $t_edges{$_};
            $t_matches{$_} //= [];
            push @{ $t_matches{$_} }, sprintf "%s_%s", $id, $e->{$_};
        }
    }

    # Once at least one tile is placed, we have to maintain consistency;
    # ignore any adjacent tiles that we don't know the orientation of.
    my %o_ids;

    foreach ( @{ $adjacent{$t_id} } ) {
        $o_ids{$_}++ unless %orientation && ! exists $orientation{$_};
    }
    die "Tile oriented out of bounds" unless %o_ids;

    # Find the relative position of each tile remaining in %o_ids.
    my $n = 0;
    my $np = { 0 => 'x-1', 1 => 'x+1', 2 => 'y-1', 3 => 'y+1' };
    foreach ( [ $x-1, $y ], [ $x+1, $y ], [ $x, $y-1 ], [ $x, $y+1 ] ) {
        my ( $i, $j ) = @$_;
        my $v = $np->{ $n++ };
        my $t = $pos_tile{ join ',', $i, $j };
        next unless defined $t && exists $o_ids{$t};
        $o_ids{$t} = $v;
    }

    my $calc_top = sub {
        my ( $edge_val, $edge_pos, $ccw ) = @_;
        return $edge_val + 0 if $edge_pos eq 'y-1';
        return ( ( $edge_val + 4 ) % 8 ) || 8 if $edge_pos eq 'y+1';
        # Clockwise direction alternates with every tile in the grid.
        # This logic assumes that we put a clockwise tile at 0,0.
        if ( $ccw % 2 ) {
            return ( ( $edge_val + 6 ) % 8 ) || 8 if $edge_pos eq 'x-1';
            return ( ( $edge_val + 2 ) % 8 ) || 8 if $edge_pos eq 'x+1';
        } else {
            return ( ( $edge_val + 2 ) % 8 ) || 8 if $edge_pos eq 'x-1';
            return ( ( $edge_val + 6 ) % 8 ) || 8 if $edge_pos eq 'x+1';
        }
    };

    # we need to know which of our edge values goes with which adjacent tile (t_vals)
    # as well as the adjacent tile's edge value, for uniqueness purposes (o_vals)
    my ( %t_vals, %o_vals );

    foreach my $v ( values %t_matches ) {
        next unless @$v > 1;  # unmatched
        my %vals = map { split '_' } @$v;  # tile id => edge value
        my $o_id = [ grep { $_ != $t_id } keys %vals ]->[0];
        next unless $o_ids{$o_id};
        $t_vals{$o_id} = [ grep { defined } ( $vals{$t_id}, @{ $t_vals{$o_id} } ) ];
        $o_vals{$o_id} = [ grep { defined } ( $vals{$o_id}, @{ $o_vals{$o_id} } ) ];
    }

    foreach my $oid ( keys %o_ids ) {
        if ( %orientation ) {
            if ( $o_vals{$oid}->[0] % 2 == $orientation{ $oid } % 2 ) {
                $t_vals{$oid} = $t_vals{$oid}->[0];
            } else {
                $t_vals{$oid} = $t_vals{$oid}->[1];
            }
        } else {
            # We started our initial position assuming we weren't flipped,
            # but if our edge values are running counterclockwise, we need
            # to go clockwise with the even numbers instead.
            my %op = reverse %o_ids;
            my ( $a_side, $b_side ) = ( $t_vals{ $op{'x+1'} }, $t_vals{ $op{'y+1'} } );
            if ( { -2 => 1, 6 => 1 }->{ $b_side->[0] - $a_side->[0] } ) {
                $t_vals{$oid} = { 1=>2, 3=>8, 5=>6, 7=>4 }->{ $t_vals{$oid}->[0] };
            }
        }
        $orientation{ $t_id } = $calc_top->( $t_vals{$oid}, $o_ids{$oid}, $x + $y );
        return $orientation{ $t_id };
    }
};

for ( my $j=0; $j < $grid_size; $j++ ) {
    for ( my $i=0; $i < $grid_size; $i++ ) {
        $orient_tile->( $i, $j );
    }
}

# After all that, we can finally start to think about drawing the assembled image.
# The instructions say to start by removing the borders of each tile from its data.

foreach my $t_id ( keys %tiles ) {
    my $t = $tiles{$t_id};
    my $new_tile_size = scalar @$t - 2;

    my @new_t = @$t[ 1 .. $new_tile_size ];
    for ( my $i=0; $i < $new_tile_size; $i++ ) {
        $new_t[ $i ] = [ @{ $new_t[ $i ] }[ 1 .. $new_tile_size ] ];
    }
    $tiles{$t_id} = \@new_t;
}

# Next, we need to solve the general question of how to
# rearrange a data grid to match a specific orientation.

my $rotate_data = sub {
    my ( $data, $orient, $ccw ) = @_;
    $ccw = $ccw % 2;   # I keep forgetting to take the modulus :(
    my @d;

    # top edge, unflipped
    return $data if $orient == ( $ccw ? 2 : 1 );

    # top edge, flipped
    if ( $orient == ( $ccw ? 1 : 2 ) ) {
        push @d, [ reverse @$_ ] foreach @$data;
        return \@d;
    }

    # bottom edge, flipped
    if ( $orient == ( $ccw ? 5 : 6 ) ) {
        push @d, reverse @$data;
        return \@d;
    }

    # bottom edge, unflipped
    if ( $orient == ( $ccw ? 6 : 5 ) ) {
        push @d, [ reverse @$_ ] foreach reverse @$data;
        return \@d;
    }

    # We can reuse these same operations on the other four edges
    # if we rotate the entire grid ninety degrees first.
    my @r_data;
    for ( my $i = scalar @{ $data->[0] } - 1; $i >= 0; $i-- ) {
        push @r_data, [ map { $_->[$i] } @$data ];
    }

    # right edge, unflipped
    return \@r_data if $orient == ( $ccw ? 8 : 3 );

    # right edge, flipped
    if ( $orient == ( $ccw ? 3 : 8 ) ) {
        push @d, [ reverse @$_ ] foreach @r_data;
        return \@d;
    }

    # left edge, flipped
    if ( $orient == ( $ccw ? 7 : 4 ) ) {
        push @d, reverse @r_data;
        return \@d;
    }

    # left edge, unflipped
    if ( $orient == ( $ccw ? 4 : 7 ) ) {
        push @d, [ reverse @$_ ] foreach reverse @r_data;
        return \@d;
    }

    die "Unsupported orientation value $orient";
};

# my $i = 0;
# my $test_tile = [ map { [ map { $i++ } ( 0 .. 9 ) ] } ( 0 .. 9 ) ];
# use Data::Dumper;
# die Dumper $rotate_data->( $test_tile, 3, 1 )->[0];

# Finally, assemble the tile data onto a 2D grid, using
# our index of positions and our tile orientation data.
my @image_tiles;

my $sort_pos = sub {
    my ( $p, $q ) = ( [ split ',', $a ], [ split ',', $b ] );
    return ( $p->[1] <=> $q->[1] ) || ( $p->[0] <=> $q->[0] );
};

foreach my $p ( sort $sort_pos keys %pos_tile ) {
    my ( $x, $y ) = split ',', $p;
    $image_tiles[$y] //= [];

    my $t_id = $pos_tile{$p};
    my $t_data = $tiles{$t_id};
    my $t_orient = $orientation{$t_id};

    push @{ $image_tiles[$y] }, $rotate_data->( $t_data, $t_orient, $x + $y );
}

# Flatten the data into one giant tile.
my @image_grid;

for ( my $j=0; $j < @image_tiles; $j++ ) {
    for ( my $i=0; $i < @image_tiles; $i++ ) {
        my $t = $image_tiles[$j]->[$i];

        for ( my $y=0; $y < @$t; $y++ ) {
            for ( my $x=0; $x < @$t; $x++ ) {
                my $r = $y + $j * scalar @$t;
                $image_grid[$r] //= [];
                push @{ $image_grid[$r] }, $t->[$y]->[$x];
            }
        }
    }
}

# print join( '', @$_ ) . "\n" foreach @image_grid;

# Can we look for sea monsters now?

my $m_tile = q/
                  #
#    ##    ##    ###
 #  #  #  #  #  #
/;

# The quickest and most efficient choice is probably to code this as a regex.

my $search_grid = sub {
    my ( $grid ) = @_;
    my $matches = 0;

    my @monster_pat = (
        qr/^(?:.){18}#/,
        qr/^#(?:.){4}##(?:.){4}##(?:.){4}###/,
        qr/^(?:.)#(?:.){2}#(?:.){2}#(?:.){2}#(?:.){2}#(?:.){2}#/,
    );
    my $monster_length = 20;
    my $monster_height = 3;

    for ( my $j = 0; $j <= scalar @$grid - $monster_height; $j++ ) {
        for ( my $i = 0; $i <= scalar @$grid - $monster_length; $i++ ) {
            my $ok = 1;

            foreach ( 0..2 ) {
                my $l = substr join( '', @{ $grid->[ $j + $_ ] } ), $i;
                my $p = $monster_pat[$_];
                $ok &&= ( $l =~ /$p/ );
            }

            $matches += $ok;
        }
    }
    return $matches;
};

# We also have to count ALL the octothorps in the grid.
my $o_monster = scalar grep { $_ eq '#' } split '', $m_tile;
my $o_grid = scalar grep { $_ eq '#' } map { @$_ } map { @$_ } values %tiles;

my @num_monsters;

foreach my $o ( 1 .. 8 ) {
    my $d = $rotate_data->( \@image_grid, $o, 0 );
    push @num_monsters, $search_grid->($d);
}

my $roughness = $o_grid - ( $o_monster * [ sort { $b <=> $a } @num_monsters ]->[0] );

printf "Part 2: %s\n", $roughness;
