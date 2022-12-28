#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 22
# https://adventofcode.com/2022/day/22

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
#         ...#
#         .#..
#         #...
#         ....
# ...#.......#
# ........#...
# ..#....#....
# ..........#.
#         ...#....
#         .....#..
#         .#......
#         ......#.
#
# 10R5L5R10L4R5L5
# );
# @lines = grep { length $_ } split "\n", $lines;

# Shape of actual data, reduced to 4x4 faces:
# my $lines = q(
#     ........
#     ........
#     ........
#     ........
#     ....
#     ....
#     ....
#     ....
# ........
# ........
# ........
# ........
# ....
# ....
# ....
# ....
#
# 10R5L5R10L4R5L5
# );
# @lines = grep { length $_ } split "\n", $lines;

my @steps;

{
    my $path = pop @lines;
    while ( $path !~ /^\d+$/ ) {
        my @next = ( $path =~ /^(\d+)([LR])/ );
        push @steps, @next;

        my $len = length join '', @next;
        $path = substr $path, $len;
    }
    push @steps, $path;
}

my @rows;
my %pos;

my $init_rows = sub {
    @rows = ();
    push @rows, [ split '' ] foreach @lines;
    # initial position
    %pos = ( facing => 0, 'y' => 0, 'x' => index $lines[0], '.' );
};

my $set_value = sub {
    my ( $x, $y, $v ) = @_;
    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
    $rows[$y]->[$x] = $v;
};  # only used in debugging (for current position display)

my $point_value = sub {
    my ( $x, $y ) = @_;
    # modify to return a space character instead of undef for this use case
    return ' ' if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
    return ' ' unless $rows[$y];     # ugh, this would auto-vivify an empty row
    return $rows[$y]->[$x] // ' ';
};

my $do_turn = sub {
    my ( $dir ) = @_;
    my $f = $pos{facing};

    if ( $dir eq 'R' ) {
        $f += ( $f == 3 ) ? -3 : 1;
    } else {
        $f -= ( $f == 0 ) ? -3 : 1;
    }

    $pos{facing} = $f;
};

my $search_right = sub {
    my ( $y ) = @_;

    for ( my $i = 0; $i < scalar @{ $rows[$y] } - 1; $i++ ) {
        next if $point_value->( $i, $y ) eq ' ';
        return do_step( $i, $y );
    }
};

my $search_left = sub {
    my ( $y ) = @_;

    for ( my $i = scalar @{ $rows[$y] } - 1; $i > 0; $i-- ) {
        next if $point_value->( $i, $y ) eq ' ';
        return do_step( $i, $y );
    }
};

my $search_down = sub {
    my ( $x ) = @_;

    for ( my $j = 0; $j < scalar @rows - 1; $j++ ) {
        next if $point_value->( $x, $j ) eq ' ';
        return do_step( $x, $j );
    }
};

my $search_up = sub {
    my ( $x ) = @_;

    for ( my $j = scalar @rows - 1; $j > 0; $j-- ) {
        next if $point_value->( $x, $j ) eq ' ';
        return do_step( $x, $j );
    }
};

# no arguments: based on position, not destination
my $wrap_around = sub {
    # facing right: find the first tile to the right of x=0
    return $search_right->( $pos{'y'} ) if $pos{facing} == 0;

    # facing left: find the first tile to the left of x=max
    return $search_left->( $pos{'y'} ) if $pos{facing} == 2;

    # facing down: find the first tile below y=0
    return $search_down->( $pos{'x'} ) if $pos{facing} == 1;

    # facing up: find the first tile above y=max
    return $search_up->( $pos{'x'} ) if $pos{facing} == 3;

    die "What is this even?";
};

sub do_step {
    my ( $x, $y ) = @_;
    return 0 if $point_value->( $x, $y ) eq '#';

    if ( $point_value->( $x, $y ) eq '.' ) {
        $pos{'x'} = $x;
        $pos{'y'} = $y;
        return 1;
    }

    # In Part 2, wrap_around can change facing, so make sure we moved...
    my $f = $pos{facing};
    if ( $wrap_around->() ) {
        return 1;
    } else {
        $pos{facing} = $f;
        return 0;
    }
}

