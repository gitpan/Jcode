#!/usr/local/bin/perl

use ExtUtils::testlib;
use Benchmark;

$| = 1;


print "Jcode Loading...\n";
require Jcode;
$Jcode::DEBUG = 1;
print "done.\n";

my $euc = `cat t/table.euc` or die "$!";
my $ucs2 = Jcode->new($euc)->ucs2;
my $utf8 = Jcode->new($euc)->utf8;

my $count = $ARGV[0] || 16;

timethese($count, {
    "utf8->ucs2" =>  \&utf8_ucs2,
    "ucs2->utf8" =>  \&ucs2_utf8,
    "euc->ucs2"  =>  \&euc_ucs2,
    "ucs2->euc"  =>  \&ucs2_euc,
    }
	  );


sub utf8_ucs2{
    &Jcode::utf8_ucs2($utf8);
}

sub ucs2_utf8{
    &Jcode::ucs2_utf8($ucs2);
}

sub euc_ucs2{
    &Jcode::euc_ucs2($ucs2);
}

sub ucs2_euc{
    &Jcode::ucs2_euc($ucs2);
}
