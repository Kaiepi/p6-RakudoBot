use v6.c;
use JSON::Fast;
unit module RakudoBot::Config;

CHECK {
    my $CWD := $*CWD;
    chdir "$*FILE../../";
    copy 'config.json.example', 'config.json' unless 'config.json'.IO.e;
    chdir $CWD;

    my package EXPORT::DEFAULT {
        my %config := from-json 'config.json'.IO.slurp;
        for %config.kv -> $k, $v {
            OUR::{"RB_{$k.uc}"} = $v;
        }
        OUR::RB_PWD = $*CWD;
    }
}