my $do_walk = sub {
    my ( $n ) = @_;
    my ( $x, $y );

    foreach ( 1 .. $n ) {
        ( $x, $y ) = ( $pos{'x'} + 1, $pos{'y'} + 0 ) if $pos{facing} == 0;
        ( $x, $y ) = ( $pos{'x'} + 0, $pos{'y'} + 1 ) if $pos{facing} == 1;
        ( $x, $y ) = ( $pos{'x'} - 1, $pos{'y'} - 0 ) if $pos{facing} == 2;
        ( $x, $y ) = ( $pos{'x'} - 0, $pos{'y'} - 1 ) if $pos{facing} == 3;

        last unless do_step( $x, $y );
    }
};

my $follow_steps = sub {
    foreach my $p ( @steps ) {
        if ( $p =~ /^\d+$/ ) {
            $do_walk->($p);
        } else {
            $do_turn->($p);
        }
    }
};

my $show_position_and_exit = sub {
    my $self = { 0 => '>', 1 => 'v', 2 => '<', 3 => '^' }->{ $pos{facing} };
    $set_value->( $pos{'x'}, $pos{'y'}, $self );
    print sprintf "%s\n", join "\n", map { join '', @$_ } @rows;
    die "\n";
};

$init_rows->();
$follow_steps->();
# $show_position_and_exit->();

my $password = sub { 1000 * ( $pos{'y'} + 1 ) + 4 * ( $pos{'x'} + 1 ) + $pos{facing} };

printf "Part 1: %s\n", $password->();


# Ugh, we have to fold the grid into a cube...

my $face_size = 50;

# I could put a lot of time and thought into a general cube-detection procedure,
# but on second thought, let's just get this done - keeping in mind the example
# and real data will have different edge mappings.

