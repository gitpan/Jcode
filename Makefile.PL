#!/usr/local/bin/perl
#
# $Id: Makefile.PL,v 0.72 2001/05/31 15:36:07 dankogai Exp dankogai $
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

