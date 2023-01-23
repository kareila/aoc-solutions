#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 19
# https://adventofcode.com/2021/day/19

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# --- scanner 0 ---
# 404,-588,-901
# 528,-643,409
# -838,591,734
# 390,-675,-793
# -537,-823,-458
# -485,-357,347
# -345,-311,381
# -661,-816,-575
# -876,649,763
# -618,-824,-621
# 553,345,-567
# 474,580,667
# -447,-329,318
# -584,868,-557
# 544,-627,-890
# 564,392,-477
# 455,729,728
# -892,524,684
# -689,845,-530
# 423,-701,434
# 7,-33,-71
# 630,319,-379
# 443,580,662
# -789,900,-551
# 459,-707,401
#
# --- scanner 1 ---
# 686,422,578
# 605,423,415
# 515,917,-361
# -336,658,858
# 95,138,22
# -476,619,847
# -340,-569,-846
# 567,-361,727
# -460,603,-452
# 669,-402,600
# 729,430,532
# -500,-761,534
# -322,571,750
# -466,-666,-811
# -429,-592,574
# -355,545,-477
# 703,-491,-529
# -328,-685,520
# 413,935,-424
# -391,539,-444
# 586,-435,557
# -364,-763,-893
# 807,-499,-711
# 755,-354,-619
# 553,889,-390
#
# --- scanner 2 ---
# 649,640,665
# 682,-795,504
# -784,533,-524
# -644,584,-595
# -588,-843,648
# -30,6,44
# -674,560,763
# 500,723,-460
# 609,671,-379
# -555,-800,653
# -675,-892,-343
# 697,-426,-610
# 578,704,681
# 493,664,-388
# -671,-858,530
# -667,343,800
# 571,-461,-707
# -138,-166,112
# -889,563,-600
# 646,-828,498
# 640,759,510
# -630,509,768
# -681,-892,-333
# 673,-379,-804
# -742,-814,-386
# 577,-820,562
#
# --- scanner 3 ---
# -589,542,597
# 605,-692,669
# -500,565,-823
# -660,373,557
# -458,-679,-417
# -488,449,543
# -626,468,-788
# 338,-750,-386
# 528,-832,-391
# 562,-778,733
# -938,-730,414
# 543,643,-506
# -524,371,-870
# 407,773,750
# -104,29,83
# 378,-903,-323
# -778,-728,485
# 426,699,580
# -438,-605,-362
# -469,-447,-387
# 509,732,623
# 647,635,-688
# -868,-804,481
# 614,-800,639
# 595,780,-596
#
# --- scanner 4 ---
# 727,592,562
# -293,-554,779
# 441,611,-461
# -714,465,-776
# -743,427,-804
# -660,-479,-426
# 832,-632,460
# 927,-485,-438
# 408,393,-506
# 466,436,-512
# 110,16,151
# -258,-428,682
# -393,719,612
# -211,-452,876
# 808,-476,-593
# -575,615,604
# -485,667,467
# -680,325,-822
# -627,-443,-432
# 872,-547,-609
# 833,512,582
# 807,604,487
# 839,-516,451
# 891,-625,532
# -652,-548,-490
# 30,-46,-14
# );
# @lines = grep { length $_ } split "\n", $lines;

my @scanners;
{   my $i;

    foreach (@lines) {
        next unless length $_;
        if ( /^--- scanner (\d+) ---$/ ) {
            $i = $1;
            $scanners[$i] //= [];
            next;
        }
        die "bad format" unless defined $i;
        # all other data lines should be coordinate triples
        push @{ $scanners[$i] }, [ split ',' ];
    }
}

# Since all location data is relative, the only way to uniquely identify
# beacons is by their distances relative to each other. Create a map
# of each beacon's distance from each other beacon (or rather the square
# of the distance, extending the Pythagorean theorem to three dimensions).
#
# Once we have the distance data, we can fingerprint each point based on
# a sorted list of its distances to all the other points in its system.
# Counting these will also tell us how many total beacons there are.
my ( %dist, %uniq, %count );

