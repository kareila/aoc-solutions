#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 18
# https://adventofcode.com/2021/day/18

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# [1,2]
# [[1,2],3]
# [9,[8,7]]
# [[1,9],[8,5]]
# [[[[1,2],[3,4]],[[5,6],[7,8]]],9]
# [[[9,[3,8]],[[0,9],6]],[[[3,7],[4,9]],3]]
# [[[[1,3],[5,3]],[[1,3],[8,7]]],[[[4,9],[6,9]],[[8,2],[7,3]]]]
#
# explode examples:
# [[[[[9,8],1],2],3],4]
# [7,[6,[5,[4,[3,2]]]]]
# [[6,[5,[4,[3,2]]]],1]
# [[3,[2,[1,[7,3]]]],[6,[5,[4,[3,2]]]]]
# [[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]
#
# split examples:
# [[[[0,7],4],[15,[0,13]]],[1,1]]
# [[[[0,7],4],[[7,8],[0,13]]],[1,1]]
# [[[[7,8],[6,7]],[[6,8],[0,8]]],[[9,[5,10]],[[5,0],[5,6]]]]
#
# "slightly larger" example:
# [[[0,[4,5]],[0,0]],[[[4,5],[2,6]],[9,5]]]
# [7,[[[3,7],[4,3]],[[6,3],[8,8]]]]
# [[2,[[0,8],[3,4]]],[[[6,7],1],[7,[1,6]]]]
# [[[[2,4],7],[6,[0,5]]],[[[6,8],[2,8]],[[2,1],[4,5]]]]
# [7,[5,[[3,8],[1,4]]]]
# [[2,[2,2]],[8,[8,1]]]
# [2,9]
# [1,[[[9,3],9],[[9,0],[0,7]]]]
# [[[5,[7,4]],7],1]
# [[[[4,2],2],6],[8,7]]
#
# my $lines = q(
# [[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]
# [[[5,[2,8]],4],[5,[[9,9],0]]]
# [6,[[[6,2],[5,6]],[[7,6],[4,7]]]]
# [[[6,[0,7]],[0,9]],[4,[9,[9,0]]]]
# [[[7,[6,4]],[3,[1,3]]],[[[5,5],1],9]]
# [[6,[[7,3],[3,2]]],[[[3,8],[5,7]],4]]
# [[[[5,4],[7,7]],8],[[8,3],8]]
# [[9,3],[[9,9],[6,[4,9]]]]
# [[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]
# [[[[5,2],5],[8,[3,7]]],[[5,[7,5]],[4,4]]]
# );
# @lines = grep { length $_ } split "\n", $lines;

my $parse_line = sub {
    my @elements = split ',', $_[0];
    my @p = [];  # top level

    foreach ( @elements ) {
        my @c = split '';

        while ( $c[0] eq '[' ) {
            shift @c;
            push @p, [];  # add another level
        }

        # numeric string accumulator
        my $n = '';

        while ( @c && $c[0] ne ']' ) {
            $n .= shift @c;
        }

        # did we find a number value?
        push @{ $p[-1] }, $n + 0 if length $n;

        # anything left must be closing brackets
        while ( @c ) {
            shift @c;
            my $d = pop @p;         # close the current level...
            push @{ $p[-1] }, $d;   # ...and add it to the parent level
        }
    }
    return @{ $p[0] };  # ta-da!
};

my $do_explodes = sub {
    my ( $p ) = @_;
    my ( $pl, $pr ) = @$p;

    # we don't need to handle arbitrary structures - these are all pairs at some level
    my @stack_left;
    my @stack_right;

    # work from left to right
    my $drill_down = sub {
        until ( ! ref $pl && ! ref $pr ) {
            if ( ref $pl ) {
                push @stack_left, undef;
                push @stack_right, $pr;
                ( $pl, $pr ) = @$pl;
            } else {
                push @stack_left, $pl;
                push @stack_right, undef;
                ( $pl, $pr ) = @$pr;
            }
        }
    };

    $drill_down->();

    MAIN:
    while ( @stack_right ) {
        if ( scalar @stack_right == 4 ) {
            # need to explode
            my $explode = { left => $pl, right => $pr };
            my $new_p = 0;

            my $propagate = sub {
                my ( $dir ) = @_;
                return unless exists $explode->{$dir};

                my $ni = ( $dir eq 'left' ? 0 : 1 );
                my $fi = ( $dir eq 'left' ? 1 : 0 );

                if ( ref $new_p->[$ni] ) {
                    my $find_r = $new_p->[$ni];
                    $find_r = $find_r->[$fi] until ( ! ref $find_r->[$fi] );
                    $find_r->[$fi] += $explode->{$dir};
                } else {
                    $new_p->[$ni] += $explode->{$dir};
                }
                delete $explode->{$dir};
            };

            while ( @stack_left ) {
                my $prev_p = [ pop @stack_left, pop @stack_right ];
                if ( defined $prev_p->[0] ) {
                    $new_p = [ $prev_p->[0], $new_p ];
                    $propagate->('left');
                } else {
                    $new_p = [ $new_p, $prev_p->[1] ];
                    $propagate->('right');
                }
            }
            return $new_p;

        } else {
            my $new_p = [ $pl, $pr ];
            while ( @stack_left ) {
                my $prev_p = [ pop @stack_left, pop @stack_right ];
                if ( defined $prev_p->[0] ) {
                    $new_p = [ $prev_p->[0], $new_p ];
                    # no need to examine left values, we're working left to right
                } else {
                    $new_p = [ $new_p, $prev_p->[1] ];

                    if ( ref $new_p->[1] ) {
                        push @stack_left, $new_p->[0];
                        push @stack_right, undef;
                        ( $pl, $pr ) = @{ $new_p->[1] };

                        $drill_down->();
                        next MAIN;
                    }
                }
            }
            return;  # nothing changed
        }
    }
};

