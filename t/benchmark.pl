#!/usr/local/bin/perl

use Benchmark;

my $count = $ARGV[0] || 16;

timethese($count, 
	  {
	       'jcode.pl'  => \&jcode_test,
               'Jcode.pm' => \&Jcode_test,
	  });

sub jcode_test{
    require "jcode.pl";
    open F, "t/table.euc" or die "$!";
    while(<F>){
      &jcode::convert(\$_, 'jis');
    }
}

sub Jcode_test{
    use Jcode;
    open F, "t/table.euc" or die "$!";
    $j = new Jcode;
    while(<F>){
	$j->set(\$_)->jis;
    }
}

