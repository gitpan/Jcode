#!/usr/local/bin/perl
#
# $Id: Makefile.PL,v 0.55 1999/07/22 17:31:29 dankogai Exp $
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

