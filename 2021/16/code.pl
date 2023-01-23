#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 16
# https://adventofcode.com/2021/day/16

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# D2FE28
# 38006F45291200
# EE00D40C823060
# 8A004A801A8002F478
# 620080001611562C8802118E34
# C0015000016115A2E0802F182340
# A0016C880162017C3686B18A3D4780
# C200B40A82
# 04005AC33890
# 880086C3E88112
# CE00C43D881120
# D8005AC2A8F0
# F600BC2D8F
# 9C005AC2F8F0
# 9C0141080250320F1802104A08
# /;
# @lines = grep { length $_ } split "\n", $lines;

my %bin_value = (
    '0' => '0000',
    '1' => '0001',
    '2' => '0010',
    '3' => '0011',
    '4' => '0100',
    '5' => '0101',
    '6' => '0110',
    '7' => '0111',
    '8' => '1000',
    '9' => '1001',
    'A' => '1010',
    'B' => '1011',
    'C' => '1100',
    'D' => '1101',
    'E' => '1110',
    'F' => '1111',
);

my $hex_to_bin = sub {
    my ( $hex ) = @_;
    my $str = '';
    $str .= $bin_value{$_} foreach split '', $hex;
    return $str;
};

my $as_decimal = sub {
    my ( $binnum ) = @_;
    my $len = length $binnum;
    my $number = 0;

    for ( my $i = 1; $i <= $len; $i++ ) {
        my $digit = substr $binnum, $len - $i, 1;
        my $mult = 2 ** ( $i - 1 );
        $number += $digit * $mult;
    }
    return $number;
};

my $version_sum = 0;

# note: this function removes parsed bits from its input
sub decode_packet {
    my ( $bin ) = @_;
    my $str = ref $bin ? $bin : \$bin;
    die "not binary input" unless $$str =~ /^[01]+$/;

    # the first three bits encode the packet version
    $$str =~ /^(.{3})(.*)$/ and $$str = $2;
    my $ver = $as_decimal->($1);
    $version_sum += $ver;

    # the next three bits encode the packet type ID
    $$str =~ /^(.{3})(.*)$/ and $$str = $2;
    my $tid = $as_decimal->($1);

    if ( $tid == 4 ) {
        my $num = '';
        while (1) {
            $$str =~ /^(.{5})(.*)$/ and $$str = $2;
            my @next = split '', $1;
            my $continue = shift @next;
            $num .= join '', @next;
            last unless $continue;
        }
        return $as_decimal->($num);

    } else {
        $$str =~ /^(.{1})(.*)$/ and $$str = $2;
        my $length_tid = $1;
        my @ret;

        if ( $length_tid ) {
            # the next 11 bits are a number that represents the number of sub-packets
            $$str =~ /^(.{11})(.*)$/ and $$str = $2;
            my $num_packets = $as_decimal->($1);
            push @ret, decode_packet($str) foreach ( 1 .. $num_packets );

        } else {
            # the next 15 bits are a number that represents the total length in bits
            $$str =~ /^(.{15})(.*)$/ and $$str = $2;
            my $len_packets = $as_decimal->($1);
            $$str =~ /^(.{$len_packets})(.*)$/ and $$str = $2;
            my $substr = $1;
            push @ret, decode_packet(\$substr) while ( length $substr > 0 );
        }

        # values are in @ret, now do operation indicated by $tid
        my %op_table = (
            0 => sub {  # sum values
                        my $sum = 0;
                        $sum += $_ foreach @ret;
                        return $sum;
                     },
            1 => sub {  # multiply together values
                        my $prod = 1;
                        $prod *= $_ foreach @ret;
                        return $prod;
                     },
            2 => sub {  # minimum value
                        my $min = shift @ret;
                        foreach (@ret) { $min = $_ unless $min < $_; }
                        return $min;
                     },
            3 => sub {  # maximum value
                        my $max = shift @ret;
                        foreach (@ret) { $max = $_ unless $max > $_; }
                        return $max;
                     },
            5 => sub {  # first value greater than second value
                        die "bad args for 5" unless scalar @ret == 2;
                        return $ret[0] > $ret[1] ? 1 : 0;
                     },
            6 => sub {  # first value less than second value
                        die "bad args for 6" unless scalar @ret == 2;
                        return $ret[0] < $ret[1] ? 1 : 0;
                     },
            7 => sub {  # first value equal to second value
                        die "bad args for 7" unless scalar @ret == 2;
                        return $ret[0] == $ret[1] ? 1 : 0;
                     },
        );
        return $op_table{$tid}->();
    }
}

my @packets = map { $hex_to_bin->($_) } @lines;
# printf "%s\n", decode_packet($_) foreach @packets;

# actual data only contains one long packet
my $val = decode_packet( $packets[0] );

printf "Part 1: %s\n", $version_sum;
printf "Part 2: %s\n", $val // '';
