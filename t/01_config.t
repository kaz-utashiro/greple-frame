use v5.26;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use open qw(:std :encoding(utf-8));

# Parameters are set by -Mframe::config(...) or -Mframe::set(...) or the
# options, and a value that is not a number is an RPN expression on the
# terminal width.  The width shows in the frame line.  The arguments of run
# come before the pattern and the file, so that they can end with --.

my $lib = File::Spec->rel2abs('lib');
local $ENV{PERL5LIB} = join ':', $lib, grep { defined and length } $ENV{PERL5LIB};
local $ENV{GREPLE_NORC} = 1;

my($fh, $file) = tempfile(UNLINK => 1);
print $fh "hello world\nother\nanother\nhello again\n";
close $fh;

sub run {
    open my $p, '-|', 'greple', @_, 'hello', $file or die "greple: $!";
    binmode $p, ':encoding(utf-8)';
    my $out = do { local $/; <$p> };
    close $p;
    ($out, $? >> 8);
}

# the width of the middle frame line
sub frame_width {
    my($out) = run(@_);
    my($line) = ($out // '') =~ /^(\h+⋮ ├.*)$/m;
    defined $line ? length $line : undef;
}

is(frame_width('-Mframe::config(width=40)', '--frame'), 40, 'config(width=40)');
is(frame_width('-Mframe::set(width=40)', '--frame'), 40, 'set(width=40) still works');
is(frame_width('-Mframe::set=width=40', '--frame'), 40, 'set=width=40 still works');
is(frame_width('-Mframe', '--set-frame-width=40', '--frame'), 40, '--set-frame-width=40');

# RPN: terminal width / 2, then terminal width / 2 - 3
my $half = frame_width('-Mframe::set(width=2/)', '--frame');
ok($half && $half > 3, "set(width=2/) gives a width ($half)");
is(frame_width('-Mframe::config(width=2/)', '--frame'), $half, 'config takes RPN');
is(frame_width('-Mframe', '--set-frame-width=2/', '--frame'), $half, '--set-frame-width takes RPN');
is(frame_width('-Mframe::config(width=2/3-)', '--frame'), $half - 3, 'longer RPN');
is(frame_width('-Mframe::config(width=40)', '--set-frame-width=30', '--frame'), 30, 'the option overrides config');

# the width reaches the fold of long lines
my($out) = run('-Mframe::config(width=40)', '--frame');
like($out, qr/hello/, 'output has the matched line');

my(undef, $status) = run('-Mframe::config(nosuchkey=1)', '--frame');
isnt($status, 0, 'an unknown parameter is an error');

for my $opt (qw(--frame-cols --frame-pages)) {
    my($o, $s) = run('-Mframe', $opt);
    is($s, 0, "$opt runs");
    like($o // '', qr/hello/, "$opt shows the match");
}

# Module options come before --, and are parsed only when -- is there.
is(frame_width('-Mframe', '--style=fold', '--width=40', '--'), 40, '--style=fold --width=40 --');
is(frame_width('-Mframe', '--config', 'style=fold,width=40', '--'), 40, '--config style=fold,width=40 --');
is(frame_width('-Mframe::config(style=fold,width=40)'), 40, 'config(style=fold,width=40)');
is(frame_width('-Mframe', '--width=40', '--', '--frame'), 40, '--width before --, --frame after it');
is(frame_width('-Mframe', '--width=2/', '--', '--frame'), $half, '--width takes RPN');
is(frame_width('-Mframe::config(width=40)', '--', '--frame'), 40, 'nothing before --, --frame after it');
isnt((run('-Mframe', '--frame', '--'))[1], 0, '--frame before -- is an error');
is(frame_width('-Mframe', '--frame'), frame_width('-Mframe', '--style=fold', '--'), '--style=fold is --frame');
like((run('-Mframe', '--style=classic', '--width=40', '--'))[0], qr/^\h+┌─/m, '--style=classic has the top frame');

for my $style (qw(cols pages)) {
    my($o, $s) = run('-Mframe', "--style=$style", '--');
    is($s, 0, "--style=$style runs");
    like($o // '', qr/^┌─.*\n│ +1 │ hello/m, "--style=$style shows the match in a box");
}

# With the multi-column styles, the width takes the place of the terminal
# width: the whole output has that width, and the separator is not folded.
sub widths {
    my($out) = run(@_);
    my %w = map { $_ => 1 } map { length } split /\n/, $out // '';
    join ',', sort { $a <=> $b } keys %w;
}
for my $style (qw(cols pages)) {
    is(widths('-Mframe', "--style=$style", '--width=60', '--'), 60, "--style=$style --width=60");
    is(widths('-Mframe', "--style=$style", '--width=120', '--'), 120, "--style=$style --width=120");
    is(widths("-Mframe::config(style=$style,width=60)"), 60, "config(style=$style,width=60)");
    is(widths('-Mframe', '--width=60', '--', "--frame-$style"), 60, "--width=60 -- --frame-$style");
    is(widths('-Mframe', '--set-frame-width=60', "--frame-$style"), 60, "--set-frame-width=60 --frame-$style");
    my($o) = run('-Mframe', "--style=$style", '--width=60', '--');
    like($o // '', qr/^│ +⋮ ├╶+ *│$/m, "--style=$style --width=60: separator line");
    unlike($o // '', qr/^│ +│ ╶/m, "--style=$style --width=60: separator is not folded");
}
is(widths('-Mframe', '--style=cols', "--width=$half", '--'), $half, 'the width is the output width');
is(widths('-Mframe', '--style=cols', '--width=2/', '--'), $half, 'the width takes RPN with cols');
like((run('-Mframe', '--style=cols', '--width=200', '--'))[0] // '', qr/^┌─.*┐┌─/m, 'a wide output has two columns');
unlike((run('-Mframe', '--style=cols', '--width=80', '--'))[0] // '', qr/^┌─.*┐┌─/m, 'width 80 has one column');
is((run('-Mframe', '--width=60', '--', '--frame-col'))[1], 0, '--frame-col runs');
is((run('-Mframe', '--width=60', '--', '--frame-pages-classic'))[1], 0, '--frame-pages-classic runs');

isnt((run('-Mframe', '--style=nosuch', '--'))[1], 0, 'an unknown style is an error');
isnt((run('-Mframe', '--nosuchoption', '--'))[1], 0, 'an unknown module option is an error');
isnt((run('-Mframe', 'extra', '--'))[1], 0, 'an argument before -- is an error');

# Without -- the arguments belong to greple as before.
is(frame_width('-Mframe::config(width=40)', '--frame'), 40, '--frame without -- is a greple option');

# An autoload of the option name in the rc file loads the module again and
# inserts its default again.  The style must be applied only once.
{
    my $home = tempdir(CLEANUP => 1);
    open my $rc, '>', "$home/.greplerc" or die "$home/.greplerc: $!";
    print $rc "option --fp -Mframe --frame-pages\n";
    print $rc "autoload -Mframe --frame --frame-classic --frame-col --frame-cols --frame-pages\n";
    close $rc;
    local $ENV{HOME} = $home;
    delete local $ENV{GREPLE_NORC};
    for my $style (qw(cols pages fold col classic)) {
	my($o, $s) = run('-Mframe', "--style=$style", '--');
	is($s, 0, "autoload in rc: --style=$style runs");
	my @lines = ($o // '') =~ /^.* 1 │ hello/mg;
	is(scalar @lines, 1, "autoload in rc: --style=$style is applied once");
	unlike($o // '', qr/│ ┌|│ │/, "autoload in rc: --style=$style is not nested");
    }
    my($o, $s) = run('--fp', '--');
    is($s, 0, 'an rc option with -Mframe works with --');
    like($o // '', qr/ 1 │ hello/, 'an rc option with -Mframe shows the match');
}

done_testing;
