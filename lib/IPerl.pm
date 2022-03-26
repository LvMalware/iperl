package IPerl;
use JSON;
use strict;
use warnings;
use lib './';
use IPerl::Term;
use IPerl::CodeExec;

our $VERSION = "1.2.1";

# Color sequences
my $OFF     = "\033[0;1m";
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
    my $prompt  = $args{prompt} || "IPerl";
    my $history = $args{history} || "$ENV{HOME}/.iperl_history";
    my $config  = $args{configfile} || "$ENV{HOME}/.iperl_config.json";
    my $default = $args{default};
    
    if (-f $config && open(my $file, "<$config"))
    {
        my $conf = decode_json(join '', <$file>);
        $history = $conf->{history} if $conf->{history};
        $default = $conf->{default} if $conf->{default};
        $prompt  = $conf->{prompt} if $conf->{prompt};
        push @{$path}, @{$conf->{path}} if $conf->{path};
    }
    elsif ($config)
    {
        print "${RED}ERROR${OFF}: Can't load config file '$config'\n";
        if (open(my $file, ">$config"))
        {
            print $file encode_json({
                history => $history,
                prompt  => $prompt,
                path    => $path
            }), "\n";
            close $file;
        }
    }
    my $term    = IPerl::Term->new(historyfile => $history);
    $term->history_load();
    bless {
        path => $path, prompt => $prompt, history => $history,
        term => $term, config => $config,
        default => $default,
    }, $self;
}

sub bind_keys {
    my ($self, %bindings) = @_;
    $self->{term}->bind_keys(%bindings);
}

sub read_code {
    my ($self) = @_;
    my $term = $self->{term};
    my $prompt = $self->{prompt} . "> ";
    my $block = "";
    my @stack = ();
    my %terminators = (
        '}' => '{',
        ']' => '[',
        ')' => '(',
    );

    my $syntax_wrong = 0;
    my $in_str = "";
    
    my $prompt2 = "..." . " " x (length($prompt) - 3);

    my $instr = undef;

    while (1) {
        my $code = $term->readline($prompt);
        next unless $code;
        for (my $i = 0; $i < length($code); $i ++) {
            my $sym = substr($code, $i, 1);
            if ($sym eq '\\') {
                $i ++;
                next
            }
            
            if (defined($instr)) {
                $instr = undef if $instr eq $sym;
                next;
            }

            my $esc = quotemeta($sym);

            if (grep(/$esc/, qw(' "))) {
                $instr = $sym;
            } elsif (grep(/$esc/, values %terminators)) {
                push @stack, $sym;
                $prompt = $prompt2;
            } elsif (grep(/$esc/, keys %terminators)) {
                if (@stack == 0 || $terminators{$sym} ne $stack[-1])
                {
                    $syntax_wrong = 1;
                    last;
                }
                pop @stack;
            }
        }
        $block .= $code;
        next if $instr && !$syntax_wrong;
        last if $syntax_wrong || @stack == 0;
    }

    $syntax_wrong = $syntax_wrong || @stack > 0;

    ($block, $syntax_wrong);
}

sub run {
    my ($self, %args) = @_;
    #print the intro
    print $args{intro}, "\n" if $args{intro};
    #get the IPerl::Term instance
    my $term = $self->{term};
    #get a reference to a completion array
    $self->{custom_completion} = $term->completion_array([]);
    #support for IPerl modules
    $INC{IPERL_MODULES} = $self->{path};
    #add the modules to the path
    unshift @INC, @{$self->{path}};

    #Give IPerl::CodeExec access to the current running IPerl instance
    $IPerl::CodeExec::IPERL_INSTANCE = $self;
    #load default modules
    IPerl::CodeExec::loadModule(@{$self->{default}}) if $self->{default};

    while (1)
    {
        my ($block, $wrong) = $self->read_code();
        if ($wrong) {
            print "${RED}Syntax error${OFF}\n";
            next;
        }
        #add user-defined function names to the completion list
        $self->add_completion(map { $1 } $block =~ /sub ([\d\w_]+)/g);
        #save the history at each command
        $term->history_save();
        #evaluate the user code on a different scope to avoid conflicts with
        #identifiers of the IPerl internal code
        my ($output, $error, $warning) = IPerl::CodeExec::__evaluate($block);
        #
        print "\n";
        print $GREEN, $output, $OFF, "\n" if length($output);
        print "${RED}ERROR${OFF}: $error\n" if $error;
        print "${YELLOW}WARNING${OFF}: $warning" if $warning;
    }
}

sub add_completion
{
    my ($self, @words) = @_;
    my $list = $self->{custom_completion};
    for my $name (@words)
    {
        my $search = quotemeta($name);
        push @{$list}, $name unless grep(/^$search$/, @{$list});
    }
}

1;
