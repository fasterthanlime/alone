use deadlogger

// game deps
import ui/[Sprite, MainUI, Input]
import Engine, Level, Collision, Baddie

import math/[Vec2, Vec3]

// libs deps
import deadlogger/Log

Hero: class extends Actor {

    logger := static Log getLogger(This name)
    mainSprite : Sprite
    reflectionSprite : Sprite

    ui: MainUI
    input: Input

    touchesGround := false
    jumpSpeed := 30.0
    speed := 18.0
    speedAlpha := 0.8
    scale := 1.0

    life := 100

    hb : RectSprite // hit box
    bb : RectSprite // bounding box
    box: Box

    body: Body
    direction := 1.0 // 1 = right, -1 = left

    bloody := false

    init: func (=level) {
        ui = level engine ui
        input = ui input
        body = Body new(level)
        
        bb = RectSprite new(body pos)
        bb filled = false
        bb size = vec2(60, 100)
        level debugSprites add(bb)

        hb = RectSprite new(body pos)
        hb filled = false
        hb size = vec2(40, 60)
        hb color = vec3(0.0, 1.0, 0.0)
        level debugSprites add(hb)

        mainSprite = SvgSprite new(body pos, 0.3, "assets/svg/movingObj_Full.svg")
        mainSprite offset x = - bb size x / 2
        mainSprite offset y = - bb size y / 2 - 20
        level sprites add(mainSprite)

        box = Box new(bb)
        box actor = this
        level collideables add(box)
    }

    update: func (delta: Float) {
        logger info("Position = %s" format(body pos _)) 

        if (input isPressed(Keys LEFT)) {
            body speed interpolateX!(-speed, speedAlpha)
            direction = -1.0
        } else if (input isPressed(Keys RIGHT)) {
            body speed interpolateX!(speed, speedAlpha)
            mainSprite scale = vec2(-scale, scale)
            direction = 1.0
        } else {
            body speed interpolateX!(0, speedAlpha)
        }

        if (touchesGround && input isPressed(Keys SPACE)) {
            body speed y = -jumpSpeed
        }

        body update(delta)

        touchesGround = false
        bloody = false

        numCollisions := 0
        reaction := vec2(0)
        perp := vec2(0)
        
        level collides?(box, |bang|
            valid := true

            if(bang other && bang other actor) {
                match (bang other actor) {
                    case baddie: Baddie =>
                        angle := body pos sub(baddie body pos) angle()
                        if (angle > 0.0) {
                            life -= 1
                            bloody = true
                            valid = false
                        }
                }
            }

            // we might need multi-constraint resolution
            // later on
            // logger info ("Bang, dir %s, depth %.2f" format(bang dir _, bang depth))
            if (valid) {
                reaction add!(bang dir mul(bang depth))
                perp add!(bang dir perp())
                numCollisions += 1
                if (bang dir y < - 0.5) {
                    touchesGround = true
                }
            }
        )

        if (numCollisions > 0) {
            factor := 1.0 / numCollisions as Float
            body pos add!(reaction mul(factor))
            body speed project!(perp mul(factor))
        }

        minAlpha := 0.2
        alphaAlpha := 0.1
        mainSprite alpha = mainSprite alpha * (1 - alphaAlpha) +
                        (body speed norm() / 18.0 + minAlpha) * alphaAlpha
        if (mainSprite alpha > 1.0) {
            mainSprite alpha = 1.0
        }

        bb pos              = body pos
        hb pos              = body pos
        mainSprite pos      = body pos
        mainSprite offset x = direction * bb size x / 2
        mainSprite scale  x = - direction * scale
    }

}






