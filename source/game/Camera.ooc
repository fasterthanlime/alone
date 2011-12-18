

/*
 * The camera allows us to convert between screen
 * coordinates and world coordinates, and back.
 *
 * It also follows the hero (smoothly) in game mode,
 * and can be moved with the WASD keys in edit mode
 */

// game deps
import ui/[Input, MainUI]
import math/[Vec2]
import Level, Hero

// libs deps
import deadlogger/Log

Camera: class extends Actor {

    ui: MainUI
    input: Input

    logger := static Log getLogger(This name)

    pos := vec2(0, 0)
    camAlpha := 0.2

    mouseworldpos := vec2(0, 0)
    halfScreen := vec2(0, 0)

    init: func (=ui) {
        input = ui input
        halfScreen = vec2(ui width / 2, ui height / 2)
    }

    update: func (delta: Float) {
        // update pointer world position
        mouseworldpos = toWorldPos(input mousepos)

        match (ui mode) {
            case UIMode GAME =>
                // follow hero!
                pos set!(ui level hero body pos)
            case UIMode EDITOR =>
                // stand still
        }

        translationTarget := pos sub(halfScreen) mul(-1)

        ui translation interpolate!(translationTarget, camAlpha)
    }
    
    toWorldPos: func (v: Vec2) -> Vec2 {
        v sub(halfScreen) add(pos)
    }

    toScreenPos: func (v: Vec2) -> Vec2 {
        v add(halfScreen) sub(pos)
    }

}
