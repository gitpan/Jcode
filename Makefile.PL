#!/usr/local/bin/perl
#
# $Id: Makefile.PL,v 0.58 1999/07/27 10:59:48 dankogai Exp dankogai $
#

use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME         => 'Jcode',
     VERSION_FROM => 'Jcode.pm',
     PREREQ_PM    => {
	 'MIME::Base64'     => "2.1",
     }
     );	       

