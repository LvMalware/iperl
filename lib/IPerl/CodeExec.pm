package IPerl::CodeExec;

#all code will be evaluated inside this scope, protecting both the user code
#and IPerl's internal code from conflicts. All functions and variables defined
#here will be acessible to the user at runtime through the input code.

#this variable holds a list of all the IPerl modules that are avaiable. These
#can be updated using refreshModules(), listed using listModules() and searched
#using searchModule().
@MODULES_LIST = ();

$IPERL_INSTANCE = undef;

sub __evaluate
{
    #evaluates the input code, returning the output, errors and warnings
    #NOTE: no variables are declared here to avoid conflicts with user code
    (eval($_[0]) || "", $@, $^W)
}

#Some functions to deal with IPerl modules
sub searchModule
{
    my ($pattern) = @_;
    refreshModules() unless @MODULES_LIST;
    my @found = grep(/$pattern/, @MODULES_LIST);
    return @found if wantarray;
    if (@found > 0)
    {
        print "[*] The following modules match the search pattern:\n";
        print "[+] $_\n" for (@found);
    }
    else
    {
        print "[-] No modules where found that match your search pattern\n";
    }
}

sub loadModule
{
    my (@modules) = @_;
    for my $module (@modules)
    {
        my @export = eval <<USE;
        require $module;
        $module->import();
        \@$module\:\:EXPORT
USE
        print "[!] Can't load module $module\n" if $@;
        $IPERL_INSTANCE->add_completion(@export) if $IPERL_INSTANCE && @export;
    }
}

sub listModules
{
    refreshModules() unless @MODULES_LIST;
    return @MODULES_LIST if wantarray;
    print "[*] Avaiable modules:\n";
    print "[+] $_\n" for (@MODULES_LIST);
}

sub refreshModules
{
    return unless $INC{IPERL_MODULES};
    @MODULES_LIST = ();
    my @list = @{$INC{IPERL_MODULES}};
    my $path = shift @list;
    my @dir_queue = ($path);
    while (@dir_queue || @list)
    {
        my $current = @dir_queue ? (shift @dir_queue) : ($path = shift @list);
        push @dir_queue, glob("$current/*") if -d $current;
        if (-f $current && $current =~ /\.pm$/i)
        {
            my $name = substr($current, length($path) + 1);
            $name =~ s/\//::/g;
            push @MODULES_LIST, $name =~ s/(\.pm)$//ir;
        }
    }
    @MODULES_LIST
}

1;
