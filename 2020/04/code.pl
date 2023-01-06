#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 4
# https://adventofcode.com/2020/day/4

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data for part 1
# my $lines = qq/
# ecl:gry pid:860033327 eyr:2020 hcl:#fffffd
# byr:1937 iyr:2017 cid:147 hgt:183cm
#
# iyr:2013 ecl:amb cid:350 eyr:2023 pid:028048884
# hcl:#cfa07d byr:1929
#
# hcl:#ae17e1 iyr:2013
# eyr:2024
# ecl:brn pid:760753108 byr:1931
# hgt:179cm
#
# hcl:#cfa07d eyr:2025 pid:166559648
# iyr:2011 ecl:brn hgt:59in
# /;
# @lines = split "\n", $lines;
# shift @lines;  # drop leading newline

my @records;
my $i = 0;

foreach my $l ( @lines ) {
    if ( $l eq "" ) {
        $i++;  # next record begins
    } else {
        $records[$i] = $records[$i] ? $records[$i] . " $l" : $l;
    }
}

my @all_fields = qw( byr iyr eyr hgt hcl ecl pid cid );
my @opt_fields = qw( cid );

my $is_ok = sub { 1 };  # everything is OK in Part 1

my $check_records = sub {
    my $num_valid = 0;
    foreach my $r (@records) {
        my %not_found = map { $_ => 1 } @all_fields;  # remove as we go
        my @fields = split ' ', $r;
        foreach my $f (@fields) {
            my ( $k, $v ) = split ':', $f;
            delete $not_found{$k} if $is_ok->($k, $v);
        }
        foreach my $k (@opt_fields) {
            delete $not_found{$k};  # done in any case, since optional field
        }
        $num_valid++ unless %not_found;
    }
    return $num_valid;
};

printf "Part 1: %s\n", $check_records->();


# logic to describe allowable values for record fields
my %validate = (
    byr => sub {
                my $v = $_[0];
                return 0 unless $v =~ /^\d{4}$/;
                return 0 if $v < 1920 || $v > 2002;
                return 1;
               },
    iyr => sub {
                my $v = $_[0];
                return 0 unless $v =~ /^\d{4}$/;
                return 0 if $v < 2010 || $v > 2020;
                return 1;
               },
    eyr => sub {
                my $v = $_[0];
                return 0 unless $v =~ /^\d{4}$/;
                return 0 if $v < 2020 || $v > 2030;
                return 1;
               },
    hgt => sub {
                my $v = $_[0];
                if ( $v =~ /^(\d+)cm$/ ) {
                    return 0 if $1 < 150 || $1 > 193;
                    return 1;
                }
                if ( $v =~ /^(\d+)in$/ ) {
                    return 0 if $1 < 59 || $1 > 76;
                    return 1;
                }
                return 0;
               },
    hcl => sub {
                my $v = $_[0];
                return $v =~ /^#[0-9a-f]{6}$/ ? 1 : 0;
               },
    ecl => sub {
                my $v = $_[0];
                my %ok = map { $_ => 1 } qw( amb blu brn gry grn hzl oth );
                return $ok{$v} ? 1 : 0;
               },
    pid => sub {
                my $v = $_[0];
                return $v =~ /^\d{9}$/ ? 1 : 0;
               },
    cid => sub { 1 }
);

$is_ok = sub {
    my ( $k, $v ) = @_;
    return $validate{$k} ? $validate{$k}->($v) : 0;
};

printf "Part 2: %s\n", $check_records->();
