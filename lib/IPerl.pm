package IPerl;
use strict;
use warnings;
use lib './';
use Term::ReadLine;
use IPerl::CodeExec;

my $VERSION = "2.0";

# Color sequences
my $OFF     = "\033[0m";
my $RED     = "\033[31;1m";
my $BLUE    = "\033[34;1m";
my $GREEN   = "\033[32;1m";
my $WHITE   = "\033[37;1m";
my $PURPLE  = "\033[35;1m";
my $YELLOW  = "\033[33;1m";

sub new
{
    my ($self, %args) = @_;
    my $path    = $args{path};
    my $prompt  = $args{"prompt"} || "IPerl";
    my $history = $args{"history"} || "$ENV{HOME}/.iperl_history";
    my $term    = Term::ReadLine->new($prompt);
    my $attr    = $term->Attribs;
    $term->ornaments(0);
    $term->read_history($history);
    $term->using_history();
    $attr->{completion_entry_function} = $attr->{list_completion_function};
    $attr->{completion_word} = [
        qw(
            chomp chop chr crypt fc hex index lc lcfirst length oct
            ord pack q// qq// reverse rindex sprintf substr tr/// uc
            ucfirst y/// m// pos qr// quotemeta s/// split study print
            abs atan2 cos exp hex int long oct rand sin sqrt srand each
            keys pop push shift splice unshift grep join map qw// reverse 
            sort unpack delete each exists values binmode close closedir
            dbmclose dbmopen die eof fileno flock format getc printf read
            readdir readline rewinddir say seek seekdir select syscall
            sysread sysseek syswrite tell telldir truncate warn write break
            if next return last exit continue kill fork exec system pipe
            wait waitpid lock scalar do require import use ref package
            accept bind connect getpeername getsockname getsockopt listen
            recv send setsockopt shutdown socket socketpair eval
            searchModule listModules refreshModules
        )
    ];
    bless {
        path => $path, prompt => $prompt, history => $history,
        term => $term, term_attribs => $attr
    }, $self;
}

sub run
{
    my ($self, %args) = @_;
    #
    print $args{intro}, "\n" if $args{intro};
    #
    my $words = $self->{term_attribs}->{completion_word};
    #support for IPerl modules
    $INC{IPERL_MODULES} = $self->{path};
    unshift @INC, $self->{path};
    
    #load default modules
    for (IPerl::CodeExec::searchModule('^Default::.+'))
    {
        IPerl::CodeExec::__evaluate("use $_") ;
    }
    
    while (1)
    {
        my $code = $self->{term}->readline("$self->{prompt}> ");
        next unless $code;
        #check if the input is a multi-line code (I'll need to refact this later)
        if ($code =~ /(\{|\(|\[)$/)
        {
            do
            {
                $_ = $self->{term}->readline("... ");
                $code .= $_ if $_
            } while ($_);
        }
        #add user-defined function names to the completion list
        $self->add_completion(map { $1 } $code =~ /sub ([\d\w_]+)/g);
        #save the history at each command
        $self->{term}->write_history($self->{history});
        #evaluate the user code on a different scope to avoid conflicts with
        #identifiers of the IPerl internal code
        my ($output, $error, $warning) = IPerl::CodeExec::__evaluate($code);
        #
        print $GREEN, $output, $OFF, "\n" if $output;
        print "${RED}ERROR${OFF}: $error\n" if $error;
        print "${YELLOW}WARNING${OFF}: $warning" if $warning;
    }
}

sub add_completion
{
    my ($self, @words) = @_;
    my $list = $self->{term_attribs}->{completion_word};
    for (@words)
    {
        push @{$list}, $1 unless grep(/^$1$/, @{$list});
    }
}

1;