for ( my $n=0; $n < @scanners; $n++ ) {
    my $s = $scanners[$n];
    ( $dist{$n}, $uniq{$n} ) = ( {}, {} );
    for ( my $i=0; $i < @$s; $i++ ) {
        # counting up from $i to avoid counting the same distance twice
        for ( my $j = $i+1; $j < @$s; $j++ ) {
            my ( $pi, $pj, $d ) = ( $s->[$i], $s->[$j], 0 );
            $d += ( $pi->[$_] - $pj->[$_] ) ** 2 foreach ( 0 .. 2 );
            $dist{$n}->{$d} = [ $pi, $pj ];
            foreach my $p ( $pi, $pj) {
                my $pk = join ',', @$p;
                $uniq{$n}->{$pk} //= [];
                push @{ $uniq{$n}->{$pk} }, $d;
            }
        }
    }
    # convert uniq to string, keeping only the two closest neighbors
    foreach my $pk ( keys %{ $uniq{$n} } ) {
        my $u = join ',', (sort { $a <=> $b } @{ $uniq{$n}->{$pk} })[0..1];
        $uniq{$n}->{$pk} = $u;
        $count{$u}++;
    }
}

printf "Part 1: %s\n", scalar keys %count;


# Now %dist contains keys of point distances and values of the two points
# that the distance is between, whereas our "fingerprint" hash %uniq has
# keys of point coordinates (in string form) and values of the distances
# from that point to its two nearest neighbors (again, in string form).
# Each is further keyed on scanner ID, since each scanner has a different
# system of coordinates, which we need to now reconcile with each other.

my $find_translation = sub {
    my ( $u_id, $k_id, $matches ) = @_;
    # @$matches is a list of distance keys that appear on both scanners
    # (k is for "known" and u is for "unknown" system of reference)
    my ( %u_points, %k_points );  # key fingerprint, val coordinates

    my $assign_points = sub {
        my ( $id, $m, $h ) = @_;
        my $match_dist = $dist{$id}->{$m};
        my %m_p = map { $uniq{$id}->{ join ',', @$_ } => $_ } @$match_dist;
        while ( my ( $k, $v ) = each ( %m_p ) ) { $h->{$k} = $v; }
    };
    foreach my $match ( @$matches ) {
        $assign_points->( $u_id, $match, \%u_points );
        $assign_points->( $k_id, $match, \%k_points );
    }
    # For the system where we don't know the origin (u), we need
    # to try expressing its points in the 24 possible orientations
    # and see which orientation resolves to a single translation
    # vector from the values of the points with known origin.
    my $rotations = sub {
        my ( $x, $y, $z ) = @{ $_[0] };
        return [
            [ 0 + $x, 0 + $y, 0 + $z ],
            [ 0 + $x, 0 + $z, 0 - $y ],
            [ 0 + $x, 0 - $y, 0 - $z ],
            [ 0 + $x, 0 - $z, 0 + $y ],

            [ 0 - $x, 0 - $y, 0 + $z ],
            [ 0 - $x, 0 - $z, 0 - $y ],
            [ 0 - $x, 0 + $y, 0 - $z ],
            [ 0 - $x, 0 + $z, 0 + $y ],

            [ 0 + $y, 0 - $x, 0 + $z ],
            [ 0 + $y, 0 + $z, 0 + $x ],
            [ 0 + $y, 0 + $x, 0 - $z ],
            [ 0 + $y, 0 - $z, 0 - $x ],

            [ 0 - $y, 0 + $x, 0 + $z ],
            [ 0 - $y, 0 - $z, 0 + $x ],
            [ 0 - $y, 0 - $x, 0 - $z ],
            [ 0 - $y, 0 + $z, 0 - $x ],

            [ 0 + $z, 0 + $y, 0 - $x ],
            [ 0 + $z, 0 + $x, 0 + $y ],
            [ 0 + $z, 0 - $y, 0 + $x ],
            [ 0 + $z, 0 - $x, 0 - $y ],

            [ 0 - $z, 0 - $y, 0 - $x ],
            [ 0 - $z, 0 - $x, 0 + $y ],
            [ 0 - $z, 0 + $y, 0 + $x ],
            [ 0 - $z, 0 + $x, 0 - $y ],
        ];  # hat tip https://github.com/artesea/advent-of-code/blob/main/2021/19a.php
    };
    my %u_rots = map { $_ => $rotations->( $u_points{$_} ) } keys %u_points;

    foreach my $n ( 0 .. 23 ) {
        my %trans;
        foreach my $p ( keys %k_points ) {
            my $k_p = $k_points{$p};
            my $u_p = $u_rots{$p}->[$n];
            my @v = map { $k_p->[$_] - $u_p->[$_] } ( 0 .. 2 );
            $trans{ join ',', @v }++;
        }
        if ( scalar keys %trans == 1 ) {
            # Now we know the translation vector and its orientation!
            my $t = [ split ',', ( keys %trans )[0] ];

            # That's the good news - the bad news is that we have to
            # update the values of %dist and %uniq to place all of the
            # coordinates for this space in the common reference frame.
            foreach my $d ( keys %{ $dist{$u_id} } ) {
                foreach my $i (0..1) {
                    my $p = $dist{$u_id}->{$d}->[$i];
                    my $pk_old = join ',', @$p;  # for updating %uniq

                    # do the rotation first, then the translation
                    $dist{$u_id}->{$d}->[$i] = $rotations->($p)->[$n];
                    $dist{$u_id}->{$d}->[$i]->[$_] += $t->[$_] foreach ( 0 .. 2 );

                    my $pk_new = join ',', @{ $dist{$u_id}->{$d}->[$i] };
                    if ( exists $uniq{$u_id}->{$pk_old} ) {
                        $uniq{$u_id}->{$pk_new} = $uniq{$u_id}->{$pk_old};
                        delete $uniq{$u_id}->{$pk_old};
                    }
                }
            }
            # this also describes the scanner's position
            return $t;
        }
    }
    die "translation not found for k_id $k_id, u_id $u_id";
};

