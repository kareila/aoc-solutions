#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 22
# https://adventofcode.com/2021/day/22

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# on x=-5..47,y=-31..22,z=-19..33
# on x=-44..5,y=-27..21,z=-14..35
# on x=-49..-1,y=-11..42,z=-10..38
# on x=-20..34,y=-40..6,z=-44..1
# off x=26..39,y=40..50,z=-2..11
# on x=-41..5,y=-41..6,z=-36..8
# off x=-43..-33,y=-45..-28,z=7..25
# on x=-33..15,y=-32..19,z=-34..11
# off x=35..47,y=-46..-34,z=-11..5
# on x=-14..36,y=-6..44,z=-16..29
# on x=-57795..-6158,y=29564..72030,z=20435..90618
# on x=36731..105352,y=-21140..28532,z=16094..90401
# on x=30999..107136,y=-53464..15513,z=8553..71215
# on x=13528..83982,y=-99403..-27377,z=-24141..23996
# on x=-72682..-12347,y=18159..111354,z=7391..80950
# on x=-1060..80757,y=-65301..-20884,z=-103788..-16709
# on x=-83015..-9461,y=-72160..-8347,z=-81239..-26856
# on x=-52752..22273,y=-49450..9096,z=54442..119054
# on x=-29982..40483,y=-108474..-28371,z=-24328..38471
# on x=-4958..62750,y=40422..118853,z=-7672..65583
# on x=55694..108686,y=-43367..46958,z=-26781..48729
# on x=-98497..-18186,y=-63569..3412,z=1232..88485
# on x=-726..56291,y=-62629..13224,z=18033..85226
# on x=-110886..-34664,y=-81338..-8658,z=8914..63723
# on x=-55829..24974,y=-16897..54165,z=-121762..-28058
# on x=-65152..-11147,y=22489..91432,z=-58782..1780
# on x=-120100..-32970,y=-46592..27473,z=-11695..61039
# on x=-18631..37533,y=-124565..-50804,z=-35667..28308
# on x=-57817..18248,y=49321..117703,z=5745..55881
# on x=14781..98692,y=-1341..70827,z=15753..70151
# on x=-34419..55919,y=-19626..40991,z=39015..114138
# on x=-60785..11593,y=-56135..2999,z=-95368..-26915
# on x=-32178..58085,y=17647..101866,z=-91405..-8878
# on x=-53655..12091,y=50097..105568,z=-75335..-4862
# on x=-111166..-40997,y=-71714..2688,z=5609..50954
# on x=-16602..70118,y=-98693..-44401,z=5197..76897
# on x=16383..101554,y=4615..83635,z=-44907..18747
# off x=-95822..-15171,y=-19987..48940,z=10804..104439
# on x=-89813..-14614,y=16069..88491,z=-3297..45228
# on x=41075..99376,y=-20427..49978,z=-52012..13762
# on x=-21330..50085,y=-17944..62733,z=-112280..-30197
# on x=-16478..35915,y=36008..118594,z=-7885..47086
# off x=-98156..-27851,y=-49952..43171,z=-99005..-8456
# off x=2032..69770,y=-71013..4824,z=7471..94418
# on x=43670..120875,y=-42068..12382,z=-24787..38892
# off x=37514..111226,y=-45862..25743,z=-16714..54663
# off x=25699..97951,y=-30668..59918,z=-15349..69697
# off x=-44271..17935,y=-9516..60759,z=49131..112598
# on x=-61695..-5813,y=40978..94975,z=8655..80240
# off x=-101086..-9439,y=-7088..67543,z=33935..83858
# off x=18020..114017,y=-48931..32606,z=21474..89843
# off x=-77139..10506,y=-89994..-18797,z=-80..59318
# off x=8476..79288,y=-75520..11602,z=-96624..-24783
# on x=-47488..-1262,y=24338..100707,z=16292..72967
# off x=-84341..13987,y=2429..92914,z=-90671..-1318
# off x=-37810..49457,y=-71013..-7894,z=-105357..-13188
# off x=-27365..46395,y=31009..98017,z=15428..76570
# off x=-70369..-16548,y=22648..78696,z=-1892..86821
# on x=-53470..21291,y=-120233..-33476,z=-44150..38147
# off x=-93533..-4276,y=-16170..68771,z=-104985..-24507
# );
# @lines = grep { length $_ } split "\n", $lines;

