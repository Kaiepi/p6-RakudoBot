use v6.c;
unit class RakudoBot::Runner;

has Lock $.mux .= new;

has IO::Path $.path;
has IO::Path $.cwd = $*CWD;
has Bool     $.debug;

method run(|args --> Str) {
    $!mux.lock;
    chdir $!path;

    my Channel $c .= new;
    my $p := Proc::Async.new: |args;
    $p.stdout.tap: -> $line {
        print $line if $!debug;
        $c.send($line);
    }
    $p.stderr.tap: -> $line {
        $*ERR.print($line) if $!debug;
        $c.send($line);
    }
    await $p.start;
    $c.close;

    chdir $!cwd;
    $!mux.unlock;

    $c.list.join('');
}

method git-submodule-update(--> Str) { $.run('git', 'submodule', 'update', '--remote', '--merge') }

method configure(*@args--> Str) { $.run("./Configure.pl", |@args) }
method make-install(--> Str)    { $.run('make', 'install')        }
method make-test(--> Str)       { $.run('make', 'test')           }
method make-stresstest(--> Str) { $.run('make', 'stresstest')     }
method make-clean(--> Str)      { $.run('make', 'clean')          }
method make-realclean(--> Str)  { $.run('make', 'realclean')      }

method zef-install(--> Str)   { $.run('zef', 'install', '--to=install/share/perl6/site', 'Zef')       }
method perl5-install(--> Str) { $.run('install/share/perl6/site/bin/zef', 'install', 'Inline::Perl5') }
