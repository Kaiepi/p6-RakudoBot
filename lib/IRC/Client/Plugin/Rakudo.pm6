use v6.c;
use IRC::Client;
use Pastebin::Shadowcat;
use RakudoBot::Runner;
unit class IRC::Client::Plugin::Rakudo is RakudoBot::Runner;
also does IRC::Client::Plugin;

has Lock                $!mux      .= new;
has Pastebin::Shadowcat $!pastebin .= new;

has Str      $.channel;
has Str      $.maintainer;
has Str      $.source;
has          @.config-flags;

has IO::Path $.rakudo-path;
has IO::Path $.repo-path;

method new(
    Str  :$channel,
    Str  :$maintainer,
    Str  :$source,
    Int  :$test-jobs,
         :@config-flags,
    Bool :$debug
) {
    my $rakudo-path := 'src/rakudo'.IO;
    my $repo-path   := $*CWD;
    self.bless:
        :$channel,
        :$maintainer,
        :$source,
        :$test-jobs,
        :@config-flags,
        :$repo-path,
        :$rakudo-path,
        :$debug;
}

method log-progress(Str $text) {
    $.irc.send: :where($!channel), :text("[{$*VM.osname}] $text");
}

method log-output(Str $message, Str $output) {
    my $url := $!pastebin.paste($output);
    $.log-progress("$message See the output at $url");
    return $url;

    CATCH { default { $.log-progress("$message Failed to upload output to Pastebin.") } }
}

multi method irc-addressed($ where /<|w>all<|w>/) {
    start {
        $!mux.protect(sub {
            $.log-progress('Running complete Rakudo build and tests (this will take a while)...');
            chdir $!rakudo-path;
            await $.git-submodule-update;
            await $.configure(|@!config-flags);
            await $.make-clean;
            await $.make;
            await $.make-install;
            await $.make-test;
            await $.zef-install;
            await $.perl5-install;
            await $.make-stresstest;
            chdir $!repo-path;
            $.log-progress('Successfully built Rakudo and passed all tests!');

            return 'done!';

            CATCH {
                when X::RakudoBot::ProcError { $.log-output('Failed to build Rakudo and run all tests...', .logs) }
                default { .rethrow }
            }
        });
    }
}

multi method irc-addressed($ where /<|w>build<|w>/) {
    start {
        $!mux.protect(sub {
            $.log-progress('Building Rakudo...');
            chdir $!rakudo-path;
            await $.git-submodule-update;
            await $.configure(|@!config-flags);
            await $.make-clean;
            await $.make;
            await $.make-install;
            chdir $!repo-path;
            $.log-progress('Successfully built Rakudo!');

            return 'done!';

            CATCH {
                when X::RakudoBot::ProcError { $.log-output('Failed build....', .logs) }
                default { .rethrow }
            }
        });
    }
}

multi method irc-addressed($ where /<|w>test<|w>/) {
    start {
        $!mux.protect(sub {
            $.log-progress('Running tests...');
            chdir $!rakudo-path;
            await $.make-test;
            chdir $!repo-path;
            $.log-progress('Successfully ran all tests!');

            return 'done!';

            CATCH {
                when X::RakudoBot::ProcError { $.log-output('Failed tests...', .logs) }
                default { .rethrow }
            }
        });
    }
}

multi method irc-addressed($ where /<|w>spectest<|w>/) {
    start {
        $!mux.protect(sub {
            $.log-progress("Running Roast's spec test suite...");
            chdir $!rakudo-path;
            await $.zef-install;
            await $.perl5-install;
            await $.make-spectest;
            chdir $!repo-path;
            $.log-progress('Successfully passed all spec tests!');

            return 'done!';

            CATCH {
                when X::RakudoBot::ProcError { $.log-output('Failed spec tests...', .logs) }
                default { .rethrow }
            }
        });
    }
}

multi method irc-addressed($ where /<|w>stresstest<|w>/) {
    start {
        $!mux.protect(sub {
            $.log-progress("Running Roast's stress test suite (this will take a while)...");
            chdir $!rakudo-path;
            await $.zef-install;
            await $.perl5-install;
            await $.make-stresstest;
            chdir $!repo-path;
            $.log-progress("Successfully passed all of Roast's tests!");

            return 'done!';

            CATCH {
                when X::RakudoBot::ProcError { $.log-output('Failed Roast stress test suite...', .logs) }
                default { .rethrow }
            }
        });
    }
}

multi method irc-addressed($ where /<|w>(github|git|source)<|w>/) {
    $!source
}

multi method irc-addressed($ where /<|w>help<|w>/) {
    "address me with 'build', 'test', 'spectest', or 'stresstest' to test building Rakudo, running tests, and running Roast\'s test suite respectively on {$*VM.osname}. Address me with 'all' to attempt to run a full build with all tests."
}
