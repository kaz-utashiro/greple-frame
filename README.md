[![Actions Status](https://github.com/kaz-utashiro/greple-frame/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kaz-utashiro/greple-frame/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-frame.svg)](https://metacpan.org/release/App-Greple-frame)
# NAME

App::Greple::frame - Greple frame output module

# SYNOPSIS

greple -Mframe --style=fold -- ...

greple -Mframe --frame ...

# VERSION

Version 1.03

# DESCRIPTION

Greple -Mframe module provide a capability to put surrounding frames
for each blocks.

`top`, `middle` and `bottom` frames are printed for blocks.

By default **--join-blocks** option is enabled to collect consecutive
lines into a single block.  If you don't like this, override it by
**--no-join-blocks** option.

# MODULE OPTIONS

Options placed between **-Mframe** and **--** belong to the module, so
their names do not conflict with the options of **greple** or of other
modules.

    greple -Mframe --style=cols -- pattern file

    greple -Mframe --style=fold --width=80 -- pattern file

When **--** is given, everything before it must be a module option, so
`-Mframe --frame pattern -- file` is an error.  Options of
**greple** and the pattern come after it.

- **--style**=_name_

    Select the output style.  An unknown name is an error.

    - **fold**

        <div>
                    <p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-3.png">
        </div>

        Set frame and fold long lines with frame-friendly prefix string.
        Folding width is taken from the terminal.  Or you can specify the
        width with the **--width** option.

    - **cols**

        Output results in multi-column format to fit the width of the
        terminal.  The number of columns is automatically calculated from the
        terminal width.

    - **pages**

        Output results in multi-column and paginated format.

        <div>
                    <p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-frame-pages.png">
        </div>

- **--width**=_n_

    Same as the **width** parameter.  See ["CONFIGURATION"](#configuration).

- **--config** _name_=_value_,...

    Set parameters of ["CONFIGURATION"](#configuration).

# COMMAND OPTIONS

These options work as options of the **greple** command, and do not need
**--**.  They are kept for compatibility and may be removed in the
future.  Use ["MODULE OPTIONS"](#module-options).

- **--frame**

    Same as **--style=fold**.

- **--frame-cols**

    Same as **--style=cols**.

- **--frame-pages**

    Same as **--style=pages**.

- **--set-frame-width**=_#_

    Same as **--width**.  You have to put this option before **--frame**
    option.

# CONFIGURATION

Module parameters are set with [Getopt::EX::Config](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AConfig) by the **config**
function.  The **--config** module option sets the same parameters.

The **set** function does the same as **config**.  It is kept only for
compatibility and will be removed in the future.

- **config**(**width**=_n_)

    Set terminal width to _n_.  Use like this:

        greple -Mframe::config(width=80) ...

        greple -Mframe::config=width=80 ...

    If non-digit character is found in the value part, it is considered as
    a Reverse Polish Notation, starting terminal width pushed on the
    stack.  RPN `2/3-` means `terminal-width / 2 - 3`.

    You can use like this:

        greple -Mframe::config=width=2/3- --frame --uc '(\w+::)+\w+' --git | ansicolumn -PC2

    With **cols** and **pages** styles, the whole output has this width, and
    the width and the number of the columns are calculated from it.

    An unknown parameter is an error.

    <div>
            <p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-column.png">
    </div>

- **config**(**style**=_name_)

    Same as the **--style** module option.

# SEE ALSO

[App::ansifold](https://metacpan.org/pod/App%3A%3Aansifold)

[App::ansicolumn](https://metacpan.org/pod/App%3A%3Aansicolumn)

[Math::RPN](https://metacpan.org/pod/Math%3A%3ARPN)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2022-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
