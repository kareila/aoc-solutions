#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 19
# https://adventofcode.com/2020/day/19

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# 0: 4 1 5
# 1: 2 3 | 3 2
# 2: 4 4 | 5 5
# 3: 4 5 | 5 4
# 4: "a"
# 5: "b"
#
# ababbb
# bababa
# abbbab
# aaabbb
# aaaabbb
# /;
# example for Part 2
# my $lines = q/
# 42: 9 14 | 10 1
# 9: 14 27 | 1 26
# 10: 23 14 | 28 1
# 1: "a"
# 11: 42 31
# 5: 1 14 | 15 1
# 19: 14 1 | 14 14
# 12: 24 14 | 19 1
# 16: 15 1 | 14 14
# 31: 14 17 | 1 13
# 6: 14 14 | 1 14
# 2: 1 24 | 14 4
# 0: 8 11
# 13: 14 3 | 1 12
# 15: 1 | 14
# 17: 14 2 | 1 7
# 23: 25 1 | 22 14
# 28: 16 1
# 4: 1 1
# 20: 14 14 | 1 15
# 3: 5 14 | 16 1
# 27: 1 6 | 14 18
# 14: "b"
# 21: 14 1 | 1 14
# 25: 1 1 | 1 14
# 22: 14 14
# 8: 42
# 26: 14 22 | 1 20
# 18: 15 15
# 7: 14 5 | 1 21
# 24: 14 1
#
# abbbbbabbbaaaababbaabbbbabababbbabbbbbbabaaaa
# bbabbbbaabaabba
# babbbbaabbbbbabbbbbbaabaaabaaa
# aaabbbbbbaaaabaababaabababbabaaabbababababaaa
# bbbbbbbaaaabbbbaaabbabaaa
# bbbababbbbaaaaaaaabbababaaababaabab
# ababaaaaaabaaab
# ababaaaaabbbaba
# baabbaaaabbaaaababbaababb
# abbbbabbbbaaaababbbbbbaaaababb
# aaaaabbaabaaaaababaa
# aaaabbaaaabbaaa
# aaaabbaabbaaaaaaabbbabbbaaabbaabaaa
# babaaabbbaaabaababbaabababaaab
# aabbbbbaabbbaaaaaabbbbbababaaaaabbaaabba
# /;
# @lines = grep { length $_ } split "\n", $lines;

my %rule_lines = map { split ': ' } grep { /:/ } @lines;
my @message_lines = grep { ! /:/ } grep { length $_ } @lines;

# using approach described here because my regex-based solution failed in Part 2:
# https://github.com/mebeim/aoc/blob/master/2020/README.md#day-19---monster-messages

sub match {
    my ( $string, $rulenum, $sidx ) = @_;
    $sidx //= 0;

    # If we are past the end of the string, we can't match anything anymore
    return if $sidx >= length $string;

    my $rule = $rule_lines{ $rulenum };

    # If the current rule is a simple character, match that literally
    if ( $rule =~ /^"(.)"$/ ) {
        # If it matches, advance 1 and return this information to the caller
        return $sidx + 1 if substr( $string, $sidx, 1 ) eq $1;
        # Otherwise fail, we cannot continue matching
        return;
    }

    # If we get here, we are in the case `X: A B | C D`
    my @matches;

    # For each option in the rule
    foreach my $option ( split / [|] /, $rule ) {
        # Start matching from the current position
        my @sub_matches = ( $sidx );

        # For any rule of this option
        foreach my $subrule ( split / /, $option ) {
            # Get all resulting positions after matching this rule
            # from any of the possible positions we have so far.
            my @new_matches;
            push @new_matches, match( $string, $subrule, $_ ) foreach @sub_matches;

            # Keep the new positions and continue with the next rule, trying to match all of them
            @sub_matches = @new_matches;
        }
        # Collect all possible matches for the current option and add them to the final result
        push @matches, @sub_matches;
    }
    # Return all possible final indexes after matching this rule
    return @matches;
}

my $count_rule_matches = sub {
    my ( $rulenum ) = @_;
    my $sum = 0;

    foreach my $m ( @message_lines ) {
        my $len_match = [ sort { $b <=> $a } match( $m, $rulenum ) ]->[0];
        $sum++ if length $m == ( $len_match // 0 );
    }
    return $sum;
};

printf "Part 1: %s\n", $count_rule_matches->(0);


$rule_lines{8}  = '42 | 42 8';
$rule_lines{11} = '42 31 | 42 11 31';

printf "Part 2: %s\n", $count_rule_matches->(0);
