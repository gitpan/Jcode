#
# $Id: Unicode.pm,v 0.40 1999/07/15 18:26:18 dankogai Exp dankogai $
#

=head1 NAME

Jcode::Unicode - Aux. routines for Jcode

=head1 DESCRIPTION

This module is called by Jcode.pm on demand.  This module is not intended for
direct use by users.  This modules implements functions related to Unicode.  
Following functions are defined here;

=item Jcode::ucs2_euc();

=item Jcode::euc_ucs2();

=item Jcode::ucs2_utf8();

=item Jcode::utf8_ucs2();

=item Jcode::euc_utf8();

=item Jcode::utf8_euc();

=cut

package Jcode::Unicode;

use strict;
use vars qw($RCSID $VERSION);

$RCSID = q$Id: Unicode.pm,v 0.40 1999/07/15 18:26:18 dankogai Exp dankogai $;
$VERSION = do { my @r = (q$Revision: 0.40 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Carp;

use Jcode::Constants qw(:all);
use Jcode::Unicode::Constants;

use vars qw(%_U2E %_E2U $PEDANTIC);

=head1 VARIABLES

=item B<$Jcode::Unicode::PEDANTIC>

When set to non-zero, x-to-unicode conversion becomes pedantic.  
That is, '\' (chr(0x5c)) is converted to zenkaku backslash and 
'~" (chr(0x7e)) to JIS-x0212 tilde.

By Default, Jcode::Unicode leaves ascii ([0x00-0x7f]) as it is.

=cut

$PEDANTIC = 0;

sub _init_u2e{
    unless ($PEDANTIC){
	$_U2E{"\xff\x3c"} = "\xa1\xc0"; # ¡À
    }else{
	delete $_U2E{"\xff\x3c"};
	$_U2E{"\x00\x5c"} = "\xa1\xc0";     #\
	$_U2E{"\x00\x7e"} = "\x8f\xa2\xb7"; # ~
    }
}

sub _init_e2u{
    unless (%_E2U){
	%_E2U = reverse %_U2E; # init only once!
    }
    unless ($PEDANTIC){
	$_E2U{"\xa1\xc0"} = "\xff\x3c"; # ¡À
    }else{
	delete $_E2U{"\xa1\xc0"};
	$_E2U{"\xa1\xc0"} = "\x00\x5c";     #\
	$_E2U{"\x8f\xa2\xb7"} = "\x00\x7e"; # ~
    }
}


# Yuck! but this is necessary because this module is 'require'd 
# instead of being 'use'd (No package export done) subs below
# belong to Jcode, not Jcode::Unicode

package Jcode;

sub ucs2_euc{
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    &Jcode::Unicode::_init_u2e;
    my $u2e = \%Jcode::Unicode::_U2E;

    $$r_str =~ s(
		 [\x00-\xff][\x00-\xff]
		 )
    {
	exists $u2e->{$&} ? $u2e->{$&} : $CHARCODE{UNDEF_JIS};
    }geox;

    $$r_str;
}

sub euc_ucs2{
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    &Jcode::Unicode::_init_e2u;
    my $e2u = \%Jcode::Unicode::_E2U;

    # 3 bytes
    $$r_str =~ s(
		 $RE{EUC_0212}|$RE{EUC_C}|$RE{EUC_KANA}|[\x00-\xff]
	      )
    {
	exists $e2u->{$&} ? $e2u->{$&} : $CHARCODE{UNDEF_UNICODE};
    }geox;

    $$r_str;
}

sub euc_utf8{
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    euc_ucs2($r_str);
    ucs2_utf8($r_str);
}

sub utf8_euc{
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    utf8_ucs2($r_str);
    ucs2_euc($r_str);
}

sub ucs2_utf8{
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    my $result;
    for my $uc (unpack("n*", $$r_str)) {
	if ($uc < 0x80) {
	    # 1 byte representation
	    $result .= chr($uc);
	} elsif ($uc < 0x800) {
	    # 2 byte representation
	    $result .= chr(0xC0 | ($uc >> 6)) .
		chr(0x80 | ($uc & 0x3F));
	} else {
	    # 3 byte representation
	    $result .= chr(0xE0 | ($uc >> 12)) .
		chr(0x80 | (($uc >> 6) & 0x3F)) .
		    chr(0x80 | ($uc & 0x3F));
	}
	
    }
    $$r_str = $result;
}

sub utf8_ucs2{
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    my $result;
    $$r_str =~ s/^[\200-\277]+//o;  # can't start with 10xxxxxx
    while (length $$r_str) {
	if ($$r_str =~ s/^([\000-\177]+)//o) {
	    $result .= pack("n*", unpack("C*", $1));
	} 
	elsif ($$r_str =~ s/^([\300-\337])([\200-\277])//o) {
	    my ($b1,$b2) = (ord($1), ord($2));
	    $result .= pack("n", (($b1 & 0x1F)<<6)|($b2 & 0x3F));
	} 
	elsif ($$r_str =~ s/^([\340-\357])([\200-\277])([\200-\277])//o)
	{
	    my ($b1,$b2,$b3) = (ord($1), ord($2), ord($3));
	    $result .= 
		pack("n", 
		     (($b1 & 0x0F)<<12)|(($b2 & 0x3F)<<6)|($b3 & 0x3F));
	} else {
	    croak "Bad UTF-8 data";
	}
    }
    $$r_str = $result;
}

1;
__END__

=head1 BUGS

This module is slow on initialization because it has to load entire
UCS2 to EUC table (and vice versa when necessary).  Once inited, the
speed is OK.

As you might have guessed, EUC <-> UTF8 conversion is implemented as 
EUC <-> UCS2 <-> UTF8 conversion so performance sucks.


=head1 SEE ALSO

=item L<Jcode::Unicode::Constants>

=item http://www.unicode.org/

=head1 COPYRIGHT

Copyright 1999 Dan Kogai <dankogai@dan.co.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
