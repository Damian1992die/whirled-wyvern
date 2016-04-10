This applies to building the Wyvern core game, avatars and pets, as originally written by Aduros.

# Requirements #

  * Flex SDK
  * Whirled SDK
  * Ant (If you're on Windows, [WinAnt](http://code.google.com/p/winant/) provides a nice installer)

For building Monsters:
  * Imagemagick (For generating the shop thumbnail. This is probably more trouble than it's  worth to get working on Windows, so just comment it out from Monster's build.xml)

Then go to each module's directory (game, player, monster...) and run ant.

# Halp! #

There are pages on the [Whirled wiki](http://wiki.whirled.com/Setting_up_your_programming_environment) for using this kind of build environment. For Ant help, post to Whirled Coders. If you're reasonably sure you've come across a bug in the build scripts, contact Aduros.