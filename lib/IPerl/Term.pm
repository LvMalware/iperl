package IPerl::Term {

    use strict;
    use warnings;
    use IO::Handle;
    use Term::ReadKey;
    use parent 'Exporter';

    our @EXPORT = qw(
        ctrl_key ARROW_UP ARROW_DOWN ARROW_RIGHT ARROW_LEFT BACKSPACE
        HOME_KEY DEL_KEY PAGE_UP PAGE_DOWN END_KEY
    );

    use constant {
        TAB_KEY     => 9,
        BACKSPACE   => 127,
        ARROW_UP    => 300 + ord('A'),
        ARROW_DOWN  => 300 + ord('B'),
        ARROW_RIGHT => 300 + ord('C'),
        ARROW_LEFT  => 300 + ord('D'),
        HOME_KEY    => 400 + ord('1'),
        DEL_KEY     => 400 + ord('3'),
        END_KEY     => 400 + ord('4'),
        PAGE_UP     => 400 + ord('5'),
        PAGE_DOWN   => 400 + ord('6'),
    };

    my @reserved_words = qw(
        abs and accept atan2 bind binmode break chomp chop chr close
        closedir connect continue cos crypt  delete die do each eof eval
        exec exists exit exp fc fileno flock for fork format getc getpeername
        getsockname getsockopt grep hex if import index int join keys kill last
        lc lcfirst length listen listModules loadModule lock long map my next
        oct or ord pack package pipe pop pos print printf push quotemeta rand
        read readdir readline recv ref refreshModules require return reverse
        rewinddir rindex say scalar searchModule seek seekdir select send
        setsockopt shift shutdown sin socket socketpair sort splice split
        sprintf sqrt srand study sub substr syscall sysread sysseek system
        syswrite tell telldir truncate uc ucfirst unpack unshift use values
        wait waitpid warn while write
    );

    sub ctrl_key {
        my ($key) = (@_);
        ord($key) & 0x1F;
    }

    sub new {
        my ($self, %args) = @_;
        bless { 
            history => {
                filename => $args{historyfile} || undef,
                current  => undef,
                lines    => [],
                size     => 0,
            },
         }, $self;
    }

    sub bind_keys {
        my ($self, %bindings) = @_;
        while (my ($key, $coderef) = each %bindings)
        {
            $self->{keybindings}->{$key} = $coderef;
        }
    }

    sub disable_raw_mode {
        my ($self) = @_;
        ReadMode 0;
    }

    sub completion_array {
        my ($self, $arrayref) = @_;
        $self->{completion_words} = $arrayref if $arrayref;
        $self->{completion_words}
    }

    sub get_completions {
        my ($self, $base) = @_;
        my $query = quotemeta($base || return undef);
        my $array = $self->{completion_words} || [];
        my @match = grep(/^$query/, @reserved_words, @{$array});
        @match
    }

    sub history_load {
        my ($self, $filename) = @_;
        $self->history_file($filename) || return 0;
        open(my $hist, "<", $self->{history}->{filename}) || return 0;
        while (my $line = <$hist>)
        {
            chomp($line);
            next unless length($line);
            $self->history_add($line);
        }

        close($hist);
        1
    }

    sub history_file {
        my ($self, $filename) = @_;
        $self->{history}->{filename} = $filename if $filename;
        $self->{history}->{filename};
    }

    sub history_save {
        my ($self, $filename) = @_;
        
        $self->history_file($filename) || return 0;
        
        open(my $hist, ">", $self->history_file($filename)) || return 0;
        
        for (my $i = 0; $i < $self->{history}->{size}; $i ++)
        {
            print $hist $self->{history}->{lines}->[$i], "\n";
        }

        close($hist);
                
        1;
    }

    sub history_add {
        my ($self, $line) = @_;
        push @{ $self->{history}->{lines} }, $line;
        $self->{history}->{current} = ++ $self->{history}->{size};
    }
    
    sub history_previous {
        my ($self) = @_;
       
        my $index = $self->{history}->{current};
        return undef unless defined($index);
        
        if ($index == 0)
        {
            $self->{history}->{current} = $self->{history}->{size} - 1;
            return undef;
        }
        else
        {
            $self->{history}->{current} = -- $index;
        }
        
        $self->{history}->{lines}->[$index];
    }

    sub history_next {
        my ($self) = @_;
        my $index = $self->{history}->{current};
        return undef if !defined($index);
        return undef if $index + 1 >= $self->{history}->{size};
        $self->{history}->{current} = ++ $index;
        $self->{history}->{lines}->[$index];
    }

    sub readkey {
        my ($self) = @_;
        READ_KEYS:
        my $key = ord(ReadKey(0));
        if ($key == 0x1b) #Escape sequence
        {
            my $s0 = ord(ReadKey(0)) || next;
            my $s1 = ord(ReadKey(0)) || next;
            if ($s0 == 0x5b) {  #[
                if ($s1 >= 0x30 && $s1 <= 0x39) {
                    my $s2 = ord(ReadKey(0)) || next;
                    if ($s2 == 0x7e)
                    {
                        return HOME_KEY  if $s1 == 0x31 || $s1 == 0x37;
                        return END_KEY   if $s1 == 0x34 || $s1 == 0x38;
                        return DEL_KEY   if $s1 == 0x33;
                        return PAGE_UP   if $s1 == 0x35;
                        return PAGE_DOWN if $s1 == 0x36;
                    }
                    elsif (($s2 >= 0x30 && $s2 <= 0x39) || $s2 == 0x3b)
                    {
                        my $ans = chr($s1) . chr($s2);
                        $ans .= ReadKey(0) until $ans =~ /(\d+);(\d+)R$/;
                        if ($self)
                        {
                            $self->{pos_y} = $1;
                            $self->{pos_x} = $2;
                        }
                        goto READ_KEYS
                    }
                }
                else
                {
                    return ARROW_UP    if $s1 == 0x41; #A
                    return ARROW_DOWN  if $s1 == 0x42; #B
                    return ARROW_RIGHT if $s1 == 0x43; #C
                    return ARROW_LEFT  if $s1 == 0x44; #D
                    return END_KEY     if $s1 == 0x46; #F
                    return HOME_KEY    if $s1 == 0x48; #H
                }
            }
            elsif ($s0 == 0x4f) #O
            {
                return END_KEY if $s1 == 0x46;  #F
                return HOME_KEY if $s1 == 0x48; #H
            }
        }

        return $key;
    }

    sub update_syntax
    {
        my ($self, $len, $code) = @_;
        return (1, "") unless length($code);
        my $render = "";
        my $lcolor = 0;
        my $in_str = 0;
        my $is_var = 0;
        my $in_com = 0;
        my $is_esc = 0;
        my $nlines = 1;
        my $width  = $self->width();
        
        my $i = $width;
        
        while ($i <= $len + length($code))
        {
            substr($code, $i - $len, 0) = "\r\n";
            $i += $width + 2;
            $nlines ++;
        }

        for my $word (split /\b{wb}/, $code)
        {
            my $ncolor = 0;
            my $w = quotemeta($word);

            if ($word eq "\n")
            {
                $render .= "\r\n\x1b[$lcolor;1m";
                next;
            } elsif ($in_str) {
                $ncolor = 32;
                if ($word eq '\\') {
                    $is_esc = 1
                } elsif ($is_esc) {
                    $is_esc = 0;
                } elsif ($word eq $in_str) {
                    $in_str = 0;
                }
            } elsif ($in_com) {
                $ncolor = 30;
            } elsif ($word =~ /^\d+\.?\d*$/ || $word =~ /^0x[\da-f]+$/i) {
                $ncolor = 31;
            } elsif ($is_var) {
                $is_var = 0;
                $ncolor = 35;
            } elsif (grep(/^$w$/, @reserved_words)) {
                $ncolor = 34;
            } elsif ($word eq "'" or $word eq '"') {
                $in_str = $word;
                $ncolor = 32;
            } elsif ($word eq "#") {
                $ncolor = 30;
                $in_com = 1;
            } elsif ($word eq '$' or $word eq '@' or $word eq '%') {
                $is_var = 1;
                $ncolor = 35;
            }

            if ($ncolor != $lcolor) {
                $lcolor = $ncolor;
                $render .= "\x1b[$ncolor;1m";
            }

            $render .= $word;
        }
        ($nlines, $render)
    }

    sub width {
        my ($self) = @_;
        my ($w, $h) = GetTerminalSize();
        $w
    }

    sub height {
        my ($self) = @_;
        my ($w, $h) = GetTerminalSize();
        $h
    }

    sub add_log {
        my ($msg) = @_;
        open(my $o, ">>log") || return;
        print $o $msg, "\n";
        close($o);
    }

    sub cursor_position {
        my ($self) = @_;
        return ($self->{pos_y}, $self->{pos_x});
    }

    sub readline {
        my ($self, $prompt) = @_;
        my $plen   = length($prompt || '');
        my $width  = $self->width();
        my $height = $self->height();
        my $buffer = "";
        my $plines = 1;
        my $cindex = 0;
        my $sugest = 0;
        my $down_y = 1;
        my $extra  = "";
        my $c_y    = 1;
        my $c_x    = $plen;

        ReadMode 5;
        
        print "\x1b[0;1m$prompt\x1b[6n" if $prompt;

        while (1) {
  
            $width = $self->width();
            $height = $self->height();
            
            my $c = $self->readkey();

            if ($c == 10 || $c == 13) {
                print "\r\n";
                last;
            } elsif ($c == TAB_KEY) {
                my $base = (split(/\b{wb}/, substr($buffer, 0, $cindex)))[-1];
                next unless $base;
                my @possible = $self->get_completions($base);
                if (@possible == 1)
                {
                    substr($buffer, $cindex - length($base), length($base)) = $possible[0];
                    $cindex += length($possible[0]) - length($base);
                }
                elsif (@possible > 1)
                {
                    $sugest = 1;
                    $extra = substr("@possible", 0, $width);
                }
            } elsif ($c > 0 && $c < 27) {
                #CTRL_{KEY}
                my $key = sprintf("CTRL_%c", $c + 64);
                my $callback = $self->{keybindings}->{$key} || next;
                $callback->($c);
            } elsif ($c == HOME_KEY) {
                #go to start of line
                $cindex = 0;
                $c_y = 1;
            } elsif ($c == END_KEY) {
                #go to end of line
                $cindex = length($buffer);
                $c_y = int(($plen + length($buffer) + $width - 1) / $width);
                $c_y ++ if ($plen + $cindex) % $width == 0;
            } elsif ($c == ARROW_UP) {
                $buffer = $self->history_previous() || next;
                $cindex = length($buffer);
                $c_y = int(($plen + length($buffer) + $width - 1) / $width);
            } elsif ($c == ARROW_DOWN) {
                $buffer = $self->history_next() || next;
                $cindex = length($buffer);
                $c_y = int(($plen + length($buffer) + $width - 1) / $width);
            } elsif ($c == ARROW_LEFT) {
                #move cursor to the left
                $c_y -- if $c_x == 1;
                $cindex -- if $cindex;
            } elsif ($c == ARROW_RIGHT) {
                #move cursor to the right
                $cindex ++ if $cindex < length($buffer);
                $c_y ++ if $c_x == $width;
            } elsif ($c == BACKSPACE) {
                #erase previous char
                substr($buffer, -- $cindex, 1) = "" if $cindex > 0;
                $c_y -- if $c_x == 1;
            } elsif ($c == DEL_KEY) {
                #erase next char
                $cindex ++ if $cindex < length($buffer);
                substr($buffer, -- $cindex, 1) = "" if $cindex > 0;
            } else {
                substr($buffer, $cindex ++, 0) = chr($c);
                $c_y ++ if $c_x >= $width;
            }
            
            #get the position of the cursor on the x axis
            $c_x = ($plen + $cindex) % $width + 1;
            #highlight the syntax and get the number of lines
            my ($nlines, $render) = $self->update_syntax($plen, $buffer);
            #add 1 to down_y if we have an extra line for completion
            $down_y += $sugest;
            #get the cursor position
            my ($row, $col) = $self->cursor_position();
            #if we are at the very end of the screen, print a newline
            print "\r\n" if $row >= $height;
            #go to the last row used before
            my $printable = "\x1b[${down_y}B" if $down_y;
            #clear every row, going up
            $printable .= "\x1b[0G\x1b[0K\x1b[1A" x ($plines + $sugest);
            #clear the current row and reset colors
            $printable .= "\x1b[0G\x1b[0K\x1b[0;1m";
            #add the prompt
            $printable .= $prompt if $prompt;
            #add the rendered buffer
            $printable .= $render;
            #add the suggestions line if completing
            $printable .= "\r\n$extra" if length($extra) > 0;
            #position the cursor on the x axis
            $printable .= "\x1b[${c_x}G";
            #position the cursor on the y axis
            my $up = $sugest + ($nlines - $c_y);
            $printable .= "\x1b[${up}A" if $up > 0;
            #reset colors
            $printable .= "\x1b[0;1m";
            #request cursor position
            $printable .= "\x1b[6n";
            #update the number of lines under the cursor
            $down_y = ($nlines - $c_y) + 1;
            #update the number of lines previously used
            $plines = $nlines;
            #reset extra to an empty string
            $extra = "";
            #reset sugest to 0
            $sugest = 0;
            #print everything at once to avoid glitches
            print $printable;
        }
        
        ReadMode 0;
        
        $self->history_add($buffer);

        return $buffer;
    }

    sub enable_raw_mode {
        my ($self) = @_;
        ReadMode 5;
    }
    
    END {
        print "\r\n";
        disable_raw_mode();
    }
}
1;