# $face_size = 4; # for the example
#
# $wrap_around = sub {
#     # Let's assume, if we're here, that we already know we're on an edge.
#
#     # process all right edges from top to bottom
#     if ( $pos{facing} == 0 ) {
#
#         # right edge of face 1 (row 1) goes to right edge of face 6 (row 3)
#         if ( $pos{'y'} < $face_size ) {  # row 1
#             $pos{facing} = 2;
#             my $j = ( 3 * $face_size - 1 ) - ( $pos{'y'} % $face_size );
#             return $search_left->($j);
#         }
#
#         # right edge of face 4 (row 2) goes to top edge of face 6 (col 4)
#         if ( $pos{'y'} < 2 * $face_size ) {  # row 2
#             $pos{facing} = 1;
#             my $i = ( 4 * $face_size - 1 ) - ( $pos{'y'} % $face_size );
#             return $search_down->($i);
#         }
#
#         # right edge of face 6 (row 3) goes to right edge of face 1 (row 1)
#         if ( $pos{'y'} < 3 * $face_size ) {  # row 3
#             $pos{facing} = 2;
#             my $j = ( $face_size - 1 ) - ( $pos{'y'} % $face_size );
#             return $search_left->($j);
#         }
#     }
#
#     # process all top edges from left to right
#     if ( $pos{facing} == 3 ) {
#
#         # top edge of face 2 (col 1) goes to top edge of face 1 (col 3)
#         if ( $pos{'x'} < $face_size ) {  # col 1
#             $pos{facing} = 1;
#             my $i = ( 3 * $face_size - 1 ) - ( $pos{'x'} % $face_size );
#             return $search_down->($i);
#         }
#
#         # top edge of face 3 (col 2) goes to left edge of face 1 (row 1)
#         if ( $pos{'x'} < 2 * $face_size ) {  # col 2
#             $pos{facing} = 0;
#             my $j = $pos{'x'} - $face_size;
#             return $search_right->($j);
#         }
#
#         # top edge of face 1 (col 3) goes to top edge of face 2 (col 1)
#         if ( $pos{'x'} < 3 * $face_size ) {  # col 3
#             $pos{facing} = 1;
#             my $i = ( $face_size - 1 ) - ( $pos{'x'} % $face_size );
#             return $search_down->($i);
#         }
#
#         # top edge of face 6 (col 4) goes to right edge of face 4 (row 2)
#         if ( $pos{'x'} < 4 * $face_size ) {  # col 4
#             $pos{facing} = 2;
#             my $j = ( 2 * $face_size - 1 ) - ( $pos{'x'} % $face_size );
#             return $search_left->($j);
#         }
#     }
#
#     # process all left edges from top to bottom
#     if ( $pos{facing} == 2 ) {
#
#         # left edge of face 1 (row 1) goes to top edge of face 3 (col 2)
#         if ( $pos{'y'} < $face_size ) {  # row 1
#             $pos{facing} = 1;
#             my $i = $pos{'y'} + $face_size;  # +1 to go from row 1 to col 2
#             return $search_down->($i);
#         }
#
#         # left edge of face 2 (row 2) goes to bottom edge of face 6 (col 4)
#         if ( $pos{'y'} < 2 * $face_size ) {  # row 2
#             $pos{facing} = 3;
#             my $i = ( 4 * $face_size - 1 ) - ( $pos{'y'} % $face_size );
#             return $search_up->($i);
#         }
#
#         # left edge of face 5 (row 3) goes to bottom edge of face 3 (col 2)
#         if ( $pos{'y'} < 3 * $face_size ) {  # row 3
#             $pos{facing} = 3;
#             my $i = ( 2 * $face_size - 1 ) - ( $pos{'y'} % $face_size );
#             return $search_up->($i);
#         }
#     }
#
#     # process all bottom edges from left to right
#     if ( $pos{facing} == 1 ) {
#
#         # bottom edge of face 2 (col 1) goes to bottom edge of face 5 (col 3)
#         if ( $pos{'x'} < $face_size ) {  # col 1
#             $pos{facing} = 3;
#             my $i = ( 3 * $face_size - 1 ) - ( $pos{'x'} % $face_size );
#             return $search_up->($i);
#         }
#
#         # bottom edge of face 3 (col 2) goes to left edge of face 5 (col 3)
#         if ( $pos{'x'} < 2 * $face_size ) {  # col 2
#             $pos{facing} = 0;
#             my $j = ( 3 * $face_size - 1 ) - ( $pos{'x'} % $face_size );
#             return $search_right->($j);
#         }
#
#         # bottom edge of face 5 (col 3) goes to bottom edge of face 2 (col 1)
#         if ( $pos{'x'} < 3 * $face_size ) {  # col 3
#             $pos{facing} = 3;
#             my $i = ( $face_size - 1 ) - ( $pos{'x'} % $face_size );
#             return $search_up->($i);
#         }
#
#         # bottom edge of face 6 (col 4) goes to left edge of face 2 (row 2)
#         if ( $pos{'x'} < 4 * $face_size ) {  # col 4
#             $pos{facing} = 0;
#             my $j = ( 2 * $face_size - 1 ) - ( $pos{'x'} % $face_size );
#             return $search_right->($j);
#         }
#     }
#
#     die "What is this even?";
# };
#
# Following steps gives password of 5031: confirmed correct for example, at least...

# $face_size = 4; # for the example

