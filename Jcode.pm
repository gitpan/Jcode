#
# $Id: Jcode.pm,v 0.40 1999/07/15 18:26:18 dankogai Exp dankogai $
#

package Jcode;
require 5.004;

use strict;
use vars qw($RCSID $VERSION);

$RCSID = q$Id: Jcode.pm,v 0.40 1999/07/15 18:26:18 dankogai Exp dankogai $;
$VERSION = do { my @r = (q$Revision: 0.40 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Carp;

=head1 NAME

Jcode - Japanese Charset Handler

=head1 SYNOPSIS

use Jcode;

# traditional

Jcode::convert(\$str, $ocode, $icode, "z");

# or OOP!

print Jcode->new($str)->h2z->tr($from, $to)->utf8;

=cut

BEGIN {
    use Exporter;
    use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA         = qw(Exporter);
    @EXPORT      = qw(jcode getcode);
    @EXPORT_OK   = qw($RCSID $VERSION $DEBUG $USE_CACHE);
    %EXPORT_TAGS = ( all => [ @EXPORT_OK, @EXPORT ] );
}

use vars @EXPORT_OK;

$DEBUG = 0;
$USE_CACHE = 1;

print $RCSID, "\n" if $DEBUG;

use Jcode::Constants qw(:all);

my %_S2E = ();
my %_E2S = ();

use overload 
    '""' => sub { ${$_[0]->{r_str}} },
    '==' => sub {overload::StrVal($_[0]) eq overload::StrVal($_[1])},
    fallback => 1,
    ;

=head1 DESCRIPTION

Jcode.pm supports both object and traditional approach.  
With object approach, you can go like;

$iso_2022_jp = Jcode::new($str)->h2z->jis;

Which is more elegant than;

$iso_2022_jp = &jcode::convert(\$str,'jis',jcode::getcode(\str), "z");

For those unfamiliar with objects, Jcode.pm still supports getcode() and convert().

=head1 Methods

Methods mentioned here all return Jcode object unless otherwise mentioned.

=over 4

=item $j = Jcode->new($str [, $icode]);

Creates Jcode object $j from $str.  Input code is automatically checked 
unless you explicitly set $icode (This is necessary if you want to 
convert from UTF8). 

The object keeps the string in EUC format enternaly.  When the object 
itself is evaluated, it returns the EUC-converted string so you can 
"print $j;" without calling access method if you are using EUC 
(thanks to function overload).

Just like most of perl objects, Jcode object is just a reference to hash so you can retrieve its guts via $j->{whatever}.

Instead of scalar value, You can use reference as

Jcode->new(\$str);

This saves time a little bit.  In exchange of the value of $str being 
converted. (In a way, $str is now "tied" to jcode object).

=cut

sub new {
    my $class = shift;
    my ($thingy, $icode) = @_;
    my $r_str = _mkbuf($thingy);
    my $nmatch;
    ($icode, $nmatch) = getcode($r_str) unless $icode;
    convert($r_str, 'euc', $icode);
    my $self = {
	r_str    => $r_str,
	icode  => $icode,
	nmatch => $nmatch,
    };
    carp "Object of class $class created" if $DEBUG >= 2;
    bless $self, $class;
}

=item $j->set($str [, $icode]);

Sets $j's internal string to $str.  Handy when you use Jcode object repeatedly 
(saves time and memory to create object). 

# converts mailbox to SJIS format

my $jconv = new Jcode;
while(<>){print $jconv->set(\$_)->mime_decode->sjis;}

=cut

sub set {
    my $self = shift;
    my ($thingy, $icode) = @_;
    my $r_str = _mkbuf($thingy);
    my $nmatch;
    ($icode, $nmatch) = getcode($r_str) unless $icode;
    convert($r_str, 'euc', $icode);
    $self->{r_str}  = $r_str;
    $self->{icode}  = $icode;
    $self->{nmatch} = $nmatch;
    return $self;
}

=item $j->append($str [, $icode]);

Appends $str to $j's internal string.

=cut

sub append {
    my $self = shift;
    my ($thingy, $icode) = @_;
    my $r_str = _mkbuf($thingy);
    my $nmatch;
    ($icode, $nmatch) = getcode($r_str) unless $icode;
    convert($r_str, 'euc', $icode);
    ${$self->{r_str}}   .= $$r_str;
    $self->{icode}       = $icode;
    $self->{nmatch}      = $nmatch;
    return $self;
}

=item $j = jcode($str [, $icode]);

shortcut for Jcode->new() so you can go like;

$sjis = jcode($str)->sjis;

=item $euc = $j->euc;

=item $jis = $j->jis;

=item $sjis = $j->sjis;

What you code is what you get :)

=cut

sub jcode { return Jcode->new(@_) }
sub euc   { return ${$_[0]->{r_str}} }
sub jis   { return  &euc_jis(${$_[0]->{r_str}})}
sub sjis  { return &euc_sjis(${$_[0]->{r_str}})}

=item $iso_2022_jp = j$str->iso_2022_jp

Same as $j->z2h->jis.  
Hankaku Kanas are forcibly converted to Zenkaku.

=cut

sub iso_2022_jp{return $_[0]->h2z->jis}

=head2 Methods that use MIME::Base64

To use methods below, you need MIME::Base64.  To install, simply

perl -MCPAN C<-e> 'CPAN::Shell->install("MIME::Base64")'

=item $mime_header = $j->mime_encode;

Converts $str to MIME-Header documented in RFC1522.

=cut

sub mime_encode{
    require MIME::Base64; # not use
    my $self = shift;
    my $jis = $self->iso_2022_jp;
    my $base64 = MIME::Base64::encode_base64($jis, "");
    return '=?ISO-2022-JP?B?' . $base64 .  '?=';
}

=item $j->mime_decode;

Decodes MIME-Header in Jcode object.

You can retrieve the number of matches via $j->{nmatch};

=cut

sub mime_decode{
    require MIME::Base64; # not use
    my $self = shift;
    my $r_str = $self->{r_str};
    $self->{nmatch} = 
	(
	 $$r_str =~ s(
		      =\?[Ii][Ss][Oo]-2022-[Jj][Pp]\?[Bb]\?
		      ([A-Za-z0-9\+\/]+=*)
		      \?=
		      )
	 {
	     jis_euc(MIME::Base64::decode_base64($1));
	 }ogex
	 );
    $self;
}

=head2 Methods implemented by Jcode::H2Z

Methods here are actually implemented in Jcode::H2Z.

=item $j->h2z([$keep_dakuten]);

Converts X201 kana (Hankaku) to X208 kana (Zenkaku).  
When $keep_dakuten is set, it leaves dakuten as is
(That is, "ka + dakuten" is left as is instead of
being converted to "ga")

You can retrieve the number of matches via $j->{nmatch};

=cut

sub h2z {
    require Jcode::H2Z; # not use
    my $self = shift;
    $self->{nmatch} = Jcode::H2Z::h2z($self->{r_str}, @_);
    return $self;
}

=item $j->z2h;

Converts X208 kana (Zenkaku) to X201 kana (Hankazu).

You can retrieve the number of matches via $j->{nmatch};

=cut

sub z2h {
    require Jcode::H2Z; # not use
    my $self = shift;
    $self->{nmatch} =  &Jcode::H2Z::z2h($self->{r_str}, @_);
    return $self;
}

=head2 Methods implemented in Jcode::Tr

Methods here are actually implemented in Jcode::Tr.

=item  $j->tr($from, $to);

Applies tr on Jcode object. $from and $to can contain EUC Japanese.

You can retrieve the number of matches via $j->{nmatch};

=cut

sub tr{
    require Jcode::Tr; # not use
    my $self = shift;
    $self->{nmatch} = Jcode::Tr::tr($self->{r_str}, @_);
    return $self;
}

=head2 Methods implemented in Jcode::Unicode

See L<Jcode::Unicode> for details

=item $ucs2 = $j->ucs2;

Returns UCS2 (Raw Unicode) string.

=cut

sub ucs2{
    require Jcode::Unicode;
    euc_ucs2(${$_[0]->{r_str}});
}

=item $ucs2 = $j->utf8;

Returns utf8 String.

=cut

sub utf8{
    require Jcode::Unicode;
    euc_utf8(${$_[0]->{r_str}});
}

=head1 Traditional Way

=item ($code, [$nmatch]) = getcode($str);

Returns char code of $str. When array context is used instead of
scaler, it also returns how many character codes are found.  
As mentioned above, $str can be \$str instead.

Warning:  UTF8 is not automatically detected!

jcode.pl Users:
This function is 100% upper-conpatible with jcode::getcode() -- well, almost;

* When its return value is an array, the order is the opposite;  jcode::getcode() returns $nmatch first.

* jcode::getcode() returns 'undef' when the number of EUC characters is equal to that of SJIS.  Jcode::getcode() returns EUC.  for Jcode.pm is no in-betweens.

=cut

sub getcode {
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    my ($code, $nmatch, $sjis, $euc) = ("", 0, 0, 0);
    
    if ($$r_str =~ /$RE{BIN}/o) {	# 'binary'
	my $ucs2;
	$ucs2 += length($1)
	    while $$r_str =~ /(\x00\w)+/go;
	if ($ucs2){      # smells like raw unicode 
	    $nmatch = $ucs2;
	    $code   = 'ucs2';
	}else{
	    $nmatch = 0;
	    $code = 'binary';
	 }
    }
    elsif ($$r_str !~ /[\e\200-\377]/o) {	# not Japanese
	$nmatch = 0;
	$code = undef;
    }				# 'jis'
    elsif ($$r_str =~ /$RE{JIS_0208}|$RE{JIS_0212}|$RE{JIS_ASC}|$RE{JIS_KANA}/o) {
	$nmatch = 1;
	$code = 'jis';
    }
    else {			# should be 'euc' or 'sjis'
	# use of (?:) by Hiroki Ohzaki <ohzaki@iod.ricoh.co.jp>
	$sjis += length($1) 
	    while $$r_str =~ /((?:$RE{SJIS_C})+)/go;
	$euc  += length($1) 
	    while $$r_str =~ /((?:$RE{EUC_C}|$RE{EUC_KANA}|$RE{EUC_0212})+)/go;
	$nmatch = _max($sjis, $euc);
	carp ">DEBUG:sjis = $sjis, euc = $euc" if $DEBUG >= 3;
	$code = $sjis > $euc ? 'sjis' : 'euc';
    }
    return wantarray ? ($code, $nmatch) : $code;
}

=item Jcode::convert($str, [$ocode, $icode, $opt]);

Converts $str to char code specified by $ocode.  When $icode is specified
also, it assumes $icode for input string instead of the one checked by
getcode(). As mentioned above, $str can be \$str instead.

jcode.pl Users:
This function is 100% upper-conpatible with jcode::convert() !

=cut

sub convert{
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    my ($ocode, $icode, $opt) = @_;

    my $nmatch;
    ($icode, $nmatch) = getcode($r_str) unless $icode;

    return $$r_str if $icode eq $ocode; # do nothin'

    no strict qw(refs);
    my $method;

    # convert to EUC

    require Jcode::Unicode if $icode =~ /ucs2|utf8/o;
    if ($icode and defined &{$method = $icode . "_euc"}){
	carp "Dispatching \&$method" if $DEBUG >= 2;
	&{$method}($r_str) ;
    }

    # h2z or z2h

    if ($opt){
	my $cmd = ($opt =~ /^z/o) ? "h2z" : ($opt =~ /^h/o) ? "z2h" : undef;
	if ($cmd){
	    require Jcode::H2Z;
	    &{'Jcode::H2Z::' . $cmd}($r_str);
	}
    }
    
    # convert to $ocode

    require Jcode::Unicode if $ocode =~ /ucs2|utf8/o;
    if ($ocode and defined &{$method = "euc_" . $ocode}){
	carp "Dispatching \&$method" if $DEBUG >= 2;
	&{$method}($r_str) ;
    }
    $$r_str;
}

# JIS<->EUC

sub jis_euc {
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    $$r_str =~ s(
		 ($RE{JIS_0212}|$RE{JIS_0208}|$RE{JIS_ASC}|$RE{JIS_KANA})
		 ([^\e]*)
		 )
    {
	my ($esc, $str) = ($1, $2);
	if ($esc !~ /$RE{JIS_ASC}/o) {
	    $str =~ tr/\x21-\x7e/\xa1-\xfe/;
	    if ($esc =~ /$RE{JIS_KANA}/o) {
		$str =~ s/([\xa1-\xdf])/\x8e$1/og;
	    }
	    elsif ($esc =~ /$RE{JIS_0212}/o) {
		$str =~ s/([\xa1-\xfe][\xa1-\xfe])/\x8f$1/og;
	    }
	}
	$str;
    }geox;
    $$r_str;
}

#

sub euc_jis {
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    $$r_str =~ s{
	($RE{EUC_C}|$RE{EUC_KANA}|$RE{EUC_0212})+
	}
    {
	my $str = $&;
	my $esc = ($str =~ tr/\x8e//d) ?	$ESC{KANA} : 
	    ($str =~ tr/\x8f//d) ? $ESC{JIS_0212} : $ESC{JIS_0208};
	$str =~ tr/\xa1-\xfe/\x21-\x7e/;
	$esc . $str . $ESC{ASC}
    }geox;
    $$r_str;
}

# EUC<->SJIS

sub sjis_euc {
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    $$r_str =~ s(
		 $RE{SJIS_C}|$RE{SJIS_KANA}
	     )
    {
	unless ($_S2E{$&}){
	    my ($c1, $c2) = unpack('CC', $&);
	    if (0xa1 <= $c1 && $c1 <= 0xdf) {
		$c2 = $c1;
		$c1 = 0x8e;
	    } elsif (0x9f <= $c2) {
		$c1 = $c1 * 2 - ($c1 >= 0xe0 ? 0xe0 : 0x60);
		$c2 += 2;
	    } else {
		$c1 = $c1 * 2 - ($c1 >= 0xe0 ? 0xe1 : 0x61);
		$c2 += 0x60 + ($c2 < 0x7f);
	    }
	    $_S2E{$&} = pack('CC', $c1, $c2);
	}
	$_S2E{$&};
    }geox;
    $$r_str;
}

#

sub euc_sjis {
    my $thingy = shift;
    my $r_str = _mkbuf($thingy);
    $$r_str =~ s(
		 $RE{EUC_C}|$RE{EUC_KANA}|$RE{EUC_0212}
		 )
    {
	unless ($_E2S{$&}){
	    my ($c1, $c2) = unpack('CC', $&);
	    if ($c1 == 0x8e) {          # SS2
		$_E2S{$&} = chr($c2);
	    } elsif ($c1 == 0x8f) {     # SS3
		$_E2S{$&} = $CHARCODE{UNDEF_SJIS};
	    }else { #SS1 or X0208
		if ($c1 % 2) {
		    $c1 = ($c1>>1) + ($c1 < 0xdf ? 0x31 : 0x71);
		    $c2 -= 0x60 + ($c2 < 0xe0);
		} else {
		    $c1 = ($c1>>1) + ($c1 < 0xdf ? 0x30 : 0x70);
		    $c2 -= 2;
		}
		$_E2S{$&} = pack('CC', $c1, $c2);
	    }
	}
	$_E2S{$&};
    }geox;
    $$r_str;
}

#

1;

__END__

=head1 BUGS

=item Unicode support by Jcode is far from efficient!

=head1 ACKNOWLEDGEMENTS

This package owes a lot in motivation, design, and code, to the jcode.pl 
for Perl4 by Kazumasa Utashiro <utashiro@iij.ad.jp>.

Hiroki Ohzaki <ohzaki@iod.ricoh.co.jp> has helped me polish regexp from the 
very first stage of development.

=head1 SEE ALSO

=item L<Jcode::Constants>

=item L<Jcode::H2Z>

=item L<Jcode::Tr>

=item L<Jcode::Unicode>

=head1 COPYRIGHT

Copyright 1999 Dan Kogai <dankogai@dan.co.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Unicode conversion table in Jcode::Unicode::Constants is based on files at 
ftp://ftp.unicode.org/Public/MAPPINGS/EASTASIA/JIS/, 
Copyright (c) 1991-1994 Unicode, Inc.

=cut

CREDITS from jcode.pl
;######################################################################
;#
;# jcode.pl: Perl library for Japanese character code conversion
;#
;# Copyright (c) 1995-1999 Kazumasa Utashiro <utashiro@iij.ad.jp>
;# Internet Initiative Japan Inc.
;# 3-13 Kanda Nishiki-cho, Chiyoda-ku, Tokyo 101-0054, Japan
;#
;# Copyright (c) 1992,1993,1994 Kazumasa Utashiro
;# Software Research Associates, Inc.
;#
;# Original version was developed under the name of srekcah@sra.co.jp
;# February 1992 and it was called kconv.pl at the beginning.  This
;# address was a pen name for group of individuals and it is no longer
;# valid.
;#
;# Use and redistribution for ANY PURPOSE, without significant
;# modification, is granted as long as all copyright notices are
;# retained.  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND
;# ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.
;#
;######################################################################
