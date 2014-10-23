#!/usr/bin/perl
#

use strict;
use Jcode;
use Test;
BEGIN { plan tests => 7 }

my $seq = 0;
sub myok{ # overloads Test::ok;
    my ($a, $b, $comment) = @_;
    print "not " if $a ne $b;
    ++$seq;
    print "ok $seq # $comment\n";
}

my $file;

my $hiragana; $file = "t/hiragana.euc"; open F, $file or die "$file:$!";
read F, $hiragana, -s $file;

my $katakana; $file = "t/zenkaku.euc"; open F, $file or die "$file:$!";
read F, $katakana, -s $file;

my $stripped; $file = "t/stripped.euc"; open F, $file or die "$file:$!";
read F, $stripped, -s $file;

my %code2str = 
    (
     'A-Za-z��-��-��' =>  $katakana,
     'a-zA-Z��-��-��' =>  $hiragana,
     );

# by Value

for my $icode (keys %code2str){
    for my $ocode (keys %code2str){
        my $ok;
        my $str = $code2str{$icode};
        my $out = jcode(\$str)->tr($icode, $ocode)->euc;
        myok($out,$code2str{$ocode}, 
             "H2Z: $icode -> $ocode");
    }
}

# test tr($s,'','d');

myok(jcode($hiragana)->tr('��-��','','d')->euc, $stripped,
      "H2Z: '��-��', '', d");

my $s = '���£á��ģţ�';
my $from = '��-�ڡ�';

myok(jcode( $s, 'euc' )->tr( $from, 'A-Z/' )->euc,  'ABC/DEF', "tr");
myok(jcode( $s, 'euc' )->tr( $from, 'A-Z\/' )->euc, 'ABC\DEF', "tr");
__END__