my $do_splits = sub {
    my ( $p ) = @_;
    my ( $pl, $pr ) = @$p;

    # we don't need to handle arbitrary structures - these are all pairs at some level
    my @stack_left;
    my @stack_right;

    # work from left to right
    my $next_left = sub {
        until ( ! ref $pl ) {
            push @stack_left, undef;
            push @stack_right, $pr;
            ( $pl, $pr ) = @$pl;
        }
    };

    $next_left->();

    MAIN:
    while ( 1 ) {  # split values can be at the top level
        if ( ! ref $pl && $pl >= 10 || ! ref $pr && $pr >= 10 ) {
            # need to split
            my $split = sub {
                my ( $num ) = @_;
                my $half = int( $num / 2 );
                return [ $half, $num - $half ];
            };

            if ( ! ref $pl && $pl >= 10 ) {  # left before right
                $pl = $split->($pl);
            } else {
                $pr = $split->($pr);
            }

            my $new_p = [ $pl, $pr ];
            while ( @stack_left ) {
                my $prev_p = [ pop @stack_left, pop @stack_right ];
                if ( defined $prev_p->[0] ) {
                    $new_p = [ $prev_p->[0], $new_p ];
                } else {
                    $new_p = [ $new_p, $prev_p->[1] ];
                }
            }
            return $new_p;

        } else {
            # before popping the stack, check $pr for refs
            if ( ref $pr ) {
                push @stack_left, $pl;
                push @stack_right, undef;
                ( $pl, $pr ) = @$pr;

                $next_left->();
                next MAIN;
            }

            my $new_p = [ $pl, $pr ];
            while ( @stack_left ) {
                my $prev_p = [ pop @stack_left, pop @stack_right ];
                if ( defined $prev_p->[0] ) {
                    $new_p = [ $prev_p->[0], $new_p ];
                    # no need to examine left values, we're working left to right
                } else {
                    $new_p = [ $new_p, $prev_p->[1] ];

                    if ( ref $new_p->[1] ) {
                        push @stack_left, $new_p->[0];
                        push @stack_right, undef;
                        ( $pl, $pr ) = @{ $new_p->[1] };

                        $next_left->();
                        next MAIN;
                    }

                    if ( $new_p->[1] >= 10 ) {
                        ( $pl, $pr ) = @{ $new_p };
                        next MAIN;
                    }
                }
            }
            return;  # nothing changed
        }
    }
};

sub reduce {
    no warnings 'recursion';  # hush
    my ( $s_number ) = @_;

    my $s_exploded = $do_explodes->( $s_number );
    while ( defined $s_exploded ) {
        $s_number = $s_exploded;
        $s_exploded = $do_explodes->( $s_number );
        # using this while loop reduces the amount of recursion needed
    }

    my $s_split = $do_splits->( $s_number );
    return reduce( $s_split ) if defined $s_split;

    return $s_number;  # already reduced
}

sub magnitude {
    my ( $p ) = @_;
    my ( $pl, $pr ) = @$p;

    if ( ref $pl ) {
        if ( ref $pr ) {
            return 3 * magnitude($pl) + 2 * magnitude($pr);
        } else {
            return 3 * magnitude($pl) + 2 * $pr;
        }
    } else {
        if ( ref $pr ) {
            return 3 * $pl + 2 * magnitude($pr);
        } else {
            return 3 * $pl + 2 * $pr;
        }
    }
}

my @pairs = map { $parse_line->($_) } @lines;
my $result = shift @pairs;

while (@pairs) {
    $result = reduce( [ $result, shift @pairs ] );
}

printf "Part 1: %s\n", magnitude( $result );


# check all x+y and y+x and note the max magnitude
my $max_magnitude = 0;

# need to be careful here, since reduce modifies its arguments.....
# using the standard Clone.pm here avoids parsing @lines into @pairs on every loop
use Clone qw(clone);
@pairs = map { $parse_line->($_) } @lines;

for ( my $i=0; $i < @lines; $i++ ) {
    for ( my $j=0; $j < @lines; $j++ ) {
        next if $i == $j;  # only add different numbers
        my $wpairs = clone(\@pairs);
        my $m = magnitude( reduce( [ $wpairs->[$i], $wpairs->[$j] ] ) );
        $max_magnitude = $m if $m > $max_magnitude;
    }
}

printf "Part 2: %s\n", $max_magnitude;

# elapsed time: approx. 15 sec for both parts together, or 10 sec if using Clone
# (I decided to allow it since it's a standard module that doesn't require CPAN)
