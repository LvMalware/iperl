#!/usr/bin/env perl
use strict;
use warnings;
use lib './lib';
use IPerl;

my $VERSION = $IPerl::VERSION;
# Color sequences
my $OFF     = "\033[0;1m";
my $RED     = "\033[31;1m";
my $BLUE    = "\033[34;1m";
my $GREEN   = "\033[32;1m";
my $YELLOW  = "\033[33;1m";
my $whoami  = getlogin();

my $intro = <<INTRO;
${OFF}Hello, ${GREEN}${whoami}${OFF} !!!
This is ${BLUE}IPerl${OFF} version ${YELLOW}$VERSION${OFF}, running ${BLUE}Perl ${YELLOW}$^V${OFF}.
Press ${RED}CTRL+Q${OFF} or type ${RED}exit${OFF} to exit.
INTRO

my $interpreter = IPerl->new(path => [ "./modules" ]);
$interpreter->bind_keys(CTRL_Q => sub { exit(0) });
$interpreter->run(intro => $intro);
