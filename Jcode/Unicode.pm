#
# $Id: Unicode.pm,v 0.30 1999/07/12 22:07:47 dankogai Exp dankogai $
#

#package Jcode::Unicode;

package Jcode;
use Jcode::Constants qw(:all);
use Jcode::Unicode::Constants;
use Carp;
use strict;

sub ucs2_euc{
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    my $u2e = \%Jcode::Unicode::Constants::_U2E;

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
    my $e2u = \%Jcode::Unicode::Constants::_E2U;

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

