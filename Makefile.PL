#!/usr/local/bin/perl
#
# $Id: Makefile.PL,v 0.74 2001/07/16 18:42:55 dankogai Exp dankogai $
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

