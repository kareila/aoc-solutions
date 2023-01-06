#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 21
# https://adventofcode.com/2020/day/21

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# mxmxvkd kfcds sqjhc nhms (contains dairy, fish)
# trh fvjkl sbzzf mxmxvkd (contains dairy)
# sqjhc fvjkl (contains soy)
# sqjhc mxmxvkd sbzzf (contains fish)
# /;
# @lines = grep { length $_ } split "\n", $lines;

my %foods;
my %allergens;

foreach ( @lines ) {
    my ( $ingredients, $contains ) = /^([^(]+) \(contains ([^)]+)/;
    my @a = split ', ', $contains;
    my @i = split ' ', $ingredients;

    foreach my $a (@a) {
        $allergens{$a} //= [];
        push @{ $allergens{$a} }, \@i;
    }

    $foods{$_}++ foreach @i;
}

# Anything missing from a specific recipe cannot possibly
# contain any of the allergens listed in that recipe.
my %not;

foreach my $a ( keys %allergens ) {
    foreach my $recipe ( @{ $allergens{$a} } ) {
        my %missing = %foods;
        delete $missing{$_} foreach @$recipe;
        $not{$a}->{$_}++ foreach keys %missing;
    }
}

# Which ingredients are in every "not" group?
my @safe;

SAFE:
foreach my $food ( keys %foods ) {
    foreach my $group ( values %not ) {
        next SAFE unless $group->{$food};
    }
    push @safe, $food;
}

my $sum = 0;
$sum += $_ foreach map { $foods{$_} } @safe;

printf "Part 1: %s\n", $sum;


# Now we try to figure out which food contains which allergen.
# Which remaining foods are in EVERY recipe containing a specific allergen?
my %possible;

foreach my $a ( keys %allergens ) {
    my %contains;
    my $i = 0;

    foreach my $recipe ( @{ $allergens{$a} } ) {
        $contains{$_}++ foreach @$recipe;
        $i++;
    }
    # Discard all the safe ingredients from consideration.
    delete $contains{$_} foreach @safe;

    $possible{$a} = { map { $_ => 1 } grep { $contains{$_} == $i } keys %contains };
}

my %definitely;

while ( %possible ) {
    foreach my $a ( keys %possible ) {
        delete $possible{$a}->{$_} foreach keys %definitely;
        my @p = keys %{ $possible{$a} };
        if ( scalar @p == 1 ) {
            $definitely{ $p[0] } = $a;
            delete $possible{$a};
        }
    }
}

my $list = join ',', sort { $definitely{$a} cmp $definitely{$b} } keys %definitely;

printf "Part 2: %s\n", $list;
