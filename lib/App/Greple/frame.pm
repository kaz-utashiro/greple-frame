package App::Greple::frame;
our $VERSION = "0.01";

=encoding utf-8

=head1 NAME

App::Greple::frame - Greple frame output module

=head1 SYNOPSIS

greple -Mframe

=head1 DESCRIPTION

Greple -Mframe module set appropriate paramater to put surrounding
frames for each blocks.

C<top>, C<middle> and C<bottom> frames are printed for blocks.

If a block is a single line, and you want to collect consecutive lines
into a single block, use B<--join-blocks> option.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use 5.014;
use warnings;
use utf8;

my($mod, $argv);
my $width;
my($head, $blockend, $file_start, $file_end);

sub terminal_width {
    use Term::ReadKey;
    my $default = 80;
    my @size;
    if (open my $tty, ">", "/dev/tty") {
	# Term::ReadKey 2.31 on macOS 10.15 has a bug in argument handling
	# and the latest version 2.38 fails to install.
	# This code should work on both versions.
	@size = GetTerminalSize $tty, $tty;
    }
    $size[0] or $default;
}

sub initialize {
    ($mod, $argv) = @_;
    $width = terminal_width;
    
    my $frame_top    = '──────┬─' . ('─' x ($width - 8));
    my $frame_middle = '    ⋮ ├╶' . ('╶' x ($width - 8));
    my $frame_bottom = '──────┴─' . ('─' x ($width - 8));

    $mod->setopt(
	'--show-frame',
	'--frame-top'    => "'$frame_top'",
	'--frame-middle' => "'$frame_middle'",
	'--frame-bottom' => "'$frame_bottom'",
	);
}

1;

__DATA__

option --frame \
	-n --join-blocks \
	--colormap=LINE= \
	--filestyle=once \
	--format=LINE='%5d │ ' \
	--blockend= \
	--show-frame
