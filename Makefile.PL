#!/usr/local/bin/perl
#
# $Id: Makefile.PL,v 0.57 1999/07/26 15:45:59 dankogai Exp dankogai $
#

use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME         => 'Jcode',
     VERSION_FROM => 'Jcode.pm',
     PREREQ_PM     => {
	 'MIME::Base64'     => "2.1",
     }
     );	       

