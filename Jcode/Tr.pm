#
# $Id: Tr.pm,v 0.35 1999/07/14 16:35:43 dankogai Exp dankogai $
#

package Jcode::Tr;
use strict;
use Carp;
use Jcode::Constants qw(:all);

use vars qw(%_TABLE);

sub tr {
    # $prev_from, $prev_to, %table are persistent variables
    my ($r_str, $from, $to, $opt) = @_;
    my (@from, @to);
    my $n = 0;

    undef %_TABLE;
    &_maketable($from, $to, $opt);

    $$r_str =~ s(
		 [\200-\377][\000-\377]|[\000-\377]
		 )
    {defined($_TABLE{$&}) && ++$n ? 
	 $_TABLE{$&} : $&}ogex;

    return $n;
}

sub _maketable {
    my ($from, $to, $opt) = @_;
    my ($ascii) = '(\\\\[\\-\\\\]|[\0-\133\135-\177])';

    grep(s/(([\200-\377])[\200-\377]-\2[\200-\377])/&_expnd2($1)/geo,
	 $from,$to);
    grep(s/($ascii-$ascii)/&_expnd1($1)/geo,
	 $from,$to);

    my @to   = $to   =~ /[\200-\377][\000-\377]|[\000-\377]/go;
    my @from = $from =~ /[\200-\377][\000-\377]|[\000-\377]/go;
    push(@to, ($opt =~ /d/ ? '' : $to[$#to]) x (@from - @to)) if @to < @from;
    @_TABLE{@from} = @to;
}

sub _expnd1 {
    my ($str) = @_;
    s/\\(.)/$1/og;
    my($c1, $c2) = unpack('CxC', $str);
    if ($c1 <= $c2) {
        for ($str = ''; $c1 <= $c2; $c1++) {
            $str .= pack('C', $c1);
        }
    }
    return $str;
}

sub _expnd2 {
    my ($str) = @_;
    my ($c1, $c2, $c3, $c4) = unpack('CCxCC', $str);
    if ($c1 == $c3 && $c2 <= $c4) {
        for ($str = ''; $c2 <= $c4; $c2++) {
            $str .= pack('CC', $c1, $c2);
        }
    }
    return $str;
}

1;
