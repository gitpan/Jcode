#!/usr/bin/perl
#
# ����
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


my $str = '�������������ʡ��Ҥ餬�ʤ����ä�String';
my $re_hira = "([��-��]+)";
my $j = jcode($str, 'euc');
my ($match) = $j->m($re_hira);
is($match, "�Ҥ餬�ʤ�", qq(m//));
$j->s("��������","�Ҳ�̾");
$j->s("�Ҥ餬��","ʿ��̾");
is("$j", "�������Ҳ�̾��ʿ��̾�����ä�String", "s///");

__END__

