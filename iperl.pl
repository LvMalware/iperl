#!/usr/bin/env perl

use warnings;
use Term::ReadLine;
use Term::ANSIColor;

#Display warnings
$SIG{__WARN__} = \&handle_warnings;

my $term = new Term::ReadLine 'IPerl';

my $command;

do
{
    $command = $term->readline(color('blue') . "IPerl" . color('white') . ">" . color('reset') . " ");
    exit if $command =~ /^exit(\(\))|;$/;
    my $output = eval($command);
    print(color('red') . "ERROR: " . color('reset') .  $@ . "\n") if $@;
    print($output . "\n") if $output;
}
while ($command !~ /^exit(\(\))|;$/);

sub handle_warnings
{
    print color('yellow'). "WARNING: " . color('reset') . $_[0] . "\n" 
}