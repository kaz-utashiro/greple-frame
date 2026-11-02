package App::Greple::frame;

our $VERSION = "1.03";

=encoding utf-8

=head1 NAME

App::Greple::frame - Greple frame output module

=head1 SYNOPSIS

greple -Mframe --style=fold -- ...

greple -Mframe --frame ...

=head1 VERSION

Version 1.03

=head1 DESCRIPTION

Greple -Mframe module provide a capability to put surrounding frames
for each blocks.

C<top>, C<middle> and C<bottom> frames are printed for blocks.

By default B<--join-blocks> option is enabled to collect consecutive
lines into a single block.  If you don't like this, override it by
B<--no-join-blocks> option.

=head1 MODULE OPTIONS

Options placed between B<-Mframe> and B<--> belong to the module, so
their names do not conflict with the options of B<greple> or of other
modules.

    greple -Mframe --style=cols -- pattern file

    greple -Mframe --style=fold --width=80 -- pattern file

When B<--> is given, everything before it must be a module option, so
C<< -Mframe --frame pattern -- file >> is an error.  Options of
B<greple> and the pattern come after it.

=over 7

=item B<--style>=I<name>

Select the output style.  An unknown name is an error.

=over 7

=item B<fold>

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-3.png">

=end html

Set frame and fold long lines with frame-friendly prefix string.
Folding width is taken from the terminal.  Or you can specify the
width with the B<--width> option.

=item B<cols>

Output results in multi-column format to fit the width of the
terminal.  The number of columns is automatically calculated from the
terminal width.

=item B<pages>

Output results in multi-column and paginated format.

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-frame-pages.png">

=end html

=back

=item B<--width>=I<n>

Same as the B<width> parameter.  See L</CONFIGURATION>.

=item B<--config> I<name>=I<value>,...

Set parameters of L</CONFIGURATION>.

=back

=head1 COMMAND OPTIONS

These options work as options of the B<greple> command, and do not need
B<-->.  They are kept for compatibility and may be removed in the
future.  Use L</MODULE OPTIONS>.

=over 7

=item B<--frame>

=for comment
=item B<--frame-fold>

Same as B<--style=fold>.

=begin comment

=item B<--frame-simple>

Set frame without folding.

=end comment

=item B<--frame-cols>

Same as B<--style=cols>.

=item B<--frame-pages>

Same as B<--style=pages>.

=item B<--set-frame-width>=I<#>

Same as B<--width>.  You have to put this option before B<--frame>
option.

=back

=begin comment

Put next line in your F<~/.greplerc> to autoload B<App::Greple::frame> module.

    autoload -Mframe --frame

Then you can use B<--frame> option whenever you want.

=end comment

=head1 CONFIGURATION

Module parameters are set with L<Getopt::EX::Config> by the B<config>
function.  The B<--config> module option sets the same parameters.

The B<set> function does the same as B<config>.  It is kept only for
compatibility and will be removed in the future.

=over 7

=item B<config>(B<width>=I<n>)

Set terminal width to I<n>.  Use like this:

    greple -Mframe::config(width=80) ...

    greple -Mframe::config=width=80 ...

If non-digit character is found in the value part, it is considered as
a Reverse Polish Notation, starting terminal width pushed on the
stack.  RPN C<2/3-> means C<terminal-width / 2 - 3>.

You can use like this:

    greple -Mframe::config=width=2/3- --frame --uc '(\w+::)+\w+' --git | ansicolumn -PC2

With B<cols> and B<pages> styles, the whole output has this width, and
the width and the number of the columns are calculated from it.

An unknown parameter is an error.

=begin html

<p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-frame/main/images/terminal-column.png">

=end html

=item B<config>(B<style>=I<name>)

Same as the B<--style> module option.

=back

=head1 SEE ALSO

L<App::ansifold>

L<App::ansicolumn>

L<Math::RPN>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2022-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.26;
use warnings;
use utf8;
use Data::Dumper;
use Getopt::EX::Config qw(config set);

$ENV{GREPLE_FRAME_PAGES_WIDTH}    //= '80';
$ENV{GREPLE_FRAME_PAGES_MARGIN}   //= '0';
$ENV{GREPLE_FRAME_PAGES_BOUNDARY} //= 'none';

my($mod, $argv);
my($head, $blockend, $file_start, $file_end);
my $frame_width;		# of a column, set by pane()

# set() is kept only for compatibility and will be removed in the future.
# Values may be RPN, which is calculated when the value is used (see param).
my $config = Getopt::EX::Config->new(
    width  => undef,
    column => undef,
    fold   => '',
    style  => undef,
);

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

sub finalize {
    ($mod, $argv) = @_;
    $config->deal_with($argv, "style=s", "width=s");
    if (my @extra = $config->argv) {
	die "@extra: unexpected argument before --\n";
    }
    # The default gets the definition, not the name: an autoload of that
    # name in the rc file would load the module again, which inserts the
    # default once more and the frame comes out twice.
    if (my $style = $config->{style}) {
	my @opt = $mod->getopt("--frame-$style")
	    or die "$style: unknown style\n";
	$mod->setopt(default => [ @opt ]);
    }
}

