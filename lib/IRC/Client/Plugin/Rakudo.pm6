use v6.c;
use IRC::Client;
use Pastebin::Shadowcat;
use RakudoBot::Config;
unit class IRC::Client::Plugin::Rakudo does IRC::Client::Plugin;

has Lock                $!mux      .= new;
has Pastebin::Shadowcat $!pastebin .= new;

method log-progress(Str $text) {
    $.irc.send: :where(RB_CHANNEL), :text("[{$*VM.osname}] $text");
}

method log-output(Str $message, @lines) {;
    my $url := $!pastebin.paste(@lines.join(''));
    $.log-progress("$message See the output at $url");
}

method diff(--> Bool) {
    my $diff := qx/git diff -q/;
    $.log-progress("The current branch has uncommitted changes. Please tell {RB_MAINTAINER} to commit or reset any changes made before running your command again.") if $diff;
    so $diff;
}

method setup(--> Str) {
    chdir RB_RAKUDO_PATH;
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
    (run 'git', 'checkout', $branch) unless $branch eq 'master';
    chdir RB_PWD;
}

method configure(--> Bool) {
    $.log-progress('Configuring Rakudo...');

    my @lines;
    my $proc = Proc::Async.new: './Configure.pl', RB_CONFIG_FLAGS;
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

    run 'make', 'clean' if './perl6'.IO.e;

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
            return if $.diff;

            my $branch := $.setup;
            my $error   = $.configure;
            $error = $.build    unless $error;
            $error = $.test     unless $error;
            $error = $.spectest unless $error;
            $.teardown($branch);
        });

        'done!';
    }
}

multi method irc-addressed($ where /<|w>build<|w>/) {
    start {
        $!mux.protect(sub {
            return if $.diff;

            my $branch := $.setup;
            my $error   = $.configure;
            $.build             unless $error;
            $.teardown($branch);
        });

        'done!';
    }
}

multi method irc-addressed($ where /<|w>test<|w>/) {
    start {
        $!mux.protect(sub {
            return if $.diff;

            my $branch := $.setup;
            $.test;
            $.teardown($branch);
        });

        'done!';
    }
}

multi method irc-addressed($ where /<|w>spectest<|w>/) {
    start {
        $!mux.protect(sub {
            return if $.diff;

            my $branch := $.setup;
            $.spectest;
            $.teardown($branch);
        });

        'done!';
    }
}

multi method irc-addressed($ where /<|w>(github|git|source)<|w>/) {
    RB_SOURCE
}

multi method irc-addressed($ where /<|w>help<|w>/) {
    'address me with "build", "test", or "spectest" to test building Rakudo, running tests, and running Roast\'s suite respectively on ' ~ $*VM.osname ~ '. Address me with "all" to attempt to run all three sequentially.'
}
