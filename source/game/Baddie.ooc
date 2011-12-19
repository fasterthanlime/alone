
// game deps
import ui/[Sprite, MainUI]
import Engine, Level, Hero, Collision, Vacuum

import math/[Vec2, Vec3, Random]

abs: func (d: Double) -> Double {
    if (d < 0.0) return -d
    d
}

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

    scale := 0.7

    state := BaddieState CMON
    attractor: Vacuum

    gtfoCounter := -1

    dead := false

    init: func (=level) {
        hero = level hero
        ui = level engine ui

        body = Body new(level)
        body gravity = 0.0

        mainSprite = SvgSprite new(body pos, 0.1, "assets/svg/baddies/baddie2_Full.svg")
        mainSprite scale = vec2(scale, scale)
        mainSprite offset = vec2(-70, -50)
        level fgSprites add(mainSprite)

        bb = RectSprite new(body pos)
        bb size = vec2(70, 70)
        //level fgSprites add(bb)
        box = Box new(bb)
        box actor = this
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

    die: func {
        dead = true
        cleanup()
        level actors remove(this)
    }

    update: func (delta: Float) {
        if (dead) return

        diff := hero body pos sub(body pos)
        motion := diff
        alpha := 0.2

        vacuumDeath := 15.0
        vacuumInfluence := 300.0

        // attempt to find close vacuums
        changed := false
        level vacuums each(|vacuum|
            diff := vacuum pos sub(body pos)
            dist := diff norm()

            if (dist < vacuumDeath) {
                die()
            }

            if (dist < vacuumInfluence) {
                a1 := diff angle()
                a2 := vacuum angle

                if (abs(a1 - a2) < 2.0) {
                    changed = true
                    state = BaddieState DUI
                    attractor = vacuum
                    targetAlpha := dist / vacuumInfluence
                    if (mainSprite alpha > targetAlpha) {
                        mainSprite alpha = targetAlpha
                    }
                }
            }
        )

        match (state) {
            case BaddieState DUI =>
                motion = attractor pos sub(body pos)
            case BaddieState CMON =>
                motion = diff mul(3.0)
            case BaddieState GTFO =>
                alpha = 0.1
                motion = diff mul(-1)
            case BaddieState WTF =>
                motion = vec2(Random randInt(-200, 200), Random randInt(-200, 200))
        }

        if (!changed) {
            mainSprite alpha = 1.0
            if (hero body speed norm() > 2.0) {
                state = BaddieState CMON 
                level collides?(box, |bang|
                    state = BaddieState WTF
                    motion = bang dir mul(bang depth)
                )
                gtfoCounter = 120
            } else if (diff norm() < 200.0) {
                if (gtfoCounter == 0) {
                    state = BaddieState GTFO
                } else {
                    state = BaddieState CMON
                    gtfoCounter = gtfoCounter - 1
                }
            } else {
                state = BaddieState WTF
                gtfoCounter = 120
            }
        }

        body speed interpolate!(motion normalized() mul(speed), alpha)
        if (body speed x > 3.0) {
            mainSprite scale x = scale
            mainSprite offset x = -60
        } else if(body speed x < -3.0) {
            mainSprite scale x = -scale
            mainSprite offset x = 60
        }

        body update(delta)
    }

}
