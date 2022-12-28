#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 19
# https://adventofcode.com/2022/day/19

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# Blueprint 1: Each ore robot costs 4 ore. Each clay robot costs 2 ore. Each obsidian robot costs 3 ore and 14 clay. Each geode robot costs 2 ore and 7 obsidian.
# Blueprint 2: Each ore robot costs 2 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 8 clay. Each geode robot costs 3 ore and 12 obsidian.
# );
# @lines = grep { length $_ } split "\n", $lines;

my %blueprints;

my $parse_lines = sub {
    my ( $l ) = @_;
    my ( $idnum ) = ( $l =~ /^Blueprint (\d+):/ );
    my $r_pat = qr/Each (\w+) robot costs ([^.]+)\./;

    while ( $l =~ /$r_pat/g ) {
        my ( $type, $recipe ) = ( $1, $2 );
        my ( @cost ) = split ' and ', $recipe;  # max 2 elements per recipe

        foreach (@cost) {
            my ( $num, $thing ) = split / /;
            $blueprints{$idnum}->{$type}->{$thing} = $num;
        }
    }
};

$parse_lines->($_) foreach @lines;

my @types = qw( ore clay obsidian geode ); # list in order of complexity

# Calculate the maximum possible robot cost for each material.
my %max_cost;

foreach my $idnum ( keys %blueprints ) {
    foreach my $t ( @types ) {
        next if $t eq 'geode';
        my $max = 0;
        foreach my $r ( keys %{ $blueprints{$idnum} } ) {
            my $c = $blueprints{$idnum}->{$r}->{$t} // 0;
            $max = $c unless $c < $max;
        }
        $max_cost{$idnum}->{$t} = $max;
    }
    $max_cost{$idnum}->{geode} = 999999999999999;  # we always need more geodes
}

