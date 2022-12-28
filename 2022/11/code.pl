#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 11
# https://adventofcode.com/2022/day/11

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# Monkey 0:
#   Starting items: 79, 98
#   Operation: new = old * 19
#   Test: divisible by 23
#     If true: throw to monkey 2
#     If false: throw to monkey 3
#
# Monkey 1:
#   Starting items: 54, 65, 75, 74
#   Operation: new = old + 6
#   Test: divisible by 19
#     If true: throw to monkey 2
#     If false: throw to monkey 0
#
# Monkey 2:
#   Starting items: 79, 60, 97
#   Operation: new = old * old
#   Test: divisible by 13
#     If true: throw to monkey 1
#     If false: throw to monkey 3
#
# Monkey 3:
#   Starting items: 74
#   Operation: new = old + 3
#   Test: divisible by 17
#     If true: throw to monkey 0
#     If false: throw to monkey 1
# );
# @lines = grep { length $_ } split "\n", $lines;

my @monkeys;  # array of anonymous hashes with keys 'items', 'oper', 'test', 'true', 'false'
my %divisors; # for Part 2

my $parse_line = sub {
    my ( $l ) = @_;
    return unless $l;

    if ( $l =~ /^Monkey \d+:/ ) {
        push @monkeys, {};
        return;
    }

    if ( $l =~ /^\s+Starting items: ([0-9, ]+)$/ ) {
        $monkeys[-1]->{items} = [ split ', ', $1 ];
        return;
    }

    if ( $l =~ /^\s+Operation: new = old ([+*]) (\S+)$/ ) {
        my ( $op, $what ) = ( $1, $2 );
        my $calc = sub {
            my ( $arg ) = @_;
            my $num = ( $what eq 'old' ) ? $arg : $what;
            return $arg + $num if $op eq '+';
            return $arg * $num if $op eq '*';
            die "Unknown op '$op'";  # catch translation failures
        };
        $monkeys[-1]->{oper} = $calc;
        return;
    }

    if ( $l =~ /^\s+Test: divisible by (\d+)$/ ) {
        my $div = $1;
        $monkeys[-1]->{test} = sub { $_[0] % $div ? 0 : 1 };
        $divisors{$div} = 1;   # disregard any duplicates
        return;
    }

    if ( $l =~ /^\s+If (\w+): throw to monkey (\d+)$/ ) {
        $monkeys[-1]->{$1} = $2;
        return;
    }

    die "Failed to parse line: $l";  # stop if something went wrong
};

$parse_line->($_) foreach @lines;

my $relief = sub {
    my ( $num ) = @_;
    # divide by three and round down
    return ( $num - ( $num % 3 ) ) / 3;
};

my @inspections;

my $turn = sub {
    my ( $which ) = @_;
    my $active = $monkeys[$which];  # which monkey is active

    # On a single monkey's turn, it inspects and throws all of the
    # items it is holding one at a time and in the order listed.

    my $per_item = sub {
        my ( $item ) = @_;
        $item = $active->{oper}->($item);  # do monkey's operation
        $item = $relief->($item);          # apply relief adjustment

        my $next = $active->{test}->($item) ? $active->{true} : $active->{false};
        push @{ $monkeys[$next]->{items} }, $item;

        $inspections[$which]++;
    };

    $per_item->($_) foreach @{ $active->{items} };
    $active->{items} = [];  # reset
};

for ( my $i = 1; $i <= 20; $i++ ) {
    $turn->($_) foreach ( 0 .. $#monkeys );
}

# use Data::Dumper;
# die Dumper \@inspections;

my $monkey_business = sub {
    my @busiest = sort { $b <=> $a } @inspections;
    return $busiest[0] * $busiest[1];
};

printf "Part 1: %s\n", $monkey_business->();


# Worry levels are no longer divided by three after each item is inspected.
$relief = sub { return $_[0] };

# "You'll need to find another way to keep your worry levels manageable."
# Without the relief step, the numbers quickly (within 20 rounds) begin to
# express themselves in scientific notation, so calculations lose accuracy.
#
# I struggled with this until I received some math advice: if you take the
# product of all the divisors and use it as a modulus, you can apply that to
# reduce worry levels without changing the end result of the calculations.

my $fear_factor = 1;  # lol
$fear_factor *= $_ foreach keys %divisors;

$relief = sub { return $_[0] % $fear_factor };

# full state reset
@inspections = ();
@monkeys = ();
$parse_line->($_) foreach @lines;

for ( my $i = 1; $i <= 10000; $i++ ) {
    $turn->($_) foreach ( 0 .. $#monkeys );
}

printf "Part 2: %s\n", $monkey_business->();
