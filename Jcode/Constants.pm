#
# $Id: Constants.pm,v 0.30 1999/07/12 22:07:47 dankogai Exp dankogai $
#

package Jcode::Constants;
require 5.000;
use Carp;
use strict;

BEGIN {
    use Exporter;
    use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw(%CHARCODE %ESC %RE);
    %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK, @EXPORT ] );
}

use vars @EXPORT_OK;

my %_0208 = (
	       1978 => '\e\$\@',
	       1983 => '\e\$B',
	       1990 => '\e&\@\e\$B',
		);

%CHARCODE = (
	     UNDEF_SJIS => '\x81\xac', # ¢®
	     UNDEF_JIS  => '\xa2\xf7', # ¢÷ -- used in unicode
	     UNDEF_UNICODE  => '\x20\x20', # ¢÷ -- used in unicode
	 );

%ESC =  (
	 JIS_0208 => "\e\$B",
	 JIS_0212 => "\e\$(D",
	 ASC      => "\e\(B",
	 KANA     => "\e\(I",
	 );

%RE =
    (
     BIN       => '[\000-\006\177\377]',
     EUC_0212  => '\217[\241-\376][\241-\376]',
     EUC_C     => '[\241-\376][\241-\376]',
     EUC_KANA  => '\216[\241-\337]',
     JIS_0208  =>  "$_0208{1978}|$_0208{1983}|$_0208{1990}",
     JIS_0212  => "\e" . '\$\(D',
     JIS_ASC   => "\e" . '\([BJ]',     
     JIS_KANA  => "\e" . '\(I',
     SJIS_C    => '[\201-\237\340-\374][\100-\176\200-\374]',
     SJIS_KANA => '[\241-\337]',
     );

#
# Util. Functions
#

# Make buffer when and only when necessary

sub Jcode::_mkbuf {
    my $thingy = shift;
    if (ref $thingy){
	return $thingy;
    }
    else{ 
	my $buf = $thingy;
	return \$buf;
    }
}

sub Jcode::_max {
    my $result = shift;
    for my $n (@_){
	$result = $n if $n > $result;
    }
    return $result;
}

1;

