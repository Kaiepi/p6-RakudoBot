use v6.c;
use JSON::Fast;
unit module RakudoBot::Config;

CHECK {
    copy 'config.json.example', 'config.json' unless 'config.json'.IO.e;

    my package EXPORT::DEFAULT {
        my %config := from-json 'config.json'.IO.slurp;
        for %config.kv -> $k, $v {
            OUR::{"RB_{$k.uc}"} = $v;
        }
        OUR::RB_PWD = $*CWD;
    }
}
