#
# Run this script once and you are all set!
#

use strict;
use File::Path;
use File::Basename;

my $install_dir = "";

for my $INC (@INC){
    if ($INC =~ /site/io){
	$install_dir = $INC;
	last;
    }
}

unless ($install_dir) {
    die qq(Please create 'site/lib' folder in ActivePerl folder!\n);
}else{
    warn "Ok. I'll install files in $install_dir folder.\n";
}

my @files = qw(
	       Jcode.pm
	       );

# push all files in Jcode directory;

require "find.pl";
&find('Jcode');

sub wanted {
    no strict "vars";
    my ($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_);
    return unless -f _;
    push @files, $name;
}


for my $file (@files) {
    my $src = $file;
    open SRC, $src or die "$src:$!";
    my $buffer;

    my $dst = $install_dir . "/" . $file;
    # $dst =~ s/:://og;
    warn "Installing $src to $dst.\n";

    my $dir = dirname($dst);
    mkpath([$dir], 0755, 1) or die "$dir:$!" unless -d $dir;
    open DST, ">$dst" or die "$dst:$!";

    while(read SRC, $buffer, 32768) {
	$buffer =~ s/\x0a/\x0d\x0a/og;
	print DST $buffer;
    }

    close SRC; close DST;
    # MacPerl::SetFileInfo('McPL', 'TEXT', $dst);

}

warn "All scripts are installed successfully\n";

__END__
