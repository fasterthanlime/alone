
/*
 * Main UI. Mostly a gtk window creating a cairo
 * context on each redraw, forcing a redraw every
 * few milliseconds.
 */

use cairo, gtk, deadlogger

// game deps
import Sprite, Input
import game/[Level, Hero]
import math/[Vec2, Vec3]

// libs deps
import deadlogger/Log
import cairo/[Cairo, GdkCairo] 
import gtk/[Gtk, Widget, Window]
import gdk/[Event]
import structs/[ArrayList]
import zombieconfig

UIMode: enum {
    MENU,
    GAME,
    GAME_OVER,
    EDITOR
}

MainUI: class {
    win: Window
    debug := false
    debugRender := false

    width, height: Int

    logger := static Log getLogger(This name)

    level: Level // current level being drawn
    input: Input

    translation := vec2(0, 0)

    gameoverUI: GroupSprite

    mode := UIMode GAME

    init: func (config: ZombieConfig) {
        win = Window new(config["title"])

        width  = config["screenWidth"]  toInt()
        height = config["screenHeight"] toInt()
        win setUSize(width as GInt, height as GInt)

        win setPosition(Window POS_CENTER)

        // exit on window close
        win connect("delete-event", exit) 
        win connect("expose-event", || draw())

        // init input system
        input = Input new(this)

        win showAll()

        createUIParts()
    }

    createUIParts: func {
        // create game over screen
        gameoverUI = GroupSprite new()

        gameoverBg := RectSprite new(vec2(width / 2, height / 2))
        gameoverBg size set!(width, height)
        gameoverBg color = vec3(0.0, 0.0, 0.0)
        gameoverUI add(gameoverBg)

        gameoverText := LabelSprite new(vec2(width / 2, height / 2), "GAME OVER")
        gameoverText color = vec3(1.0, 1.0, 1.0)
        gameoverText centered = true
        gameoverText fontSize = 80.0
        gameoverUI add(gameoverText)
    }

    reset: func {
        // reset all signal handlers
        input disconnect()
        input = Input new(this)
    }

    run: func {
        Gtk main()
    }

    redraw: func {
        gdkWin := win getWindow()
        gdkWin invalidateRegion(gdkWin getClipRegion(), false)
    }

    draw: func {
        gdkWin := win getWindow()
        cr := GdkContext new(gdkWin)
        paint(cr)
        cr destroy()
    }

    paint: func (cr: Context) {
        if (mode == UIMode GAME || mode == UIMode EDITOR) {
            cr translate(translation x, translation y)
            background(cr)

            // draw level
            if (level) {
                level bgSprites each(|sprite| sprite draw(cr))
                level sprites each(|sprite| sprite draw(cr))
                level fgSprites each(|sprite| sprite draw(cr))

                if(debug || debugRender || mode == UIMode EDITOR) {
                    level debugSprites each(|sprite| sprite draw(cr))
                }
            } else {
                logger error("No level set!")
            }

            // now draw the UI
            cr translate(-translation x, -translation y)
            drawUI(cr)
        } else if (mode == UIMode GAME_OVER) {
            gameoverUI draw(cr)
        }
    }

    drawUI: func (cr: Context) {
        barHeight := 40
        barAlpha := 0.8

        cr setSourceRGBA(1, 1, 1, 0.7)

        // top bar
        cr rectangle(0, 0, width, barHeight)
        cr fill()

        // bottom bar
        cr rectangle(0, height - barHeight, width, height)
        cr fill()

        // text !
        cr selectFontFace("Impact", CairoFontSlant NORMAL, CairoFontWeight NORMAL)
        cr setSourceRGB(0, 0, 0)
        cr setFontSize(26.0)

        // level title
        cr moveTo(20, 30)
        cr showText("Level: " + level name)

        // level title
        cr moveTo(350, 30)
        cr showText("Health: %d%%" format(level hero life))

        // mode
        cr moveTo(20, height - barHeight + 30)
        cr showText("Mode: %s" format(match mode {
            case UIMode GAME   => "game"    
            case UIMode EDITOR => "editor"    
        }))

        // draw editor UI, if any
        if (mode == UIMode EDITOR) {
            level editor paint(cr)
        } else {
            // the less life we have, the less we see
            cr rectangle(0, 0, width, height)
            cr clip()
            cr setSourceRGB(0.0, 0.0, 0.0)
            cr paintWithAlpha(1.0 - level hero life / 100.0)

            if (level hero bloody) {
                cr rectangle(0, 0, width, height)
                cr clip()
                cr setSourceRGB(1.0, 0.1, 0.1)
                cr paintWithAlpha(0.7)
            }
        }
    }

    background: func (cr: Context) {
        cr setSourceRGB(0.1, 0.1, 0.1)
        cr paint()
    }

}
