
// game deps
import ui/[Sprite, MainUI]
import Engine, Level

import math/[Vec2, Vec3, Random]

Baddie: class extends Actor {

    ui: MainUI

    touchesGround := false
    groundHeight := 0.0

    mainSprite: EllipseSprite
    bb: RectSprite // bounding box
    box: Box

    body: Body
    direction := 1.0

    counter := 0

    speed := 4.0
    speedAlpha := 0.5

    collideCounter := 0
    collideDuration := 15

    scale := 0.25

    init: func (=level, =groundHeight) {
        ui = level engine ui

        body = Body new(level)

        bb = RectSprite new(body pos)
        bb filled = false
        bb size = vec2(10, 10)
        bb color = vec3(0.3, 0.3, Random randInt(0, 255) / 255.0)
        ui sprites add(bb)

        mainSprite = EllipseSprite new(body pos)
        mainSprite size = vec2(15, 15)
        ui sprites add(mainSprite)

        box = Box new(bb)
        level collideables add(box)
    }

    update: func (delta: Float) {
        counter = counter - 1
        if (counter < 0) {
            counter = Random randInt(40, 600)
            direction = -direction
        } else if (collides?()) {
            direction = -direction
        }

        body speed interpolateX(speed * direction, speedAlpha)

        body update(delta)

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
    }

    collides?: func -> Bool {
        if (collideCounter > 0) {
            collideCounter = collideCounter - 1
            return false
        }

        collides := false

        if (body pos x - bb size x / 2 < 0) {
            collides = true
        } else if (body pos x + bb size x / 2 > ui width) {
            collides = true
        } else {
            level collides?(box, |bang|
                // TODO: do more interesting stuff with the info here
                collides = true 
            )
        }

        if (collides) {
            collideCounter = Random randInt(0, collideDuration)
        }
        collides
    }

}
