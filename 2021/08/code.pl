#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 8
# https://adventofcode.com/2021/day/8

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = qq/
# be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
# edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
# fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
# fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
# aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
# fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
# dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
# bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
# egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
# gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
# /;
# @lines = grep { length $_ } split "\n", $lines;

# note which digits contain which segments
my %digits = qw( 0 abcefg 1 cf 2 acdeg 3 acdfg 4 bcdf 5 abdfg 6 abdefg 7 acf 8 abcdefg 9 abcdfg );

# now try parsing input, noting that segment ordering is random

my $sort_segment = sub {
    return join '', sort( split '', $_[0] );
};

my $total_pt1 = 0;
my $total_pt2 = 0;

foreach my $l (@lines) {
    my ( $pats, $vals ) = split / [|] /, $l;

    my @segs = map { $sort_segment->($_) } split ' ', $pats;

    my %garbled;
    my %unique_lengths = qw( 2 1 3 7 4 4 7 8 );

    foreach my $s (@segs) {
        if ( my $u = $unique_lengths{ length $s } ) {
            $garbled{$u} = $s;
        }
    }

    # next analysis:
    # A. segment 'a' is turned off in 1, 4               (2)
    # B. segment 'b' is turned off in 1, 2, 3, 7         (4)*
    # C. segment 'c' is turned off in 5, 6               (2)
    # D. segment 'd' is turned off in 0, 1, 7            (3)
    # E. segment 'e' is turned off in 1, 3, 4, 5, 7, 9   (6)*
    # F. segment 'f' is turned off in 2 only             (1)*
    # G. segment 'g' is turned off in 1, 4, 7            (3)

    my %found_seg;
    foreach my $s (@segs) {
        foreach my $c ( split '', $s ) {
            $found_seg{$c}->{$s} = 1;
        }
    }

    my %segment_map;

    foreach my $c ( keys %found_seg ) {
        my $num = scalar keys %{ $found_seg{$c} };

        my %unique_segnum = qw( 9 f 6 b 4 e );
        if ( my $u = $unique_segnum{ $num } ) {
            $segment_map{$u} = $c;
        }

        if ( $num == 9 ) {
            my ( $s ) = grep { index( $_, $c ) == -1 } @segs;
            $garbled{2} = $s;
        }
        if ( $num == 8 ) {
            my $v = $found_seg{$c}->{ $garbled{4} } ? 'c' : 'a';
            $segment_map{$v} = $c;
        }
        if ( $num == 7 ) {
            my $v = $found_seg{$c}->{ $garbled{4} } ? 'd' : 'g';
            $segment_map{$v} = $c;
        }
    }

    # values for all segments are now known
    # can use %digits and %segment_map to calculate unknown values

    foreach my $d ( 0..9 ) {
        next if exists $garbled{$d};
        my @chars = split '', $digits{$d};
        my $result = join '', map { $segment_map{$_} } @chars;

        $garbled{$d} = $sort_segment->( $result );
    }

    # now FINALLY decode outputs
    my $output = '';
    my %decoded = reverse %garbled;
    my %count = reverse %unique_lengths;

    foreach my $v ( split ' ', $vals ) {
        my $d = $decoded{ $sort_segment->( $v ) };
        $output .= $d;
        $total_pt1++ if $count{$d};
    }

    $total_pt2 += $output;
}

printf "Part 1: %s\n", $total_pt1;
printf "Part 2: %s\n", $total_pt2;
