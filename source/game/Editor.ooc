
/*
 * Level editor, including level editor ui
 */

// game deps
import ui/[MainUI, Input, Sprite]
import game/[Level, Platform, Hero, Camera]
import math/[Vec2]

// libs deps
import deadlogger/Log
import cairo/[Cairo, GdkCairo] 

Editor: class extends Actor {

    logger := static Log getLogger(This name)

    ui: MainUI
    level: Level
    input: Input

    cameraSpeed := 18.0

    currentPlatform: Platform

    INF := -10000000000.0 // probably not in the level ;)

    init: func (=ui, =level) {
        input = ui input

        input onKeyPress(Keys F12, ||
            ui mode = match (ui mode) {
                case UIMode EDITOR =>
                    currentPlatform mainSprite alpha = 0.0
                    UIMode GAME
                case UIMode GAME   =>
                    currentPlatform mainSprite alpha = 0.5
                    UIMode EDITOR
            }
        )

        currentPlatform = Platform new(level, vec2(INF), "metal")
        currentPlatform mainSprite alpha = 0.0
        level actors add(currentPlatform)
    }

    moveCamera: func (x, y: Float) {
        logger info("Moving camera (%.2f, %.2f)" format(x, y))
        level camera pos add!(vec2(x, y) mul(cameraSpeed))
    }

    paint: func (cr: Context) {
        if (ui mode != UIMode EDITOR) return

        cr moveTo(200, 200)
        cr setFontSize(80.0)
        cr setSourceRGB(1.0, 0.3, 0.3)
        cr showText("EDITOR, BITCHES!")
    }

    update: func (delta: Float) {
        if (ui mode != UIMode EDITOR) {
            currentPlatform pos set!(INF, INF)
            return
        }

        if(input isPressed(Keys W)) { moveCamera( 0, -1) }
        if(input isPressed(Keys A)) { moveCamera(-1,  0) }
        if(input isPressed(Keys S)) { moveCamera( 0,  1) }
        if(input isPressed(Keys D)) { moveCamera( 1,  0) }

        currentPlatform pos set!(level camera mouseworldpos)
    }

}
