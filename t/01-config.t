use v6.c;
use RakudoBot::Config;
use Test;

plan 10;

ok defined RB_HOST;
ok defined RB_NICKNAME;
ok defined RB_PASSWORD;
ok defined RB_USERNAME;
ok defined RB_CHANNEL;

ok defined RB_MAINTAINER;
ok defined RB_SOURCE;
ok defined RB_TEST_JOBS;
ok defined RB_CONFIG_FLAGS;

ok defined RB_DEBUG;
