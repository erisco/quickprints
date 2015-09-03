# QuickPrints

A mod for [Factorio](http://www.factorio.com/), QuickPrints offers convenient blueprints for the early game.

## What it does

- Unlocks the "Automated Construction" research automatically, allowing you to place ghost objects (and place blueprints).
- Gives you empty blueprints for free whenever you want them.
- Constructs ghost objects using items from your inventory automatically (just run nearby!).

## How to install

This mod installs the same way as most Factorio mods, so if you are already familiar with how to do that then you're good to go. Otherwise, here is more detail.

In the Factorio mods directory, create a new sub-directory named `QuickPrints_version` where "version" is the version number found in QuickPrint's `info.json` file (for example, `0.1.0`).

Then, either clone this repository into the `QuickPrints_version` directory or copy the contents of this repository into that directory.

For more information, read "[Modding Overview](http://www.factorioforums.com/wiki/index.php?title=Modding_overview)" from the Factorio Wiki.

## How to use (GUI)

When in-game, click the `QuickPrints` button. This button should be on the top of your screen. If not, see the `init` command in section "How to use (console)".

  - `On` Enables QuickPrints mode for yourself.
  - `Off` Disables QuickPrints mode for yourself.
  - `Give Blueprint` Give yourself an empty blueprint.
  - `Unlock Research` Unlocks the "Automated Construction" research.
  - `Help` Prints help information to the console.

## How to use (console)

These are all commands that you type into the in-game console -- you must have a game loaded to access it. The default key to open and close the console is tilde, i.e. `~`.

Print help information:

    /c remote.call("qp","help",player_index)

Unlock "Automated Construction" research:

    /c remote.call("qp","research")

Give a player a blueprint:

    /c remote.call("qp","blueprint",player_index)

Initialise QuickPrints for a player. This should be done automatically, but in case something goes awry you can call this manually:

    /c remote.call("qp","init",player_index)

Enable, disable, and toggle QuickPrints mode:

    /c remote.call("qp","enable",player_index)
    /c remote.call("qp","disable",player_index)
    /c remote.call("qp","toggle",player_index)

Only when "QuickPrints mode" is enabled will nearby ghost objects be replaced with items from your inventory. By default it is disabled.

For the most convenience, use the toggle command and exploit the console's command history -- when the console is open press your keyboard's up arrow to re-enter the last used command. 