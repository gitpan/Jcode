#!/usr/local/bin/perl
#
# $Id: Makefile.PL,v 0.69 2001/05/11 15:45:36 dankogai Exp dankogai $
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

