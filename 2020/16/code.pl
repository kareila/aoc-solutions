#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 16
# https://adventofcode.com/2020/day/16

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# class: 1-3 or 5-7
# row: 6-11 or 33-44
# seat: 13-40 or 45-50
#
# your ticket:
# 7,1,14
#
# nearby tickets:
# 7,3,47
# 40,4,50
# 55,2,20
# 38,6,12
# /;
# @lines = grep { length $_ } split "\n", $lines;
#
# example data for Part 2
# my $lines = q/
# class: 0-1 or 4-19
# row: 0-5 or 8-19
# seat: 0-13 or 16-19
#
# your ticket:
# 11,12,13
#
# nearby tickets:
# 3,9,18
# 15,1,5
# 5,14,9
# /;
# @lines = grep { length $_ } split "\n", $lines;

my %rule_lines = map { split ': ' } grep { /^[^:]+: .+$/ } @lines;
my @ticket_lines = grep { /,/ } @lines;
my $my_ticket = shift @ticket_lines;

my $parse_rule = sub {
    my ( $range ) = @_;
    # every range has the format "n1-n2 or n3-n4"
    my ( $n1, $n2, $n3, $n4 ) = ( $range =~ /^(\d+)-(\d+) or (\d+)-(\d+)$/ );
    return sub {
        return 0 if $_[0] <  $n1;
        return 1 if $_[0] <= $n2;
        return 0 if $_[0] >  $n4;
        return 1 if $_[0] >= $n3;
        return 0;
    };
};

my %rules = map { $_ => $parse_rule->( $rule_lines{$_} ) } keys %rule_lines;
my $invalid_sum = 0;

# also, we can get a head start on Part 2 by discarding the invalid tickets
my @valid_tickets;

foreach my $t ( @ticket_lines ) {
    my $t_ok = 1;
    foreach my $n ( split ',', $t ) {
        unless ( scalar grep { $_->($n) } values %rules ) {
            $invalid_sum += $n;
            $t_ok = 0;
        }
    }
    push @valid_tickets, $t if $t_ok;
}

printf "Part 1: %s\n", $invalid_sum;


# look at every ticket's value for each column of data
my $num_fields = scalar split ',', $valid_tickets[0];
my %possible_rule_matches;

for ( my $i=0; $i < $num_fields; $i++ ) {
    my @fv = map { [ split ',' ]->[$i] } @valid_tickets;
    my $can_be = {};
    while ( my ( $k, $r ) = each %rules ) {
        # do all values for this field obey this rule?
        $can_be->{$k} = 1 if scalar ( grep { $r->($_) } @fv ) == scalar @fv;
    }
    $possible_rule_matches{$i} = $can_be;
}

# In our example, the first field can only be 'row'; the second field
# can be 'class' or 'row', so must be 'class'; and the third field can
# be any of the three, but is the only one that can be 'seat'. We can
# use a similar process of elimination to map fields on the full data
# set, but we only need to track the fields starting with 'departure'.

my %departure_fields;
my @found;

while ( %possible_rule_matches ) {
    foreach my $i ( keys %possible_rule_matches ) {
        delete $possible_rule_matches{$i}->{$_} foreach @found;
        my @r = keys %{ $possible_rule_matches{$i} };
        if ( scalar @r == 1 ) {
            delete $possible_rule_matches{$i};
            $departure_fields{ $r[0] } = $i if $r[0] =~ /^departure /;
            push @found, $r[0];
        }
    }
}

# the rest of this solution doesn't apply to the example
die "No departure keys found" unless %departure_fields;

my @ticket_vals = split ',', $my_ticket;
my $product = 1;
$product *= $ticket_vals[$_] foreach values %departure_fields;

printf "Part 2: %s\n", $product;
