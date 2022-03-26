# IPerl
> Interactive Perl interpreter

This is a simple REPL (Read, Execute, Print, Loop) script that aims to provide an easy and fun way to run an interactive Perl interpreter.

## Dependencies
- JSON
> user@pc:~$ cpan JSON
- Term::ReadKey
> user@pc:~$ cpan Term::ReadKey
## Installation

OS X & Linux:

```bash
git clone https://github.com/lvmalware/iperl && \
cd iperl && \
sudo ./install.sh
```

Windows:

Switch to Linux and try the method above :)

## Usage

![showcase](https://user-images.githubusercontent.com/37661824/127336208-18fb984b-e17a-4c61-b10e-e39b9d0c834d.gif)


## Some cool modules

Modules can be found [here](https://github.com/LvMalware/iperl_modules)

To install them:

1. clone the repository

```bash
git clone https://github.com/LvMalware/iperl_modules
```

2. add their path to the config file

Assuming you have a configuration file your $HOME directory, modify the value of 'path':

```JSON
{
    "history" : "/home/lva/.iperl_history",
    "prompt"  : "IPerl",
    "path"    : ["/usr/share/iperl/modules", "add_your_path_here"]
}

```

## Writting and deploying your modules

Write a standart Perl module, like the following Example.pm:

```perl
package Example;
use base 'Exporter';
our @EXPORT = qw(test_func1 test_func2);

sub test_func1
{
    ...
}

sub test_func2
{
    ...
}
```

Copy your module to any location already on the path (configured on your config file) or add its location to the path as shown above.

## use vs. loadModule

The release 1.1.1 introduced the loadModule() function that can be used (as the name sugests) to load the contents of a module into the current running instance of IPerl.

loadModule() can be used only inside the interactive interpreter and does basically the same as 'use', but with the difference that it will automatically add all the exported names from the loaded module to the completion list, allowing these names to be sugested and completed by typing their first letters and pressing tab.

Besides that, there is no advantage in using loadModule() instead of 'use' to load modules.

## Latest updates

### Version 1.2.1
- Fixed issues with IPerl::Term

### Version 1.2
- Added syntax highlight
- Removed dependence on Term::ReadLine::Gnu (replaced by IPerl::Term)
- Added key-binding capabilities

### Version 1.1.1
- Added support for config file in JSON format
- Added a loadModule() function. Modules loaded through loadModule() have their exported names automatically added to the completion list
- Default modules can be specified through the config file

### Version 1.1
- Added an install.sh for easy installation within unix-like systems
- Moved execution context away from IPerl's code scope to avoid conflicts
- Added support for custom modules (need to be expanded ...)

## TODO list

- Add more custom modules
- Allow editing multi-line code
- Improve multi-line code support
- Fix any bugs that may appear within IPerl::Term

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
