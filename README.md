[![Actions Status](https://github.com/kaz-utashiro/greple-frame/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-frame/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-frame.svg)](https://metacpan.org/release/App-Greple-frame)
# NAME

App::Greple::frame - Greple frame output module

# SYNOPSIS

greple -Mframe --frame ...

# DESCRIPTION

Greple -Mframe module provide a capability to put surrounding frames
for each blocks.

`top`, `middle` and `bottom` frames are printed for blocks.

By default **--join-blocks** option is enabled to collect consecutive
lines into a single block.  If you don't like this, override it by
**--no-join-blocks** option.

# OPTIONS

- **--frame**

    Set frame and fold long lines with frame-friendly prefix string.
    Folding width is taken from the terminal.  Or you can specify the
    width by calling **set** function with module option.

Put next line in your `~/.greplerc` to autoload **App::Greple::frame** module.

    autoload -Mframe --frame

Then you can use **--frame** option whenever you want.

<div>
    <p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-2.png">
</div>

# FUNCTION

- **set**(**width**=_n_)

    Set terminal width to _n_.  Use like this:

        greple -Mframe::set(width=80) ...

        greple -Mframe::set=width=80 ...

    If non-digit character is found in the value part, it is considered as
    a Reverse Polish Notation, starting terminal width pushed on the
    stack.  Next command set `terminal-width / 2 - 3`.

        greple -Mframe::set=width=2/3- ...

# SEE ALSO

[App::ansifold](https://metacpan.org/pod/App%3A%3Aansifold)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