$wrap_around = sub {
    # Let's assume, if we're here, that we already know we're on an edge.

    # process all right edges from top to bottom
    if ( $pos{facing} == 0 ) {

        # right edge of row 1 goes to right edge of row 3
        if ( $pos{'y'} < $face_size ) {  # row 1
            $pos{facing} = 2;
            my $j = ( 3 * $face_size - 1 ) - ( $pos{'y'} % $face_size );
            return $search_left->($j);
        }

        # right edge of row 2 goes to bottom edge of col 3
        if ( $pos{'y'} < 2 * $face_size ) {  # row 2
            $pos{facing} = 3;
            my $i = $pos{'y'} + $face_size;  # +1 to go from row 2 to col 3
            return $search_up->($i);
        }

        # right edge of row 3 goes to right edge of row 1
        if ( $pos{'y'} < 3 * $face_size ) {  # row 3
            $pos{facing} = 2;
            my $j = ( $face_size - 1 ) - ( $pos{'y'} % $face_size );
            return $search_left->($j);
        }

        # right edge of row 4 goes to bottom edge of col 2
        if ( $pos{'y'} < 4 * $face_size ) {  # row 4
            $pos{facing} = 3;
            my $i = $pos{'y'} - 2 * $face_size;  # -2 to go from row 4 to col 2
            return $search_up->($i);
        }
    }

    # process all top edges from left to right
    if ( $pos{facing} == 3 ) {

        # top edge of col 1 goes to left edge of row 2
        if ( $pos{'x'} < $face_size ) {  # col 1
            $pos{facing} = 0;
            my $j = $pos{'x'} + $face_size;
            return $search_right->($j);
        }

        # top edge of col 2 goes to left edge of row 4
        if ( $pos{'x'} < 2 * $face_size ) {  # col 2
            $pos{facing} = 0;
            my $j = $pos{'x'} + 2 * $face_size;
            return $search_right->($j);
        }

        # top edge of col 3 goes to bottom edge of col 1
        if ( $pos{'x'} < 3 * $face_size ) {  # col 3
            $pos{facing} = 3;  # yes, really
            my $i = $pos{'x'} - 2 * $face_size;
            return $search_up->($i);
        }
    }

    # process all left edges from top to bottom
    if ( $pos{facing} == 2 ) {

        # left edge of row 1 goes to left edge of row 3
        if ( $pos{'y'} < $face_size ) {  # row 1
            $pos{facing} = 0;
            my $j = ( 3 * $face_size - 1 ) - ( $pos{'y'} % $face_size );
            return $search_right->($j);
        }

        # left edge of row 2 goes to top edge of col 1
        if ( $pos{'y'} < 2 * $face_size ) {  # row 2
            $pos{facing} = 1;
            my $i = $pos{'y'} - $face_size;
            return $search_down->($i);
        }

        # left edge of row 3 goes to left edge of row 1
        if ( $pos{'y'} < 3 * $face_size ) {  # row 3
            $pos{facing} = 0;
            my $j = ( $face_size - 1 ) - ( $pos{'y'} % $face_size );
            return $search_right->($j);
        }

        # left edge of row 4 goes to top edge of col 2
        if ( $pos{'y'} < 4 * $face_size ) {  # row 4
            $pos{facing} = 1;
            my $i = $pos{'y'} - 2 * $face_size;  # -2 to go from row 4 to col 2
            return $search_down->($i);
        }
    }

    # process all bottom edges from left to right
    if ( $pos{facing} == 1 ) {

        # bottom edge of col 1 goes to top edge of col 3
        if ( $pos{'x'} < $face_size ) {  # col 1
            $pos{facing} = 1;  # yes, really
            my $i = $pos{'x'} + 2 * $face_size;
            return $search_down->($i);
        }

        # bottom edge of col 2 goes to right edge of row 4
        if ( $pos{'x'} < 2 * $face_size ) {  # col 2
            $pos{facing} = 2;
            my $j = $pos{'x'} + 2 * $face_size;  # +2 to go from col 2 to row 4
            return $search_left->($j);
        }

        # bottom edge of col 3 goes to right edge of row 2
        if ( $pos{'x'} < 3 * $face_size ) {  # col 3
            $pos{facing} = 2;
            my $j = $pos{'x'} - $face_size;  # -1 to go from col 3 to row 2
            return $search_left->($j);
        }
    }

    die "What is this even?";
};

$init_rows->();  # resets %pos
$follow_steps->();

printf "Part 2: %s\n", $password->();
