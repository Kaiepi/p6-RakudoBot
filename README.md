NAME
====

RakudoBot - IRC bot for testing Rakudo builds

DESCRIPTION
===========

RakudoBot is an IRC bot for testing builds of Rakudo. To install, run:

    $ git clone https://github.com/Kaiepi/p6-RakudoBot.git
    $ cd p6-RakudoBot
    $ cp config.json.example config.json
    $ zef install .

Afterwards, edit `config.json` to suit your needs. To start the bot, run:

    $ screen -L -S rakudo-bot rakudo-bot

COMMANDS
========

Commands may be used by addressing the bot.

  * **build**

Runs `Configure.pl` and `make`, outputting any errors.

  * **test**

Runs `make test`, outputting any errors.

  * **spectest**

Runs `make spectest`, outputting any errors.

  * **all**

Runs `Configure.pl`, `make`, `make test`, and `make spectest`, outputting any errors.

  * **github**

  * **git**

  * **source**

Link to the source repo for the bot.

  * **help**

Displays help for the bot's commands.

CONFIG
======

  * **host**

The host the bot will connect to.

  * **nickname**

The bot's nickname.

  * **password**

The bot's password, if any.

  * **username**

The bot's username.

  * **channel**

The channel the bot will be active in.

  * **maintainer**

The nickname of the maintainer of the bot (you) in case users need to contact them.

  * **source**

Link to the source repo of the bot.

  * **rakudo_path**

The path to the directory containing Rakudo's source code. If it doesn't exist, clone <https://github.com/perl6/rakudo.git> and change this to its path.

  * **config_flags**

Flags to pass to `Configure.pl` when building Rakudo. For more information, run this from the directory containing Rakudo's source code:

    $ ./Configure.pl --help

  * **debug**

Enable/disable debug logging.

AUTHOR
======

Ben Davies <kaiepi@outlook.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2017 Ben Davies

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

