#!/usr/bin/perl
#
# 入口
#
use strict;
use Jcode;
BEGIN {
    if ($] < 5.008001){
        print "1..0 # Skip: Perl 5.8.1 or later required\n";
        exit 0;
    }
    require Test::More;
    Test::More->import(tests => 2);
}


my $str = '漢字、カタカナ、ひらがなの入ったString';
my $re_hira = "([ぁ-ん]+)";
my $j = jcode($str, 'euc');
my ($match) = $j->m($re_hira);
is($match, "ひらがなの", qq(m//));
$j->s("カタカナ","片仮名");
$j->s("ひらがな","平仮名");
is("$j", "漢字、片仮名、平仮名の入ったString", "s///");

__END__

