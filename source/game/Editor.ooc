
/*
 * Level editor, including level editor ui
 */

// game deps
import ui/[MainUI, Input, Sprite]
import game/[Level, Platform, Hero, Camera]
import EditModes
import math/[Vec2]

// libs deps
import deadlogger/Log
import cairo/[Cairo, GdkCairo] 
import structs/[HashMap]

Editor: class extends Actor {

    logger := static Log getLogger(This name)

    ui: MainUI
    level: Level
    input: Input

    cameraSpeed := 25.0

    // ALLLL the possible modes
    IDLE: EditMode
    DROP: EditMode

    // the current mode
    mode: EditMode

    init: func (=ui, =level) {
        input = ui input

        setupEvents()
        setupEditModes()
    }

    setupEditModes: func {
        IDLE = IdleMode new(this)
        DROP = DropMode new(this)

        mode = IDLE
    }

    setupEvents: func {
        // mode swap
        input onKeyPress(Keys F12, ||
            ui mode = match (ui mode) {
                case UIMode EDITOR =>
                    mode leave()
                    UIMode GAME
                case UIMode GAME   =>
                    mode enter()
                    UIMode EDITOR
            }
        )

        input onKeyPress(Keys BACKSPACE, ||
            if (ui mode != UIMode EDITOR) return

            level reset()
        )

        input onKeyPress(Keys E, ||
            if (ui mode != UIMode EDITOR) return

            change(DROP)
        )
    }

    moveCamera: func (x, y: Float) {
        level camera pos add!(vec2(x, y) mul(cameraSpeed))
    }

    paint: func (cr: Context) {
        if (ui mode != UIMode EDITOR) return

        cr moveTo(200, 200)
        cr setFontSize(80.0)
        cr setSourceRGB(1.0, 0.3, 0.3)
        cr showText("EDITOR, BITCHES!")

        cr moveTo(100, 100)
        cr setFontSize(40.0)
        cr showText("edit mode: %s" format(mode name))

        mode paint(cr)
    }

    update: func (delta: Float) {
        mode update(delta)

        if(input isPressed(Keys W)) { moveCamera( 0, -1) }
        if(input isPressed(Keys A)) { moveCamera(-1,  0) }
        if(input isPressed(Keys S)) { moveCamera( 0,  1) }
        if(input isPressed(Keys D)) { moveCamera( 1,  0) }
    }

    change: func (newMode: EditMode) {
        if (ui mode == UIMode EDITOR) {
            mode leave()
            mode = newMode
            mode enter()
        } else {
            mode = newMode
        }
    }

}