my @switches;
foreach (@lines) {
    my ( $state, $xvals, $yvals, $zvals ) = /^(\w+) x=([^,]+),y=([^,]+),z=([^,]+)$/;
    push @switches, [ $state, map { split /\.\./ } ( $xvals, $yvals, $zvals ) ];
}

my %cube;
my $init_cube = sub {
    %cube = ();
    foreach my $s (@switches) {
        my $v = $s->[0] eq 'on' ? 1 : 0;
        # make sure we're in the area of interest
        next if $s->[1] > 50 || $s->[3] > 50 || $s->[5] > 50;
        next if $s->[2] < -50 || $s->[4] < -50 || $s->[6] < -50;

        for ( my $i = $s->[1]; $i <= $s->[2]; $i++ ) {
            for ( my $j = $s->[3]; $j <= $s->[4]; $j++ ) {
                for ( my $k = $s->[5]; $k <= $s->[6]; $k++ ) {
                    $cube{"$i,$j,$k"} = $v;
                }
            }
        }
    }
};
$init_cube->();

printf "Part 1: %s\n", scalar grep { $_ > 0 } values %cube;


# For Part 2, our area is going to be too large to manage as before.
# Instead, let's just look at the volumes defined by the switches.
#
# I've really struggled with this, so again, I'm using an outside guide:
# https://github.com/mebeim/aoc/tree/master/2021#day-22---reactor-reboot

my $overlap = sub {
    my ( $switch_a, $switch_b ) = @_;
    my $max_x1 = $switch_a->[1] > $switch_b->[1] ? $switch_a->[1] : $switch_b->[1];
    my $max_y1 = $switch_a->[3] > $switch_b->[3] ? $switch_a->[3] : $switch_b->[3];
    my $max_z1 = $switch_a->[5] > $switch_b->[5] ? $switch_a->[5] : $switch_b->[5];
    my $min_x2 = $switch_a->[2] < $switch_b->[2] ? $switch_a->[2] : $switch_b->[2];
    my $min_y2 = $switch_a->[4] < $switch_b->[4] ? $switch_a->[4] : $switch_b->[4];
    my $min_z2 = $switch_a->[6] < $switch_b->[6] ? $switch_a->[6] : $switch_b->[6];
    return undef unless $max_x1 < $min_x2 && $max_y1 < $min_y2 && $max_z1 < $min_z2;
    return [ undef, $max_x1, $min_x2, $max_y1, $min_y2, $max_z1, $min_z2 ];
};

my ( @positive, @negative );

# Here we track each "on" volume as well as the areas of overlap.
# Each positive overlap is added as a negative, so that it isn't
# counted twice. Same with negative overlaps added to positive.

foreach my $s (@switches) {
    my @new_negative;  # temporary buffer

    foreach my $p (@positive) {
        my $intersect = $overlap->( $s, $p );
        next unless defined $intersect;
        push @new_negative, $intersect;
        $new_negative[-1]->[0] = 'off';
    }

    foreach my $n (@negative) {
        my $intersect = $overlap->( $s, $n );
        next unless defined $intersect;
        push @positive, $intersect;
        $positive[-1]->[0] = 'on';
    }
    push @negative, @new_negative;
    push @positive, $s if $s->[0] eq 'on';
}

my $volume = sub {
    my @s = @{ $_[0] };
    return ( $s[2] - $s[1] + 1 ) * ( $s[4] - $s[3] + 1 ) * ( $s[6] - $s[5] + 1 );
};

my $total = 0;

# Each list element knows if it's on or off, so we can combine them here.
foreach my $s ( @positive, @negative ) {
    my $v = $s->[0] eq 'on' ? $volume->($s) : 0 - $volume->($s);
    $total += $v;
}

printf "Part 2: %s\n", $total;
# elapsed time: approx. 6 sec - confirmed that the count_dict approach
# would reduce this to 4 sec, but at the expense of comprehensibility
