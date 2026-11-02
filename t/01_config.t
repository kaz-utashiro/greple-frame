use v5.26;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempfile);
use File::Spec;
use open qw(:std :encoding(utf-8));

# Parameters are set by -Mframe::config(...) or -Mframe::set(...) or the
# options, and a value that is not a number is an RPN expression on the
# terminal width.  The width shows in the frame line.

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

done_testing;
