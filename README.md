# IPerl
> Interactive Perl interpreter

This is a simple REPL (Read, Execute, Print, Loop) script that aims to provide an easy and fun way to run a interactive Perl interpreter.

## Dependencies

- Term::ReadLine::Gnu
> user@pc:~$ cpan Term::ReadLine::Gnu

- Term::ANSIColor
> user@pc:~$ cpan Term::ANSIColor

## Installation

OS X & Linux:

```sh
sudo cp iperl.pl /bin/iperl
```

Windows:

```sh
cp iperl.pl %HOMEPATH%
```

## Usage example

```
user@pc:~$ iperl

Hello, user.
This is IPerl version 0.3, running Perl v5.28.1 .
Press CTRL+T to enter multi-line code, stop with CTRL+D .
Press CTRL+C to exit.

IPerl> 
```

## TODO list

- Add sugestions/completions
- Add syntax highlight
- Allow editing multi-line code

## Meta

Lucas V. Araujo – lucas.vieira.ar@disroot.org

Distributed under the GNU GPL-3.0+ license. See ``LICENSE`` for more information.

[https://github.com/LvMalware/iperl](https://github.com/LvMalware/)

## Contributing

1. Fork it (<https://github.com/LvMalware/iperl/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request
