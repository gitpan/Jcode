#!/usr/local/bin/perl
#
# $Id: Makefile.PL,v 2.0 2005/05/16 19:08:08 dankogai Exp dankogai $
#
use strict;
use ExtUtils::MakeMaker;

my @EXTRA;
$] >= 5.008001
    and @EXTRA = (
		  NORECURS => 1,
		  PM => { 'Jcode.pm' =>  '$(INST_LIB)/Jcode.pm',
			  'Jcode/Nihongo.pod'
			  => '$(INST_LIB)/Jcode/Nihongo.pod'
		      },
		  );

WriteMakefile
    (
     NAME         => 'Jcode',
     VERSION_FROM => 'Jcode.pm',
     PREREQ_PM    => {
	 'MIME::Base64'     => "2.1",
     },
     ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Jcode.pm', # retrieve abstract from module
       AUTHOR     => 'Dan Kogai <dankogai@dan.co.jp>') : ()
      ),
     @EXTRA,
     );	       

