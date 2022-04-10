package IPerl::Term {
    use strict;
    use warnings;
    use IO::File;
    use Term::Size;
    use Term::ReadKey;

    use constant {
        TAB_KEY     => 0x09,
        ESC_KEY     => 0x1b,
        BACKSPACE   => 0x7f,
        ARROW_UP    => 300 + ord('A'),
        ARROW_DOWN  => 300 + ord('B'),
        ARROW_RIGHT => 300 + ord('C'),
        ARROW_LEFT  => 300 + ord('D'),
        HOME_KEY    => 400 + ord('1'),
        DEL_KEY     => 400 + ord('3'),
        END_KEY     => 400 + ord('4'),
        PG_UP       => 400 + ord('5'),
        PG_DOWN     => 400 + ord('6'),
    };

    my @reserved_words = qw(
        abs and accept atan2 bind binmode break chomp chop chr close
        closedir connect constant continue cos crypt  delete die do each eof
        eval eq exec exists exit exp fc fileno flock for fork format getc
        getpeername getsockname getsockopt grep hex if import index int join
        keys kill last lc lcfirst length listen listModules loadModule lock
        long map my ne next oct open or ord pack package pipe pop pos print
        printf push quotemeta rand read readdir readline recv ref refreshModules
        require return reverse rewinddir rindex say scalar searchModule seek
        seekdir select send setsockopt shift shutdown sin socket socketpair sort
        splice split sprintf sqrt srand study sub substr syscall sysread sysseek
        system syswrite tell telldir truncate uc ucfirst unpack unshift use
        values wait waitpid warn while write
    );

    sub new {
        my ($self, %args) = @_;
        bless {
            raw     => 0,
            history => {
                filename    => $args{histfile} || undef,
                current     => undef,
                lines       => [],
                size        => 0,
                file        => 0,
            },
        }, $self;
    }

    sub bind_keys {
        my ($self, %bindings) = @_;
        while (my ($key, $coderef) = each %bindings) {
            next if $key eq "CTRL_T" || $key eq "CTRL_U" || $key eq "CTRL_D";
            $self->{keybindings}->{$key} = $coderef;
        }
    }

    sub raw_mode {
        my ($self) = @_;
        ReadMode ($self->{raw} ^= 5);
        unless ($SIG{WINCH}) {
            $SIG{WINCH} = sub {
                $self->update_term();
            };
            $self->update_term();
        }
    }

    sub read_key {
        my ($self) = @_;
        READING:
        my $key = ord(ReadKey(0));
        if ($key == 0x1b) {
            # escape sequence
            my $a = ord(ReadKey(0)) || next;
            my $b = ord(ReadKey(0)) || next;
            if ($a == 0x5b) {
                # [
                if ($b >= 0x30 && $b <= 0x39) {
                    my $c = ord(ReadKey(0)) || next;
                    if ($c == 0x7e) {
                        return HOME_KEY if $b == 0x31 || $b == 0x37;
                        return END_KEY  if $b == 0x34 || $b == 0x38;
                        return DEL_KEY  if $b == 0x33;
                        return PG_DOWN  if $b == 0x36;
                        return PG_UP    if $b == 0x35;
                    } elsif (($c >= 0x30 && $c <= 0x39) || $c == 0x3b) {
                        my $xy = chr($b) . chr($c);
                        $xy .= ReadKey(0) until $xy =~ /(\d+);(\d+)R$/;
                        if ($self) {
                            $self->{cx} = $1;
                            $self->{cy} = $2;
                        }
                        goto READING
                    }
                }
                return ARROW_UP    if $b == 0x41;
                return ARROW_DOWN  if $b == 0x42;
                return ARROW_RIGHT if $b == 0x43;
                return ARROW_LEFT  if $b == 0x44;
                return END_KEY     if $b == 0x46;
                return HOME_KEY    if $b == 0x48;
            } elsif ($a == 0x4f) {
                return END_KEY  if $b == 0x46;
                return HOME_KEY if $b == 0x48;
            }
        }
        $key
    }

    sub completion_array {
        my ($self, $arrayref) = @_;
        $self->{completions} = $arrayref if $arrayref;
        $self->{completions}
    }

    sub get_completions {
        my ($self, $base) = @_;
        my $query = quotemeta($base || return undef);
        my $array = $self->{completions} || [];
        my @match = grep(/^$query/, @reserved_words, @{$array});
        @match
    }

    sub history_file {
        my ($self, $filename) = @_;
        $self->{history}->{filename} = $filename if $filename;
        $self->{history}->{filename};
    }

    sub history_save {
        my ($self, $filename) = @_;
        $filename = $self->history_file($filename);
        unless (my $hist = $self->{history}->{file}) {
            open($hist, ">", $filename);
        }
        for my $line ($self->{history}->{lines}->@*) {
            print $hist $line, "\n";
        }

        close($hist);
                
        1;
    }

    sub history_add {
        my ($self, $line) = @_;
        push @{ $self->{history}->{lines} }, $line;
        $self->{history}->{current} = ++ $self->{history}->{size};
        my $hist = $self->{history}->{file} || return 0;
        print $hist $line, "\n";
    }

    sub history_load {
        my ($self, $filename) = @_;
        $filename = $self->history_file($filename) || return 0;
        my $hist = IO::File->new($filename, "a+") || return 0;
        while (my $line = <$hist>) {
            chomp($line);
            next unless length($line);
            $self->history_add($line);
        }
        $self->{history}->{file} = $hist;
        1
    }

    sub history_next {
        my ($self) = @_;
        my $index = $self->{history}->{current} || return undef;
        return undef if $index + 1 >= $self->{history}->{size};
        $self->{history}->{current} = ++ $index;
        $self->{history}->{lines}->[$index];
    }

    sub history_prev {
        my ($self) = @_;
        my $index = $self->{history}->{current} || return undef;
        
        if ($index == 0) {
            $self->{history}->{current} = $self->{history}->{size} - 1;
            return undef;
        } 

        $self->{history}->{current} = -- $index;
        $self->{history}->{lines}->[$index];
    }

    sub CTRL_KEY {
        sprintf("CTRL_%c", shift() + 0x40);
    }

    sub highlight_syntax 
    {
        my ($self, $code) = @_;
        return "" unless length($code);
        my $render = "";
        my $lcolor = 0;
        my $in_str = 0;
        my $is_var = 0;
        my $in_com = 0;
        my $is_esc = 0;

        for my $word (split /\b{wb}/, $code)
        {
            my $ncolor = 0;
            my $w = quotemeta($word);

            if ($in_str) {
                $ncolor = 36;
                if ($is_var) {
                    $is_var = 0;
                    $ncolor = 35;
                } elsif ($word eq '\\') {
                    $is_esc = 1
                } elsif ($is_esc) {
                    $is_esc = 0;
                } elsif ($word eq $in_str) {
                    $in_str = 0;
                } elsif ($word eq '%' || $word eq '@' || $word eq '$') {
                    $ncolor = 35;
                    $is_var = 1;
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
                $ncolor = 36;
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

        $render
    }

    sub readline {
        my ($self, $prompt) = @_;
        $prompt     = "" unless $prompt;
        my $index   = 0;
        my $buffer  = "";
        my $reading = 1;
        my $prevrow = 0;
        my $prevcol = 1;
        my $prevsug = 0;
        my $sugestions = "";
        my $nl = 0;

        $| = 1;
        $self->raw_mode();
        print "\x1b[6n\x1b[0;1m$prompt";

        while ($reading) {

            my $printable = "";

            my $k = $self->read_key() || next;

            if ($k == 0x0a || $k == 0x0d) {
                $reading = 0;
            } elsif ($k == ARROW_LEFT) {
                $index -- if $index > 0;
            } elsif ($k == ARROW_RIGHT) {
                $index ++ if $index < length($buffer);
            } elsif ($k == BACKSPACE) {
                substr($buffer, -- $index, 1) = "" if $index;
            } elsif ($k == DEL_KEY) {
                substr($buffer, $index, 1) = "" if $index < length($buffer);
            } elsif ($k == ARROW_UP) {
                $buffer = $self->history_prev() || next;
                $index = length($buffer);
            } elsif ($k == ARROW_DOWN) {
                $buffer = $self->history_next() || next;
                $index = length($buffer);
            } elsif ($k == TAB_KEY) {
                my $base = (split(/\b{wb}/, substr($buffer, 0, $index)))[-1];
                unless ($base) {
                    $buffer .= "    ";
                    $index += 4;
                } else {
                    my @possible = $self->get_completions($base);
                    if (@possible == 1) {
                        substr($buffer, $index - length($base), length($base)) = $possible[0];
                        $index += length($possible[0]) - length($base);
                    } elsif (@possible > 1) {
                        $sugestions = substr("@possible", 0, $self->{width});
                    }
                }
            } elsif ($k == HOME_KEY) {
                $index = 0;
            } elsif ($k == END_KEY) {
                $index = length($buffer);
            } elsif ($k > 0 && $k < 27) {
                my $ctrl = CTRL_KEY($k);
                if ($ctrl eq 'CTRL_T') {
                    next unless $index > 1;
                    my $tmp = substr($buffer, $index - 1, 1);
                    substr($buffer, $index - 1, 1) = substr($buffer, $index - 2, 1);
                    substr($buffer, $index - 2, 1) = $tmp;
                } elsif ($ctrl eq 'CTRL_U') {
                    $buffer = "";
                    $index = 0;
                } elsif ($ctrl eq 'CTRL_D') {
                    $reading = 0;
                } else {
                    my $callback = $self->{keybindings} || next;
                    $callback = $callback->{$ctrl} || next;
                    $callback->()
                }
            } else {
                substr($buffer, $index ++, 0) = chr($k);
            }

            my $w = $self->width();
            my $h = $self->height();
            my $x = (length($prompt) + $index) % $w + 1;
            my $y = int((length($prompt) + $index + $w - 1) / $w);
            my $l = int((length($prompt) + length($buffer) + $w - 1) / $w);
            my $r = $self->{cy} + $l;

            if (($prevrow - $y) > 0 && $index != 0) {
                $printable .= "\x1b[1B" x ($prevrow - $y);
            }

            if ($nl || ($x == 2 && $x > $prevcol)) {
                $printable .= "\x1b[1A";
            }

            $nl = 0;

            my $render = $self->highlight_syntax($buffer);
            $printable .= "\x1b[0G\x1b[0K\x1b[1A" x $prevrow;
            $printable .= "\x1b[0G\x1b[0K\x1b[0;1m${prompt}${render}";
            if ($r >= $h || (length($prompt) + $index) % $w == 0) {
                $printable .= "\n";
                $l ++;
                $nl = 1;
            }

            if ($sugestions || $prevsug) {
                $printable .= "\r\n\x1b[0;1m\x1b[0K$sugestions";
                $sugestions = "";
                $prevsug = 1 - $prevsug;
                $l ++;
            }

            $printable .= "\x1b[${x}G";

            if ($reading && ($l - ($y + $nl) > 0)) {
                $printable .= "\x1b[1A" x ($l - ($y + $nl));
            }

            print $printable;

            $prevrow = $y - 1;
            $prevcol = $x;
        }

        $self->raw_mode();
        print "\r\n";
        $self->history_add($buffer);
        $buffer
    }

    sub width {
        my ($self) = @_;
        $self->{width}
    }

    sub height {
        my ($self) = @_;
        $self->{height}
    }

    sub update_term {
        my ($self) = @_;
        ($self->{width}, $self->{height}) = Term::Size::chars *STDOUT{IO};
    }

    END {
        print "\r\n";
        ReadMode 0;
    }
}

1;
