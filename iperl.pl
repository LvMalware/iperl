#!/usr/bin/env perl

use warnings;
use Term::ReadLine;

my $VERSION = "1.0";

# Color sequences
my $OFF     = "\033[0m";
my $RED     = "\033[31;1m";
my $BLUE    = "\033[34;1m";
my $GREEN   = "\033[32;1m";
my $WHITE   = "\033[37;1m";
my $PURPLE  = "\033[35;1m";
my $YELLOW  = "\033[33;1m";


#Display warnings
$SIG{__WARN__} = \&handle_warnings;
#Save history before exiting
$SIG{INT}      = IGNORE;

$| = 1;
my $history = "$ENV{HOME}/.iperl_history";
my $whoami  = getlogin();
my $prompt  = "${BLUE}IPerl$OFF";


my $term = Term::ReadLine->new('IPerl');
$term->ornaments(0);
$term->add_defun('multiline_code', \&multiline_code, ord "\ct");
$term->read_history($history);
$term->using_history;

my $attribs = $term->Attribs;
$attribs->{completion_entry_function} = $attribs->{list_completion_function};
#from perldoc perlfunc
my @completion_words = qw(
    chomp chop chr crypt fc hex index lc lcfirst length oct ord pack q// qq//
    reverse rindex sprintf substr tr/// uc ucfirst y/// m// pos qr// quotemeta
    s/// split study print abs atan2 cos exp hex int long oct rand sin sqrt 
    srand each keys pop push shift splice unshift grep join map qw// reverse 
    sort unpack delete each exists values binmode close closedir dbmclose
    dbmopen die eof fileno flock format getc printf read readdir readline
    rewinddir say seek seekdir select syscall sysread sysseek syswrite tell
    telldir truncate warn write break if next return last exit continue kill
    fork exec system pipe wait waitpid lock scalar do require import use ref
    package accept bind connect getpeername getsockname getsockopt listen recv
    send setsockopt shutdown socket socketpair eval
);
$attribs->{completion_word} = \@completion_words;


sub main
{
    print <<WELCOME;
Hello, ${GREEN}${whoami}${OFF} !!!
This is $prompt version $VERSION, running ${BLUE}Perl ${YELLOW}$^V${OFF}.
Press ${RED}CTRL+T${OFF} to enter multi-line code, stop with ${RED}CTRL+D${OFF}.
Type ${RED}exit${OFF} to exit.

WELCOME

    while (1)
    {
        my $line = $term->readline("$prompt> ") || '';
        if ($line =~ /\{$/)
        {
            multiline_code($line);
            next;
        }
        execute_code($line);
    }

    0;
}

sub execute_code
{
    my ($code) = @_;
    if ($code eq 'exit')
    {
        $term->write_history($history);
        exit 0;
    }
    my $output = eval($code) || "";
    if ($@)
    {
        print("${RED}ERROR: $OFF$@\n");
    }
    else
    {
        while ($code =~ /sub ([\d\w_]+)/ig)
        {
            push @completion_words, $1 unless grep(/^$1$/, @completion_words);
        }
    }
    
    print("${GREEN}${output}${OFF}\n") if $output;
}

sub handle_warnings
{
    print "${YELLOW}WARNING: ${OFF}$_[0]\n" 
}

sub multiline_code
{
    my ($start) = @_;
    print "\n";
    my $code = $start ? $start : '';
    do
    {
        print "${PURPLE}... ${OFF}";
        $_ = $term->readline("");
        $code .= $_ if $_;
    }
    while ($_);
    print "\n";
    execute_code($code);
}

exit main;
