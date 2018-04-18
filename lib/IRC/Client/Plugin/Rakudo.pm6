use v6.c;
use IRC::Client;
use Pastebin::Shadowcat;
unit class IRC::Client::Plugin::Rakudo does IRC::Client::Plugin;

has Lock                $!mux      .= new;
has Pastebin::Shadowcat $!pastebin .= new;

has Str      $.channel;
has Str      $.maintainer;
has Str      $.source;
has IO::Path $.path;
has          @.config-flags;
has IO::Path $.cwd;

method new(
    Str :$channel,
    Str :$maintainer,
    Str :$source,
    Str :$rakudo-path,
    :@config-flags
) {
    my $replacer := $*DISTRO.is-win
        ?? / \%USERPROFILE\% | \%HOMEDRIVE\% \%HOMEPATH\% /
        !! / \~ /;
    my IO::Path $path .= new: $rakudo-path.subst($replacer, $*HOME, :g:i).IO.resolve;
    fail "Configured Rakudo path '$path' is not a directory!" unless $path.d;

    self.bless:
        :$channel,
        :$maintainer,
        :$source,
        :$path,
        :@config-flags,
        :cwd($*CWD);
}

method log-progress(Str $text) {
    $.irc.send: :where($!channel), :text("[{$*VM.osname}] $text");
}

method log-output(Str $message, @lines) {
    my $url := $!pastebin.paste(@lines.join(''));
    $.log-progress("$message See the output at $url");

    CATCH {
        default {
            $.log-progress("$message Failed to upload output to Pastebin.");
        }
    }
}

method diff(--> Bool) {
    my $diff := qx/git diff -q/;
    $.log-progress("The current branch has uncommitted changes. Please tell {$!maintainer} to commit or reset any changes made before running your command again.") if $diff;
    so $diff;
}

method setup(--> Str) {
    my $output := qx/git branch/;
    $output ~~ / \*\s(\N+) /;

    my $branch := ~$0;
    unless $branch eq 'master' {
        run 'git', 'fetch', 'origin', 'master';
        run 'git', 'checkout', 'master';
    }
    $branch;
}

method teardown(Str $branch) {
    run('git', 'checkout', $branch) unless $branch eq 'master';
}

method configure(--> Bool) {
    $.log-progress('Configuring Rakudo...');

    my @lines;
    my $proc = Proc::Async.new: './Configure.pl', |@!config-flags;
    $proc.stdout.tap({ @lines.push($_) });
    $proc.stderr.tap({ @lines.push($_) });
    await $proc.start;
    return False;

    CATCH {
        default {
            $.log-output('Configuring failed.', @lines);
            return True;
        }
    }
}

method build(--> Bool) {
    $.log-progress('Building Rakudo...');

    run 'make', 'clean' if 'perl6'.IO.e;

    my @lines;
    my $proc = Proc::Async.new: 'make';
    $proc.stdout.tap({ @lines.push($_) });
    $proc.stderr.tap({ @lines.push($_) });
    await $proc.start;

    $.log-progress('Build successful!');
    return False;

    CATCH {
        default {
            $.log-output('Build failed.', @lines);
            return True;
        }
    }
}

method test(--> Bool) {
    $.log-progress('Testing Rakudo...');

    my @lines;
    my $proc := Proc::Async.new: 'make', 'test';
    $proc.stdout.tap({
        @lines.push($_);
        $.log-progress("| $_") if $_ ~~ / ^ t\S+\s+\( /;
    });
    $proc.stderr.tap({ @lines.push($_) });
    await $proc.start;

    $.log-progress('Tests passed!');
    return False;

    CATCH {
        default {
            $.log-output('Tests failed.', @lines);
            return True;
        }
    }
}

method spectest(--> Bool) {
    $.log-progress('Running Roast test suite... (this will take a while)');

    my @lines;
    my $proc := Proc::Async.new: 'make', 'spectest';
    $proc.stdout.tap({
        @lines.push($_);
        $.log-progress("| $_") if $_ ~~ / ^ t\S+\s+\( /;
    });
    $proc.stderr.tap({ @lines.push($_) });
    await $proc.start;

    $.log-progress('Roast tests passed!');
    return False;

    CATCH {
        default {
            $.log-output('Roast tests failed.', @lines);
            return True;
        }
    }
}

multi method irc-addressed($ where /<|w>all<|w>/) {
    start {
        $!mux.protect(sub {
            chdir $!path;
            return chdir $!cwd if $.diff;

            my $branch := $.setup;
            my $error   = $.configure;
            $error = $.build    unless $error;
            $error = $.test     unless $error;
            $error = $.spectest unless $error;
            $.teardown($branch);
            chdir $!cwd;
        });

        'done!';
    }
}

multi method irc-addressed($ where /<|w>build<|w>/) {
    start {
        $!mux.protect(sub {
            chdir $!path;
            return chdir $!cwd if $.diff;

            my $branch := $.setup;
            my $error   = $.configure;
            $.build unless $error;
            $.teardown($branch);
            chdir $!cwd;
        });

        'done!';
    }
}

multi method irc-addressed($ where /<|w>test<|w>/) {
    start {
        $!mux.protect(sub {
            chdir $!path;
            return chdir $!cwd if $.diff;

            my $branch := $.setup;
            $.test;
            $.teardown($branch);
            chdir $!cwd;
        });

        'done!';
    }
}

multi method irc-addressed($ where /<|w>spectest<|w>/) {
    start {
        $!mux.protect(sub {
            chdir $!path;
            return chdir $!cwd if $.diff;

            my $branch := $.setup;
            $.spectest;
            $.teardown($branch);
            chdir $!cwd;
        });

        'done!';
    }
}

multi method irc-addressed($ where /<|w>(github|git|source)<|w>/) {
    $!source
}

multi method irc-addressed($ where /<|w>help<|w>/) {
    "address me with 'build', 'test', or 'spectest' to test building Rakudo, running tests, and running Roast\'s suite respectively on {$*VM.osname}. Address me with 'all' to attempt to run all three sequentially."
}
