#!/usr/bin/env perl
use strict;
use warnings;
use lib './lib';
use IPerl;

my $VERSION = "1.1";
# Color sequences
my $OFF     = "\033[0m";
my $RED     = "\033[31;1m";
my $BLUE    = "\033[34;1m";
my $GREEN   = "\033[32;1m";
my $YELLOW  = "\033[33;1m";
my $whoami  = getlogin();

my $intro = <<INTRO;
Hello, ${GREEN}${whoami}${OFF} !!!
This is ${BLUE}IPerl${OFF} version $VERSION, running ${BLUE}Perl ${YELLOW}$^V${OFF}.
Type ${RED}exit${OFF} to exit.
INTRO

my $interpreter = IPerl->new(path => [ "./modules" ]);
$interpreter->run(intro => $intro);
