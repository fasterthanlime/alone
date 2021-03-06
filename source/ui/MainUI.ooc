
/*
 * Main UI. Mostly initializing SDL, launching the input
 * system, and tada!
 */

use gobject, cairo, sdl, deadlogger

// game deps
import Sprite, Input
import game/[Level, Hero]
import math/[Vec2, Vec3]

// libs deps
import deadlogger/Log
import cairo/[Cairo] 
import structs/[ArrayList]
import zombieconfig
import sdl/[Sdl, Event, Video]
import gobject

UIMode: enum {
    MENU
    GAME
    GAME_OVER
    EDITOR
    ULTIMATE_WIN
}

MainUI: class {
    debug := false
    debugRender := false

    width, height: Int
    screen, sdlSurface: SdlSurface*
    cairoSurface: ImageSurface
    cairoContext: Context

    logger := static Log getLogger(This name)

    level: Level // current level being drawn
    input: Input

    translation := vec2(0, 0)

    mode := UIMode MENU

    init: func (config: ZombieConfig) {
        g_type_init() // needed for librsvg to work
        SDL init(SDL_INIT_EVERYTHING)

        width  = config["screenWidth"]  toInt()
        height = config["screenHeight"] toInt()

        flags := SDL_HWSURFACE
        if(config["fullScreen"] == "true") {
            flags |= SDL_FULLSCREEN
        }

        screen = SDLVideo setMode(width, height, 32, flags)
        SDLVideo wmSetCaption(config["title"], null)

        sdlSurface = SDLVideo createRgbSurface(SDL_HWSURFACE, width, height, 32,
            0x00FF0000, 0x0000FF00, 0x000000FF, 0)

        cairoSurface = ImageSurface new(sdlSurface@ pixels, CairoFormat RGB24,
            sdlSurface@ w, sdlSurface@ h, sdlSurface@ pitch)

        cairoContext = Context new(cairoSurface)

        // init input system
        input = Input new(this)

        createUIParts()

        setupEvents()
    }

    setupEvents: func {
        input onKeyPress(Keys F12, ||
            this mode = match (this mode) {
                case UIMode EDITOR =>
                    level editor setEnabled(false)
                    UIMode GAME
                case UIMode GAME   =>
                    level editor setEnabled(true)
                    UIMode EDITOR
                case => this mode
            }
        )

        input onKeyPress(Keys ENTER, ||
            this mode = match (this mode) {
                case UIMode MENU         => level reset(); UIMode GAME
                case UIMode GAME_OVER    => UIMode MENU
                case UIMode ULTIMATE_WIN => UIMode MENU
                case => this mode
            }
        )

        input onKeyPress(Keys ESC, ||
            match (this mode) {
                case UIMode MENU => quit()
                case UIMode GAME => this mode = UIMode MENU
            }
        )
    }

    quit: func {
        SDL quit()
	exit(0)
    }

    gameoverUI: GroupSprite
    gamewinUI: GroupSprite
    menuUI: GroupSprite

    hud: GroupSprite
    healthPercentageSprite: LabelSprite
    hitsNumberSprite: LabelSprite
    levelNameSprite: LabelSprite
    modeSprite: LabelSprite

    notifScreen: GroupSprite
    notifTextSprite: LabelSprite

    notifyCounter := 0

    bloodScreen: ImageSprite

    blinkyText: LabelSprite
    blinkyCounter := 20

    createUIParts: func {
        // create hud
        hud = GroupSprite new()

        barHeight := 40
        barAlpha := 0.8

        topBar := RectSprite new(vec2(width / 2, barHeight / 2))
        topBar size set!(width, barHeight)
        topBar color = vec3(0.0, 0.0, 0.0)
        topBar alpha = barAlpha
        hud add(topBar)

        bottomBar := RectSprite new(vec2(width / 2, height - barHeight / 2))
        bottomBar size set!(width, barHeight)
        bottomBar color = vec3(0.0, 0.0, 0.0)
        bottomBar alpha = barAlpha
        hud add(bottomBar)

        credits := LabelSprite new(vec2(width / 2, height - 20), "Made for Ludum Dare #22 by Amos Wenger, Einat Schlagmann, and Sylvain Wenger")
        credits centered = true
        credits color = vec3(1.0, 0.7, 0.7)

        hud add(credits)
        healthSprite := ImageSprite new(vec2(10, 10), "assets/svg/health.svg")
        hud add(healthSprite)

        healthPercentageSprite = LabelSprite new(vec2(70, 20), "100%")
        healthPercentageSprite color = vec3(1.0, 1.0, 1.0)
        healthPercentageSprite centered = true
        hud add(healthPercentageSprite)

        hitsSprite := ImageSprite new(vec2(width - 120, 10), "assets/svg/score.svg")
        healthPercentageSprite centered = true
        hud add(hitsSprite)

        hitsNumberSprite = LabelSprite new(vec2(width - 60, 20), "0/10")
        hitsNumberSprite color = vec3(1.0, 1.0, 1.0)
        hitsNumberSprite centered = true
        hud add(hitsNumberSprite)

        // create blood screen
        bloodScreen = ImageSprite new(vec2(0, 0), "assets/svg/bloodScreen.svg")
        bloodScreen scale set!(width / 1920.0, height / 1080.0)

        // create notifScreen
        notifScreen = GroupSprite new()
        notifBg := RectSprite new(vec2(width / 2, 200))
        notifBg color = vec3(0.0, 0.0, 0.0)
        notifBg alpha = 0.5
        notifBg size set!(width - 40, 200)
        notifScreen add(notifBg)

        notifTextSprite = LabelSprite new(vec2(width / 2, 200), "Notification!")
        notifTextSprite color = vec3(1.0, 1.0, 1.0)
        notifTextSprite centered = true
        notifTextSprite fontSize = 30.0
        notifScreen add(notifTextSprite)

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

        // create game won screen
        gamewinUI = GroupSprite new()

        gamewinBg := RectSprite new(vec2(width / 2, height / 2))
        gamewinBg size set!(width, height)
        gamewinBg color = vec3(1.0, 0.7, 0.7)
        gamewinUI add(gamewinBg)

        nyan := ImageSprite new(vec2(width / 2, 400), "assets/svg/kitten_wShadow.svg")
        nyan offset set!(- nyan width / 2, - nyan height / 2) 
        gamewinUI add(nyan)

        gamewinText := LabelSprite new(vec2(width / 2, height - 200), "YOU WON THE INTERNET.")
        gamewinText color = vec3(1.0, 1.0, 1.0)
        gamewinText centered = true
        gamewinText fontSize = 80.0
        gamewinUI add(gamewinText)

        // create menu screen
        menuUI = GroupSprite new()
        menuBg := ImageSprite new(vec2(0, 0), "assets/png/titleScreenBg.png")
        menuBg scale set!(width / 1920.0, height / 1080.0)
        menuUI add(menuBg)

        menuRect := RectSprite new(vec2(width / 2, 80))
        menuRect size set!(width, 160)
        menuRect color = vec3(0.0, 0.0, 0.0)
        menuRect alpha = 0.7
        menuUI add(menuRect)

        menuRect = RectSprite new(vec2(width / 2, height - 40))
        menuRect size set!(width, 80)
        menuRect color = vec3(0.0, 0.0, 0.0)
        menuRect alpha = 0.7
        menuUI add(menuRect)

        titleText := LabelSprite new(vec2(width / 2, 60), "LONELY PLANET")
        titleText color = vec3(1.0, 1.0, 1.0)
        titleText centered = true
        titleText fontSize = 80.0
        menuUI add(titleText)

        titleText = LabelSprite new(vec2(width / 2, 130), "A story of love and loss. And kittens.")
        titleText color = vec3(1.0, 1.0, 1.0)
        titleText centered = true
        titleText fontSize = 30.0
        menuUI add(titleText)

        blinkyText = LabelSprite new(vec2(width / 2, height - 40), "Press enter to start")
        blinkyText color = vec3(1.0, 1.0, 1.0)
        blinkyText centered = true
        blinkyText fontSize = 30.0
        menuUI add(blinkyText)
    }
    
    notify: func (msg: String, duration := 100) {
        notifTextSprite text = msg
        notifyCounter = duration
    }

    reset: func {
        // reset all signal handlers
        input disconnect()
        input = Input new(this)
        setupEvents()
    }

    redraw: func {
        draw()
        input _poll()
    }

    draw: func {
        cr := cairoContext

        // clear screen and go again!
        cr setSourceRGB(0.0, 0.0, 0.0)
        cr paint()

        paint(cr)

        SDLVideo blitSurface(sdlSurface, null, screen, null)
        SDLVideo flip(screen)
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
        } else if (mode == UIMode ULTIMATE_WIN) {
            gamewinUI draw(cr)
        } else if (mode == UIMode MENU) {
            blinkyCounter -= 1
            if(blinkyCounter <= 0) {
                blinkyCounter = 20
                blinkyText visible = !blinkyText visible
            }
            menuUI draw(cr)
        }
    }

    drawUI: func (cr: Context) {
        if (mode == UIMode GAME) {
            // the less life we have, the less we see
            cr rectangle(0, 0, width, height)
            cr clip()
            cr setSourceRGB(0.0, 0.0, 0.0)
            cr paintWithAlpha(1.0 - level hero life / 100.0)

            if (level hero bloody) {
                bloodScreen draw(cr)
            }
        }

        hud draw(cr)

        if(notifyCounter > 0) {
            notifyCounter -= 1
            notifScreen draw(cr)
        }

        healthPercentageSprite text = "%d%%" format(level hero life)
        hitsNumberSprite text = "%d/%d" format(level hitsNumber, level totalHitsNumber)

        // draw editor UI, if any
        if (mode == UIMode EDITOR) {
            level editor paint(cr)
        } else {
        }
    }

    background: func (cr: Context) {
        cr setSourceRGB(0.1, 0.1, 0.1)
        cr paint()
    }

}
