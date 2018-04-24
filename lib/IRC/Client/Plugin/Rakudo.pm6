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

has IO::Path $.path;
has IO::Path $.cwd;
has Bool     $.debug;

method new(
    Str  :$channel,
    Str  :$maintainer,
    Str  :$source,
    Str  :$rakudo-path,
         :@config-flags,
    Bool :$debug
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
        :$debug,
        :cwd($*CWD);
}

method log-progress(Str $text) {
    $.irc.send: :where($!channel), :text("[{$*VM.osname}] $text");
}

method log-output(Str $message, @lines) {
    my $url := $!pastebin.paste(@lines.join(''));
    $.log-progress("$message See the output at $url");
    return $url;

    CATCH {
        default {
            $.log-progress("$message Failed to upload output to Pastebin.");
        }
    }
}

multi method irc-addressed($ where /<|w>all<|w>/) {
    $.log-progress('Running complete Rakudo build and tests... (this will take a while)...');
    chdir $!path;
    my $p := Promise.start({ $.configure(|@!config-flags) });
    my $output = await $p;
    $output = await $p.then({ $.make-clean });
    $output = await $p.then({ $.make });
    $output = await $p.then({ $.make-install });
    $output = await $p.then({ $.make-test });
    $output = await $p.then({ $.zef-install });
    $output = await $p.then({ $.perl5-install });
    $output = await $p.then({ $.make-stresstest });
    chdir $!cwd;
    $.log-progress('Successfully built Rakudo and passed all tests!');
    return 'done!';

    CATCH { default { $.log-output('Complete build and tests failed.', $output); } }
}

multi method irc-addressed($ where /<|w>build<|w>/) {
    $.log-progress('Building Rakudo...');
    chdir $!path;
    my $p := Promise.start({ $.configure(|@!config-flags) });
    my $output = await $p;
    $output = await $p.then({ $.make-clean });
    $output = await $p;
    $output = await $p.then({ $.make });
    chdir $!cwd;
    $.log-progress('Successfully built Rakudo!');
    return 'done!';

    CATCH { default { $.log-output('Build failed.', $output); } }
}

multi method irc-addressed($ where /<|w>test<|w>/) {
    $.log-progress('Running tests...');
    chdir $!path;
    my $p := Promise.start({ $.make-test });
    my $output = await $p;
    chdir $!cwd;
    $.log-progress('Successfully ran all tests!');
    return 'done!';

    CATCH { default { $.log-output('Tests failed.', $output); } }
}

multi method irc-addressed($ where /<|w>stresstest<|w>/) {
    $.log-progress('Running stress tests with Roast (this will take a while)...');
    chdir $!path;
    my $p := Promise.start({ $.zef-install });
    my $output = await $p;
    $output = await $p.then({ $.perl5-install });
    $output = await $p.then({ $.make-stresstest });
    chdir $!cwd;
    $.log-progress('Successfully ran the full test suite!');
    return 'done!';

    CATCH { default { $.log-output('Failed to pass the test suite.', $output); } }
}

multi method irc-addressed($ where /<|w>(github|git|source)<|w>/) {
    $!source
}

multi method irc-addressed($ where /<|w>help<|w>/) {
    "address me with 'build', 'test', or 'stresstest' to test building Rakudo, running tests, and running Roast\'s suite respectively on {$*VM.osname}. Address me with 'all' to attempt to run all three sequentially."
}
