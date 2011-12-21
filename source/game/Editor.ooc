
/*
 * Level editor, including level editor ui
 */

// game deps
import ui/[MainUI, Input, Sprite]
import game/[Level, Platform, Hero, Camera]
import EditModes, LevelSaver
import math/[Vec2]

// libs deps
import deadlogger/Log
import cairo/[Cairo] 
import structs/[HashMap, ArrayList]

Editor: class extends Actor {

    logger := static Log getLogger(This name)

    ui: MainUI
    sprites := ArrayList<Sprite> new()

    level: Level
    levelName: String

    cameraSpeed := 25.0

    // ALLLL the possible modes
    IDLE: EditMode
    DROP: EditMode

    // the current mode
    mode: EditMode

    input: Proxy

    init: func (=ui, =level, =levelName) {
        input = ui input sub()

        setupEvents()
        setupEditModes()
    }

    setupEditModes: func {
        IDLE = IdleMode new(this)
        DROP = DropMode new(this)

        mode = IDLE
    }

    setEnabled: func (b: Bool) {
        input enabled = b
        if (b) {
            mode enter()
        } else {
            mode leave()
        }
    }

    setupEvents: func {
        // works in both mode for debug
        ui input onKeyPress(Keys BACKSPACE, ||
            if(ui mode == UIMode GAME || ui mode == UIMode EDITOR) {
                level reset()
            }
        )

        // -------------------
        // STUFF THAT ONLY WORKS IN EDIT MODE
        // -------------------
    }

    moveCamera: func (x, y: Float) {
        level camera pos add!(vec2(x, y) mul(cameraSpeed))
    }

    paint: func (cr: Context) {
        if (ui mode != UIMode EDITOR) return

        cr selectFontFace("Impact", CairoFontSlant NORMAL, CairoFontWeight NORMAL)
        cr setSourceRGB(1.0, 0.3, 0.3)
        cr moveTo(100, 100)
        cr setFontSize(40.0)
        cr showText("edit mode: %s" format(mode name))

        mode paint(cr)

        sprites each(|sprite| sprite draw(cr))
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
