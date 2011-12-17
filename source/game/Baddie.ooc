
// game deps
import ui/[Sprite, MainUI]
import Engine, Level, Hero

import math/[Vec2, Vec3, Random]

BaddieState: enum {
    CMON,
    GTFO
}

Baddie: class extends Actor {

    ui: MainUI

    touchesGround := false
    groundHeight := 0.0

    hero: Hero

    mainSprite: EllipseSprite
    bb: RectSprite // bounding box
    box: Box

    body: Body
    direction := 1.0

    counter := 0

    speed := 8.0
    speedAlpha := 0.5

    collideCounter := 0
    collideDuration := 15

    scale := 0.25

    state := BaddieState CMON

    init: func (=level, =groundHeight, =hero) {
        ui = level engine ui

        body = Body new(level)
        body gravity = 0.0

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
        diff := hero body pos sub(body pos)

        match (state) {
            case BaddieState CMON =>
                // nuffin to do
            case BaddieState GTFO =>
                diff = diff mul(-1.0)
        }

        if (hero body speed norm() < 3.0 && diff norm() < 200.0) {
            state = BaddieState GTFO
        } else {
            state = BaddieState CMON
        }

        body speed interpolate(diff normalized() mul(speed), 0.05)
        body update(delta)
    }

}
