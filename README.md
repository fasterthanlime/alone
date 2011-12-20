
## Well hi there!

This is an experimental (you're used to this word with me by now, aren't you?) entry for Ludum Dare 22. I've always wanted to make an entry to that contest, and today I was like FUCK YEAH I feel like doing ooc all night, so there we go.

## How to build it?

Clone it, go to libs/, clone the following:

  * https://github.com/nddrylliog/zombieconfig
  * https://github.com/nddrylliog/ooc-gdk
  * https://github.com/nddrylliog/ooc-gtk
  * https://github.com/nddrylliog/ooc-cairo
  * https://github.com/fredreichbier/deadlogger
  * https://github.com/nddrylliog/ooc-rsvg

Then source "devrc" (or just export OOC\_LIBS=path-to-alone/libs),
hit `rock -v` in the root directory and you're good to go!

## What is there to play?

=============
Game controls
=============

Left/Right arrow = walk
Space = jump
Backspace = try a level again

=====================
Level editor controls
=====================

F12 = switch editor mode on/off

---------------
In idle mode
---------------

F1 = load level (esc to cancel, enter to confirm)
F2 = save level
F3 = rename level
F4 = change minimum kills to win
F5 = change welcome message
F6 = change win message
F7 = change next level (enter "<win>" for last level)

----------------
In drop mode
----------------

Left/right arrow cycle between droppables
Right click also cycles between droppables
Left click drops

Start and end points are unique, you can drag them around as
you want (useful for end point to position the rocket ship right)

Vacuums are oriented, click to position, hold and drag to rotate
it the way you want.

Swarms can be sized however you want, click to position, hold and
drag to change the radius however you want.

In decor mode, use 'F1' to choose your own svg file. There's no way
to move a decor once dropped, sorry (we had to edit json files by hand,
it's pretty cool)

===================
Config file
===================

You can adjust the resolution with screenX/screenY,
and change the initial level (see comments) in alone.config
