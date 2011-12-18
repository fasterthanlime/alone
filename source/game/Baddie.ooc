
// game deps
import ui/[Sprite, MainUI]
import Engine, Level, Hero

import math/[Vec2, Vec3, Random]

BaddieState: enum {
    CMON,
    GTFO,
    WTF
}

Baddie: class extends Actor {

    ui: MainUI

    hero: Hero

    mainSprite: Sprite
    bb: RectSprite // bounding box
    box: Box

    body: Body
    direction := 1.0

    counter := 0

    speed := 8.0
    speedAlpha := 0.5

    collideCounter := 0
    collideDuration := 15

    state := BaddieState CMON

    init: func (=level) {
        hero = level hero
        ui = level engine ui

        body = Body new(level)
        body gravity = 0.0

        bb = RectSprite new(body pos)
        bb filled = false
        bb size = vec2(40, 40)
        bb color = vec3(0.3, 0.3, Random randInt(0, 255) / 255.0)
        // level sprites add(bb)

        mainSprite = SvgSprite new(body pos, "assets/svg/baddies/Baddie1_Full.svg")
        mainSprite scale = vec2(0.2, 0.2)
        mainSprite offset = vec2(-40, -40)
        level sprites add(mainSprite)

        box = Box new(bb)
        level collideables add(box)
    }

    update: func (delta: Float) {
        diff := hero body pos sub(body pos)
        motion := diff
        alpha := 0.05

        match (state) {
            case BaddieState CMON =>
                motion = diff
            case BaddieState GTFO =>
                alpha = 0.2
                motion = diff mul(-1)
            case BaddieState WTF =>
                motion = vec2(Random randInt(-200, 200), Random randInt(-200, 200))
        }

        if (hero body speed norm() > 3.0) {
            state = BaddieState CMON 
            level collides?(box, |bang|
                state = BaddieState WTF
            )
        } else if (diff norm() < 300.0) {
            state = BaddieState GTFO
        } else {
            state = BaddieState WTF
        }

        body speed interpolate!(motion normalized() mul(speed), alpha)
        body update(delta)
    }

}
