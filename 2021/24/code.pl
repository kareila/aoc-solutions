#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 24
# https://adventofcode.com/2021/day/24

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# *********************************** BEGIN SOLUTION **********************************

# I tried to implement the ALU as described, but that didn't help me find the solution.
# We're going to have to follow the advice to "figure out what MONAD does some other way"
# which I really hate. I'm here to write code, not to do algebraic manipulation!!
#
# That also means looking at others' solutions for the third day in a row, argh.
# (But at least I'm getting practice with translating Python idioms into Perl.)
# https://gist.github.com/jkseppan/1e36172ad4f924a8f86a920e4b1dc1b1

my ( @x_add, @y_add );

for ( my $i=0; $i < @lines; $i++ ) {
    my ($v) = ( $lines[$i] =~ /(-?\d+)$/ );
    my $n = $i % 18;
    push @x_add, $v + 0 if $n == 5;
    push @y_add, $v + 0 if $n == 15;
}

my @z_div = map { $_ > 0 ? 1 : 26 } @x_add;

# calculate possible values of z before a single block if the final value of z is z2
my $possible_zs = sub {
    my ( $i, $z2, $w ) = @_;
    $i //= 0;
    die "out of range" if $i < 0 || $i >= scalar @x_add;
    die "bad input" unless defined $z2 && defined $w && $w != 0 && $w =~ /^\d$/;
    my @zs;

    my $x = $z2 - $w - $y_add[$i];
    push @zs, int( $x / 26 ) * $z_div[$i] if $x % 26 == 0;
    my $r = $w - $x_add[$i];
    push @zs, $r + $z2 * $z_div[$i] if $r >= 0 && $r < 26;

    return @zs;
};

my $solve = sub {
    my @ws = ( 1..9 );
    @ws = reverse @ws if defined $_[0] && $_[0] eq 'min';
    my %zs = ( 0 => 1 );
    my %result;

    for ( my $i = $#x_add; $i >= 0; $i-- ) {
        my %newzs;
        # we're going through w in reverse to only keep the latest (highest) result
        foreach my $w (@ws) {
            foreach my $z ( keys %zs ) {
                foreach my $z0 ( $possible_zs->( $i, $z, $w ) ) {
                    $newzs{ $z0 }++;
                    $result{ $z0 } = [$w];
                    push @{ $result{ $z0 } }, @{ $result{$z} } if exists $result{$z};
                }
            }
        }
        %zs = %newzs;
    }
    return join '', @{ $result{0} };
};

printf "Part 1: %s\n", $solve->('max');
printf "Part 2: %s\n", $solve->('min');

# ************************************ END SOLUTION ***********************************

# Example data:
# my $lines = q(
# inp w
# add z w
# mod z 2
# div w 2
# add y w
# mod y 2
# div w 2
# add x w
# mod x 2
# div w 2
# mod w 2
# );
# @lines = grep { length $_ } split "\n", $lines;

my $alu = { 'w' => 0, 'x' => 0, 'y' => 0, 'z' => 0 };

my $opr = {
    'inp' => sub {
                    my ( $a ) = @_;
                    return sub { $alu->{$a} = shift @{ $_[0] } };
                 },
    'add' => sub {
                    my ( $a, $b ) = @_;
                    return sub {
                        $b = $alu->{$b} if $b =~ /^[wxyz]$/;
                        $alu->{$a} += $b;
                    };
                 },
    'mul' => sub {
                    my ( $a, $b ) = @_;
                    return sub {
                        $b = $alu->{$b} if $b =~ /^[wxyz]$/;
                        $alu->{$a} *= $b;
                    };
                 },
    'div' => sub {
                    my ( $a, $b ) = @_;
                    return sub {
                        $b = $alu->{$b} if $b =~ /^[wxyz]$/;
                        die "Can't divide by zero" if $b == 0;
                        $alu->{$a} = int( $alu->{$a} / $b );
                    };
                 },
    'mod' => sub {
                    my ( $a, $b ) = @_;
                    return sub {
                        $b = $alu->{$b} if $b =~ /^[wxyz]$/;
                        die "Can't modulo negatives" if $alu->{$a} < 0;
                        die "Can't modulo negatives" if $b <= 0;
                        $alu->{$a} %= $b;
                    };
                 },
    'eql' => sub {
                    my ( $a, $b ) = @_;
                    return sub {
                        $b = $alu->{$b} if $b =~ /^[wxyz]$/;
                        $alu->{$a} = ( $alu->{$a} == $b ) ? 1 : 0;
                    };
                 },
};

