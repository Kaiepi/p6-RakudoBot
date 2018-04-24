use v6.c;
use JSON::Fast;
unit module RakudoBot::Config;

CHECK {
    my package EXPORT::DEFAULT {
        my %config := from-json %?RESOURCES<config.json>.IO.slurp;
        for %config.kv -> $k, $v {
            OUR::{"RB_{$k.uc}"} := $v;
        }
    }
}
