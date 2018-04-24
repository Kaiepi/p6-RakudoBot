use v6.c;
use IRC::Client;
use IRC::Client::Plugin::Rakudo;
use RakudoBot::Config;
unit module RakudoBot:ver<0.0.1>:auth<github:Kaiepi>;

my IRC::Client::Plugin::Rakudo $rakudo-plugin .= new:
    :channel(RB_CHANNEL),
    :maintainer(RB_MAINTAINER),
    :source(RB_SOURCE),
    :rakudo-path(RB_RAKUDO_PATH),
    :config-flags(RB_CONFIG_FLAGS),
    :debug(RB_DEBUG);

.run with IRC::Client.new:
    :host(RB_HOST),
    :nick(RB_NICKNAME),
    :password(RB_PASSWORD),
    :username(RB_USERNAME),
    :channels(RB_CHANNEL),
    :debug(RB_DEBUG),
    :plugins($rakudo-plugin);

=begin pod

=head1 NAME

RakudoBot - IRC bot for testing Rakudo builds

=head1 DESCRIPTION

RakudoBot is an IRC bot for testing builds of Rakudo. To install, run:

    $ git clone https://github.com/Kaiepi/p6-RakudoBot.git
    $ cd p6-RakudoBot
    $ cp resources/config.json.example resources/config.json
    $ zef install .

Afterwards, edit C<config.json> to suit your needs. To start the bot, run:

    $ screen -L -S rakudo-bot rakudo-bot

Note: you will need to run C<zef install . --force-install> if you make changes
to C<config.json> after installing RakudoBot, since Zef caches it.

=head1 COMMANDS

Commands may be used by addressing the bot.

=item B<build>

Runs C<Configure.pl> and C<make>, outputting any errors.

=item B<test>

Runs C<make test>, outputting any errors.

=item B<stresstest>

Runs C<make stresstest>, outputting any errors.

=item B<all>

Runs C<Configure.pl>, C<make>, C<make test>, and C<make spectest>, outputting
any errors.

=item B<github>
=item B<git>
=item B<source>

Link to the source repo for the bot.

=item B<help>

Displays help for the bot's commands.

=head1 CONFIG

=item B<host>

The host the bot will connect to.

=item B<nickname>

The bot's nickname.

=item B<password>

The bot's password, if any.

=item B<username>

The bot's username.

=item B<channel>

The channel the bot will be active in.

=item B<maintainer>

The nickname of the maintainer of the bot (you) in case users need to contact
them.

=item B<source>

Link to the source repo of the bot.

=item B<rakudo_path>

The path to the directory containing Rakudo's source code. If it doesn't exist,
clone <https://github.com/perl6/rakudo.git> and change this to its path.

=item B<config_flags>

Flags to pass to C<Configure.pl> when building Rakudo. For more information, run
this from the directory containing Rakudo's source code:

    $ ./Configure.pl --help

=item B<debug>

Enable/disable debug logging.

=head1 AUTHOR

Ben Davies <kaiepi@outlook.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Ben Davies

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