my $can_make = sub {
    my ( $idnum, $type, $resources, $robots, $minutes_left ) = @_;

    # Never try to make a robot that we have as many of as we need
    # to cover any possible cost of that resource in one minute,
    # because we can only build one robot per minute.
    return if ( $robots->{$type} // 0 ) >= $max_cost{$idnum}->{$type};

    # this one weird trick reduced my computation time by about 30%
    # https://www.reddit.com/r/adventofcode/comments/zpy5rm/2022_day_19_what_are_your_insights_and/
    if ( defined $minutes_left && $type ne 'geode' ) {
        if ( my $x = $robots->{$type} // 0 ) {
            my $y = $resources->{$type} // 0;
            my $z = $max_cost{$idnum}->{$type};
            return if $x * $minutes_left + $y >= $minutes_left * $z;
        }
    }

    # Do we have the resources we need?
    my $cost = $blueprints{$idnum}->{$type};
    my $ok = 1;
    foreach ( keys %$cost ) {
        $ok &&= ( $resources->{$_} // 0 ) >= $cost->{$_};
        die "Can't have negative resources!"
            if exists $resources->{$_} && $resources->{$_} < 0;
    }
    return $type if $ok;
};

my $build_robot = sub {
    my ( $idnum, $type, $resources, $robots ) = @_;
    return unless $can_make->( $idnum, $type, $resources, $robots );

    # pay the cost
    my $cost = $blueprints{$idnum}->{$type};
    $resources->{$_} -= $cost->{$_} foreach keys %$cost;

    # do the production step
    while ( my ( $type, $num ) = each %$robots ) {
        $resources->{$type} += $num;
    }

    # robot is ready
    $robots->{$type}++;
};

# From here on this is heavily adapted from a solution seen on Reddit.
# I simply couldn't figure out an algorithm that would consistently
# yield the same results I was seeing in the examples without using
# a brute-force, "try every solution" approach like this.

my $skey = sub {
    my ( $resources, $robots, $time ) = @_;
    my $s_re = join ',', map { $_, $resources->{$_} // 0 } @types;
    my $s_rb = join ',', map { $_, $robots->{$_} // 0 } @types;
    return join '|', $s_re, $s_rb, $time;
};

my $calc_path = sub {
    my ( $idnum, $minutes_left ) = @_;
    my @paths = ( [ {}, { ore => 1 }, $minutes_left - 1 ] );  # initial values
    my %seen;
    my $best = 0;

    while ( my $p = pop @paths ) {
        my ( $resources, $robots ) = ( { %{ $p->[0] } }, { %{ $p->[1] } } );
        $minutes_left = $p->[2];
        # "throw away goods if they are too high so that loop will be caught by the seen filter"
        # ??? I know this means deduplicating paths with meaningless extra resources,
        # but I'm not clear on the math behind this particular calculation
        foreach my $t ( @types[0..2] ) {
            my $cap = 2 * $max_cost{$idnum}->{$t} - 2;
            $resources->{$t} = $cap if ( $resources->{$t} // 0 ) > $cap;
        }
        next if $seen{ $skey->( $resources, $robots, $minutes_left ) }++;

        # if we can't possibly beat our best, abandon this path
        my ( $g_res, $g_rob ) = ( $resources->{ geode } // 0, $robots->{ geode } // 0 );
        for ( my $g = $minutes_left; $g >= 0; $g-- ) {
            $g_res += $g_rob++;  # if we could create another geode robot every turn
        }
        next if $g_res <= $best;

        if ( $can_make->( $idnum, $types[3], $resources, $robots, $minutes_left ) ) {
            ( $resources, $robots ) = ( {%$resources}, {%$robots} );
            $build_robot->( $idnum, $types[3], $resources, $robots );
            push @paths, [ $resources, $robots, $minutes_left - 1 ] if $minutes_left > 0;
        } else {
            foreach my $t ( @types[0..2] ) {
                if ( $can_make->( $idnum, $t, $resources, $robots, $minutes_left ) ) {
                    my ( $newres, $newrob ) = ( {%$resources}, {%$robots} );
                    $build_robot->( $idnum, $t, $newres, $newrob );
                    push @paths, [ $newres, $newrob, $minutes_left - 1 ] if $minutes_left > 0;
                }
            }
            # production step (the "do nothing" choice)
            while ( my ( $type, $num ) = each %$robots ) {
                $resources->{$type} += $num;
            }
            push @paths, [ $resources, $robots, $minutes_left - 1 ] if $minutes_left > 0;
        }
        $best = $resources->{ $types[3] } if ( $resources->{ $types[3] } // 0 ) > $best;
    }
    return $best;
};

my $quality_sum = 0;

foreach my $idnum ( sort { $a <=> $b } keys %blueprints ) {
    my $best = $calc_path->( $idnum, 24 );
    warn "Best for $idnum is $best.\n";
    $quality_sum += $idnum * $best;
}

printf "\nPart 1: %s\n\n", $quality_sum;


delete $blueprints{$_} foreach ( 4 .. scalar keys %blueprints );  # hungry elephant

my $total32 = 1;

foreach my $idnum ( sort { $a <=> $b } keys %blueprints ) {
    my $best = $calc_path->( $idnum, 32 );
    warn "Best for $idnum is $best.\n";
    $total32 *= $best;
}

printf "\nPart 2: %s\n", $total32;

# elapsed time: approx. 43 seconds for both parts together
#
# thx https://topaz.github.io/paste/#XQAAAQDJCQAAAAAAAAARiEJHiiMzw3cPM/1YYwym2CY2IxGBOKs1Dxh4qS2HaIkyEn4Lip1JtzxLSyEXQFgRdnT0oTjrZKlAJsae15zsmSOiHV9g7l0MGjFi2qz8XgfK3njrl2R9nLpgjpmbD0HySVHY8L/bnR53OjoycsV9HM3fnC1FGEPeSKdqLq25N4JxRoXqTeAz+Z28cUs+x5ksmjEtTekgGtMjJqyff84ZM/2Vc4i6RjIHKv/jGw+M4zJ7G1srOBbesD78B7/eVju11QLRNZFwEHaiSsvH0K4ubeE+SiVOHPprHpZ5yl2n5X+7+mkWeQg+0dEsKUkhfXWTei0CYjk4BVnF5TMtsqiP703LsIytlOrcHMkoH2fuj4L8GF/ttKqmD8flVUmE7HQyH6bfZGd7GgRzugQmdTiMHZczP60Cy1ktXya60VQkILZxOBoAePfSkdXZ7jDu4fMPfXbKy+RVOFhSVAVyZUAdq6j81zVnECf66Qqja96VAXOsdte0HXLmIxqWDdeKHFV2Q1VP7QTrk1AGoy1v9430UwXyEXo41O7PEn2N9fnvS2D+qEkX4KvpiLWwNqwZ611lunWGYljZwk2NsjWscqkG4GJmPlPyaHkv4xM7EQ3MULa2Tqp70OjxXrNQU4Gdi4gh22OWXh+/b4+Y7z+WdJ23isXoeLUDojSWGSa4UT9B00u63MTuCC5dqysZqo+Xv3uXl6ZfllKkrUiQ3TgM4iBJO9xdG+aEQjxvyfKlqkOBOW2isiqpFst/VX8kTKEHooiQ8KyPsDhRmADYQR1RXaS8MG5vudR5u/FJJ0QvMLlXxEGU4bSjHkd8GmsAleW/9EyLeydsYMsAOM5tKuSslhxjwumzpbnePi1SWriMNcjjCMrFTlqMr5Lk24GlJsbP0syYOOEoZtB7nNnZbWglLoaQB9bZakjUOqeGLOku6I/YID89yEz8fcTbZsOjMH0Jvu8YmnORF74PFJf0p6mb9zgZZK0qdJdnZLft3nPDIPvCXegB/2sBBzf6Mh80uOrHm5kpQa8YWpNR2qAeejgfdhJc8OX1UAmVvXWILK6wTgjXVrjw+RhdciW0dXpB5JBhQsqzuCEQGioGDnAWqo/qV5YHn8Chzx8lZAHfghucuUFyeRTqs5vZmy0MFemEPROFwUvWgsMNMDUjUtH9j8OqXhVj3UkZSQaczZZCSCEP3kwAdtgFILk6I3LV+iUj5nQkhr4KOAcDqnV856SfIXLBbOMGifXbQIzexJ8nqy8p5wY0vgW8Y5xVzf/6fWI0
