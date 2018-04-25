use v6.c;
unit class RakudoBot::Runner;

class X::RakudoBot::ProcError is Exception is export {
    has $.command;
    has $.logs;
    has $.e;
    method message(--> Str) {
        "Failed to run command '$!command' successfully."
    }
}

has Bool $.debug;

method run(|args --> Promise) {
    start {
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
        $c.list.join('');

        CATCH {
            default {
                $c.close unless $c.closed;
                my $command := args.Str;
                my $logs := $c.list.join('');
                X::RakudoBot::ProcError.new(:$command, :$logs, :e($!)).throw;
            }
        }
    }
}

method configure(*@args--> Promise) { $.run("./Configure.pl", |@args) }
method make(--> Promise)            { $.run('make')                   }
method make-install(--> Promise)    { $.run('make', 'install')        }
method make-clean(--> Promise)      { $.run('make', 'clean')          }
method make-realclean(--> Promise)  { $.run('make', 'realclean')      }

method make-test(--> Promise)       { $.run('make', 'test')       }
method make-spectest(--> Promise)   { $.run('make', 'spectest')   }
method make-stresstest(--> Promise) { $.run('make', 'stresstest') }

method git-submodule-update(--> Promise) {
    $.run('git', 'submodule', 'update', '--remote', '--merge');
}
method zef-install(--> Promise)   {
    $.run('zef', 'install', '--to=install/share/perl6/site', 'Zef')
}
method perl5-install(--> Promise) {
    $.run('install/share/perl6/site/bin/zef', 'install', '--to=install/share/perl6/site', 'Inline::Perl5');
}
