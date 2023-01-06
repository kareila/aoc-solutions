#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 7
# https://adventofcode.com/2020/day/7

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = qq/
# light red bags contain 1 bright white bag, 2 muted yellow bags.
# dark orange bags contain 3 bright white bags, 4 muted yellow bags.
# bright white bags contain 1 shiny gold bag.
# muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
# shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
# dark olive bags contain 3 faded blue bags, 4 dotted black bags.
# vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
# faded blue bags contain no other bags.
# dotted black bags contain no other bags.
# /;
# my $lines = qq/
# shiny gold bags contain 2 dark red bags.
# dark red bags contain 2 dark orange bags.
# dark orange bags contain 2 dark yellow bags.
# dark yellow bags contain 2 dark green bags.
# dark green bags contain 2 dark blue bags.
# dark blue bags contain 2 dark violet bags.
# dark violet bags contain no other bags.
# /;
# @lines = grep { length $_ } split "\n", $lines;

# all lines are of the form "[color] bags contain [contents]." where contents
# are a comma-sep list of "[num] [color] bag(s)" or the phrase "no other bags"
# also, all color descriptions are two words

my %bag_rules;

my $parse_rule = sub {
    my ( $l ) = @_;

    my ( $type, $contents ) = ( $l =~ /^(\w+ \w+) bags contain ([^.]+)\.$/ );
    my @c = split ', ', $contents;

    $bag_rules{ $type } = {};
    return if $c[0] eq 'no other bags';

    foreach my $b (@c) {
        my ( $num, $color ) = ( $b =~ /^(\d+) (\w+ \w+) bags?$/ );
        $bag_rules{ $type }->{ $color } = $num;
    }
};

$parse_rule->( $_ ) foreach @lines;

# now we want to dig through each type of bag to do full inventory

my %unpacked;  # key: color; value: hash of color => number, de-nested

# Here (and elsewhere) I use non-local subroutines when needed for recursion.
sub unpack_bag {
    my ( $top, $bag ) = @_;
    $bag //= $top;

    # see if we already have this bag's inventory
    if ( my $u = $unpacked{ $bag } ) {
        return if $bag eq $top;  # nothing to do
        # Add this bag's contents to the contents of the top-level bag.
        $unpacked{ $top }->{$_} += $u->{$_} foreach keys %$u;
        return $unpacked{ $top }->{ $bag }++;  # count the bag itself too
    }

    # haven't inventoried this bag yet - consult the rules
    my $contents = $bag_rules{ $bag };
    return $unpacked{ $top } = {} if $bag eq $top && ! %$contents;  # empty bag

    foreach my $i ( keys %$contents ) {
        unpack_bag($i);  # this caches it sooner rather than later

        # unpack each inner bag in turn, adding the contents to this bag's inventory
        unpack_bag( $top, $i ) foreach ( 1 .. $contents->{$i} );
    }

    $unpacked{ $top }->{ $bag }++ unless $bag eq $top;  # count the bag itself too
}

unpack_bag($_) foreach keys %bag_rules;  # fully populate %unpacked

my $has_shiny_gold = scalar grep { $_->{'shiny gold'} } values %unpacked;

printf "Part 1: %s\n", $has_shiny_gold;


# use Data::Dumper;
# die Dumper $unpacked{'shiny gold'};

my $num_bags = 0;
$num_bags += $_ foreach values %{ $unpacked{'shiny gold'} };

printf "Part 2: %s\n", $num_bags;
