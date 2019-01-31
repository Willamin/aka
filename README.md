# aka

A handler for aliases that a little more feature-rich than Bash's built-in aliases. However, Bash's built-in aliases handle the environment and working directory very differently.

## Use

Configuration belongs in `~/.config/aka.yml`.

Choose whichever method works for you:
  - `$ aka --list` will list aliases in a format supported by bash.
  - `$ aka --link` will create soft links in the `~/.config/aka/` directory.

Either way, `aka` reads the configuration, looks at how it was invoked (busybox-style) and executes the appropriate alias. Additionally, `aka` will print out a formatted explanation of what the alias is for. Printing out the alias when running it both helps avoid forgetting the true command and helps others that watch you program to understand what's happening.

## Installation

Aka is written in [Crystal](https://crystal-lang.org). As such, it must be compiled before it can be ran. After installing the Crystal compiler, you should be able to do the following:
  - `$ git clone git@github.com:Willamin/aka.git`
  - `$ cd aka`
  - `$ shards build --release`
  - the binary will be built at `bin/aka`, which should then be linked or copied to someplace in your PATH

## Contributing

1. Fork it ( https://github.com/Willamin/aka/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Willamin](https://github.com/Willamin) Will Lewis - creator, maintainer
