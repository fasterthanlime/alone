use deadlogger

// game deps
import ui/[Sprite, MainUI]
import Engine, Level

import math/[Vec2, Vec3]

// libs deps
import deadlogger/Log

Hero: class extends Actor {

    logger := static Log getLogger(This name)
    mainSprite : Sprite
    reflectionSprite : Sprite

    ui: MainUI

    groundHeight := 0.0
    touchesGround := false
    jumpSpeed := 30.0
    speed := 18.0
    speedAlpha := 0.8
    scale := 0.3

    hb : RectSprite // hit box
    bb : RectSprite // bounding box

    body: Body
    direction := 1.0 // 1 = right, -1 = left


    init: func (=level, =groundHeight) {
        ui = level engine ui
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

        mainSprite = SvgSprite new(body pos, "assets/svg/movingObj_Full.svg")
        mainSprite scale = vec2(scale, scale)
        mainSprite offset x = - bb size x / 2
        mainSprite offset y = - bb size y / 2 - 20
        level sprites add(mainSprite)
    }

    update: func (delta: Float) {
        // logger info("Position = %s" format(body pos _)) 

        if (ui isPressed(Keys LEFT)) {
            body speed interpolateX!(-speed, speedAlpha)
            direction = -1.0
        } else if (ui isPressed(Keys RIGHT)) {
            body speed interpolateX!(speed, speedAlpha)
            mainSprite scale = vec2(-scale, scale)
            direction = 1.0
        } else {
            body speed interpolateX!(0, speedAlpha)
        }

        if (touchesGround && ui isPressed(Keys SPACE)) {
            body speed y = -jumpSpeed
        }

        body update(delta)

        minAlpha := 0.2
        alphaAlpha := 0.1
        mainSprite alpha = mainSprite alpha * (1 - alphaAlpha) +
                        (body speed norm() / 18.0 + minAlpha) * alphaAlpha
        if (mainSprite alpha > 1.0) {
            mainSprite alpha = 1.0
        }

        // artificial ground collision
        maxHeight := groundHeight - bb size y / 2
        if (body pos y > maxHeight) {
            if (body speed y > 0) {
                body speed y = 0
            }
            body pos y = maxHeight
            touchesGround = true
        } else {
            touchesGround = false
        }

        mainSprite pos = body pos
        mainSprite       offset x = direction * bb size x / 2
        mainSprite       scale x = - direction * scale
    }

}






