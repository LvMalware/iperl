#!/usr/bin/env perl

use warnings;
use Term::ReadLine;
use Term::ANSIColor;

my $VERSION = 0.3;

#Display warnings
$SIG{__WARN__} = \&handle_warnings;

my $term = Term::ReadLine->new('IPerl');
$term->bind_key(ord "\ci", 'tab-insert');
$term->add_defun('multiline_code', \&multiline_code, ord "\ct");

print "Hello, " . getlogin() . ".\n";
print "This is IPerl version $VERSION, running Perl $^V .\n";
print "Press CTRL+T to enter multi-line code, stop with CTRL+D .\n";
print "Press CTRL+C to exit.\n\n";

do
{
    $_ = $term->readline(color('blue') . "IPerl" . color('white') . ">" . color('reset') . " ") || '';
    my $output = eval($_) || " ";
    print(color('red') . "ERROR: " . color('reset') .  $@ . "\n") if $@;
    print($output . "\n") if $output;
}
while (1);

sub handle_warnings
{
    print color('yellow'). "WARNING: " . color('reset') . $_[0] . "\n" 
}

sub multiline_code
{
    print "\n";
    $term->ornaments(0);
    my $code = '';
    do
    {
        $_ = $term->readline("...  ");
        $code .= $_ if $_;
    }
    while ($_);
    print "\n";
    my $output = eval($code);
    print(color('red') . "ERROR: " . color('reset') .  $@ . "\n") if $@;
    print($output . "\n") if $output;
    $term->ornaments(1);
}