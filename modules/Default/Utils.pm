package Default::Utils;
use warnings;
use base 'Exporter';
our @EXPORT = qw(str2hex hex2str strxor);

sub str2hex
{
    my ($str) = @_;
    join '', map { sprintf "%02x", ord $_ } split //, $str;
}

sub hex2str
{
    my ($hex) = @_;
    join '', map { chr hex $_ } $hex =~ /.{2}/g;
}

sub strxor
{
    my ($txt, $key) = sort { length($b) <=> length($a) } @_;
    join '', map {
        chr(ord(substr($txt, $_)) ^ ord(substr($key, $_ % length($key))))
    } 0 .. length($txt) - 1
}

1;