my %frame_base = (
    top    => '      ┌─' ,
    middle => '    ⋮ ├╶' ,
    bottom => '──────┴─' ,
);

sub opt_frame {
    my $pos = shift;
    my $width = $frame_width // param('width') // ($config->{width} = terminal_width);
    local $_ = $frame_base{$pos} or die;
    if ((my $rest = $width - length) > 0) {
	$_ .= (substr($_, -1, 1) x $rest);
    }
    $_;
}

my %rpn = (
    width  => { init => sub { terminal_width } },
    column => { init => sub { terminal_width } },
    );
sub rpn {
    my($k, $v) = @_;
    require Getopt::EX::RPN
	and Getopt::EX::RPN->import('rpn_calc');
    my $init = $rpn{$k}->{init} // die;
    my @init = ref $init ? $init->() : $init ? $init : ();
    int(rpn_calc(@init, $v)) or die "$v: format error\n";
}

# A value can be set at any time before it is used, by the module
# function or by an option, so the RPN is calculated here.
sub param {
    my $k = shift;
    my $v = $config->{$k};
    if (defined $v and $rpn{$k} and $v =~ /\D/) {
	$v = $config->{$k} = rpn($k, $v);
    }
    $v;
}

# For the multi-column options: the width parameter takes the place of
# the terminal width.  Returns the width to fold, the whole width and the
# number of columns, in the order of $<shift> in their definitions.
sub pane {
    my %arg = @_;
    require Getopt::EX::RPN;
    my $whole = param('width') // terminal_width;
    my($width, $column) = map {
	int(Getopt::EX::RPN::rpn_calc($whole, $_)) or die "$_: format error\n";
    } @arg{qw(width column)};
    $frame_width = $width;
    ($width, $whole, $column);
}

sub get {
    use List::Util qw(pairmap);
    pairmap { param($a) } @_;
}

1;

__DATA__

mode function

option --set-frame-width  &config(width=$<shift>)
option --set-frame-column &config(column=$<shift>)

option --ansifold-with-width \
       --pf "ansifold --expand --discard=EL --padding --prefix '      │ ' $<shift> --width=$<shift>"

option --ansifold \
       --ansifold-with-width &get(fold,width)

option --frame-color-filename \
       --colormap FILE=555/CE --format FILE=' %s'

option --frame-simple \
       --line-number --join-blocks \
       --filestyle=once \
       --colormap LINE= --format LINE='%5d │ ' \
       --blockend= \
       --show-frame-middle

option --show-frame-top    --frame_top    &opt_frame(top)
option --show-frame-middle --frame_middle &opt_frame(middle)
option --show-frame-bottom --frame_bottom &opt_frame(bottom)

option --frame-plain --frame-color-filename --frame-simple
option --frame-fold  --frame-plain --ansifold
option --frame       --frame-fold

option --frame-classic-plain --frame-simple --show-frame-top --show-frame-bottom
option --frame-classic-fold  --frame-classic-plain --ansifold
option --frame-classic       --frame-classic-fold

##
## EXPERIMENTAL: --frame-pages, --frame-cols
##

# RPN
define @TEXT_WIDTH  $ENV{GREPLE_FRAME_PAGES_WIDTH}
define @MARGIN      $ENV{GREPLE_FRAME_PAGES_MARGIN}
define @LINE_FIELD  8
define @FRAME_GAP   3
define @COL_WIDTH   @TEXT_WIDTH:@LINE_FIELD:+:@FRAME_GAP:+
define @COLUMN      @COL_WIDTH:/:INT:DUP:1:GE:EXCH:1:IF
define @WIDTH       DUP:@COLUMN:/:@FRAME_GAP:-:@MARGIN:-

define $FOLD \
       ansifold --expand --discard=EL --padding \
       --width=$<shift> \
       --prefix '      │ ' \
       --boundary=$ENV{GREPLE_FRAME_PAGES_BOUNDARY} \
       --linebreak=all --runin=@MARGIN --runout=@MARGIN

define $COLS \
       ansicolumn --border=box -c $<shift> -U $<shift>

define $PAGES \
       ansicolumn --border=box -P -c $<shift> -C $<shift>

# &pane is called when these options are expanded, so that it sees the
# width given by --set-frame-width.  It can not be in the definition of
# --frame-col and others, because --style puts them in the default option,
# where functions are not called.

define $PANE &pane(width=@WIDTH,column=@COLUMN)

option --frame-col-pf --pf "$FOLD" $<remove(0,2)>
option --frame-pages-pf --pf "$FOLD | $PAGES"
option --frame-cols-pf --pf "$FOLD | $COLS"

option --frame-col-pane --frame-col-pf $PANE
option --frame-pages-pane --frame-pages-pf $PANE
option --frame-cols-pane --frame-cols-pf $PANE

option --frame-col --frame-col-pane --frame-plain
option --frame-pages --frame-pages-pane --frame-plain
option --frame-cols --frame-cols-pane --frame-plain

option --frame-columns --frame-cols

option --frame-pages-classic --frame-pages-pane --frame-classic-plain