my @cmd_stack;
foreach (@lines) {
    my ( $cmd, @input ) = split ' ';
    push @cmd_stack, $opr->{$cmd}->(@input);
}

my $execute = sub {
    my $args = \@_;
    $alu = { 'w' => 0, 'x' => 0, 'y' => 0, 'z' => 0 };  # reset
    $_->($args) foreach @cmd_stack;
    return $alu->{z};
};

# find the largest valid fourteen-digit model number that contains no 0 digits
# (validity indicated by a zero in 'z' after execution completes)

my $search = sub {
    my $num = join '', map { 9 } ( 1..14 );  # start with largest fourteen-digit number

    while (1) {
        $num-- and next if $num =~ /0/;
        warn $num if $num % 100000 == 99999;
        $execute->(split '', $num);
        last if $alu->{z} == 0;  # $num is "valid"
        $num--;
    }
    return $num;
};

# This is an exact implementation of the ALU as described in the problem
# statement, but it will take an extremely long time to find the requested
# maximum valid value for MONAD. Can we speed it up with state caching?

my %s_cache;
my $cache_alu = sub { $s_cache{$_[0]} = $alu };

{   @cmd_stack = ();
    my $prev_input;
    my $skip_to_next_input = 0;
    $opr = {
        'inp' => sub {
                        my ( $a ) = @_;
                        return sub {
                            $skip_to_next_input = 0;
                            $alu->{$a} = shift @{ $_[0] };
                            # we should note which register was used,
                            # but the MONAD program always uses 'w'
#                           $prev_input = sprintf '%s:%s', $a, $alu->{$a};
                            $prev_input = $alu->{$a};
                            if ( $s_cache{ $prev_input } ) {
                                $alu = $s_cache{ $prev_input };
                                $skip_to_next_input = 1;
                            }
                        };
                     },
        'add' => sub {
                        my ( $a, $b ) = @_;
                        return sub {
                            return if $skip_to_next_input;
                            $b = $alu->{$b} if $b =~ /^[wxyz]$/;
                            $alu->{$a} += $b;
                        };
                     },
        'mul' => sub {
                        my ( $a, $b ) = @_;
                        return sub {
                            return if $skip_to_next_input;
                            $b = $alu->{$b} if $b =~ /^[wxyz]$/;
                            $alu->{$a} *= $b;
                        };
                     },
        'div' => sub {
                        my ( $a, $b ) = @_;
                        return sub {
                            return if $skip_to_next_input;
                            $b = $alu->{$b} if $b =~ /^[wxyz]$/;
                            die "Can't divide by zero" if $b == 0;
                            $alu->{$a} = int( $alu->{$a} / $b );
                        };
                     },
        'mod' => sub {
                        my ( $a, $b ) = @_;
                        return sub {
                            return if $skip_to_next_input;
                            $b = $alu->{$b} if $b =~ /^[wxyz]$/;
                            die "Can't modulo negatives" if $alu->{$a} < 0;
                            die "Can't modulo negatives or zeroes" if $b <= 0;
                            $alu->{$a} %= $b;
                        };
                     },
        'eql' => sub {
                        my ( $a, $b ) = @_;
                        return sub {
                            return if $skip_to_next_input;
                            $b = $alu->{$b} if $b =~ /^[wxyz]$/;
                            $alu->{$a} = ( $alu->{$a} == $b ) ? 1 : 0;
                        };
                     },
    };

    foreach (@lines) {
        my ( $cmd, @input ) = split ' ';
        if ( $cmd eq 'inp' ) {
            push @cmd_stack, sub { $cache_alu->( $prev_input ) if defined $prev_input };
        }
        push @cmd_stack, $opr->{$cmd}->(@input);
    }
    # one more cache save and reset at end of program
    push @cmd_stack, sub { $cache_alu->( $prev_input ) if defined $prev_input;
                           $prev_input = undef };
}

# This does seem to cut our computation time roughly in half, but that's still too long.
#
# Furthermore, it doesn't seem to agree with the results from our solution above, so
# maybe there's a bug somewhere? The lack of discrete examples in today's problem made
# constructing a solution harder than it could have been. At any rate, I'm saving what
# I wrote here so that I can maybe salvage it later.
