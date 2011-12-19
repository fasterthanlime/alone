
// game deps
import ui/[Sprite, MainUI]
import Engine, Level, Hero, Collision, Vacuum

import math/[Vec2, Vec3, Random]

BaddieState: enum {
    CMON,
    GTFO,
    WTF,
    DUI
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

    scale := 0.5

    state := BaddieState CMON
    attractor: Vacuum

    gtfoCounter := -1

    init: func (=level) {
        hero = level hero
        ui = level engine ui

        body = Body new(level)
        body gravity = 0.0

        mainSprite = SvgSprite new(body pos, 0.1, "assets/svg/baddies/baddie2_Full.svg")
        mainSprite scale = vec2(0.5, 0.5)
        mainSprite offset = vec2(-40, -40)
        level fgSprites add(mainSprite)

        bb = RectSprite new(body pos)
        bb size = vec2(40, 40)
        box = Box new(bb)
        level collideables add(box)
    }

    cleanup: func {
        level fgSprites remove(mainSprite)
        level collideables remove(box)
    }

    isPermanent: func -> Bool {
        // baddie are spawned from swarms
        false
    }

    update: func (delta: Float) {
        diff := hero body pos sub(body pos)
        motion := diff
        alpha := 0.2

        vacuumInfluence := 300.0

        // attempt to find close vacuums
        changed := false
        level vacuums each(|vacuum|
            dist := vacuum pos sub(body pos) norm()
            if (dist < vacuumInfluence) {
                changed = true
                state = BaddieState DUI
                attractor = vacuum
            }
            targetAlpha := dist / vacuumInfluence
            if (mainSprite alpha > targetAlpha) {
                mainSprite alpha = targetAlpha
            }
        )

        match (state) {
            case BaddieState DUI =>
                motion = attractor pos sub(body pos)
            case BaddieState CMON =>
                motion = diff mul(3.0)
            case BaddieState GTFO =>
                alpha = 0.2
                motion = diff mul(-1)
            case BaddieState WTF =>
                motion = vec2(Random randInt(-200, 200), Random randInt(-200, 200))
        }

        if (!changed) {
            if (hero body speed norm() > 3.0) {
                state = BaddieState CMON 
                level collides?(box, |bang|
                    state = BaddieState WTF
                )
                gtfoCounter = 120
            } else if (diff norm() < 200.0) {
                if (gtfoCounter == 0) {
                    state = BaddieState GTFO
                } else {
                    state = BaddieState CMON
                }
                gtfoCounter = gtfoCounter - 1
            } else {
                state = BaddieState WTF
                gtfoCounter = 120
            }
        }

        body speed interpolate!(motion normalized() mul(speed), alpha)
        if (body speed x > 3.0) {
            mainSprite scale x = scale
            mainSprite offset x = 0
        } else if(body speed x < -3.0) {
            mainSprite scale x = -scale
            mainSprite offset x = 50
        }

        body update(delta)
    }

}