# We are taking scanner 0 as our point of origin. Iteratively search
# for other scanners that have "at least 12 of the same beacons" which
# isn't entirely clear how to extrapolate for number of distances, but
# testing on the example where we know 0 and 1 overlap, the desired
# number of matches seems to be 66. More than that and the search fails.
# ** Noting some math here: ( 12 * 11 ) / 2 = 66 **
my %found = ( 0 => [0,0,0] );
my %search = map { $_ => 1 } ( 1 .. $#scanners );

while ( %search ) {
    foreach my $s ( keys %search ) {
        my %overlap;
        foreach my $f ( keys %found ) {
            my @matches = grep { $dist{$f}->{$_} } keys %{ $dist{$s} };
            $overlap{$f} = \@matches if @matches == 66;
        }
        if ( %overlap ) {
            my $f = [ keys %overlap ]->[0];
            $found{$s} = $find_translation->( $s, $f, $overlap{$f} );
            delete $search{$s};
            last;  # reinitialize the foreach search loop
        }
    }
}

# Now that we've adjusted the frame of reference for each scanner,
# we can determine how far apart the scanners all are from each other.
my $m_dist = sub {
    my ( $x1, $y1, $z1, $x2, $y2, $z2 ) = ( @{ $_[0] }, @{ $_[1] } );
    # calculate the Manhattan distance for any two points in 3D space
    return abs( $x1 - $x2 ) + abs( $y1 - $y2 ) + abs( $z1 - $z2 );
};

my @s_dist;

for ( my $i=0; $i < @scanners; $i++ ) {
    # counting up from $i to avoid counting the same distance twice
    for ( my $j = $i+1; $j < @scanners; $j++ ) {
        push @s_dist, $m_dist->( $found{$i}, $found{$j} );
    }
}

printf "Part 2: %s\n", [ sort { $b <=> $a } @s_dist ]->[0];
