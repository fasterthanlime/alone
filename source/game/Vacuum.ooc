
// game deps
import ui/[Sprite, MainUI]
import Engine, Level, Hero, Collision, Editor

import math/[Vec2, Vec3, Random]

Vacuum: class extends Actor {

    bb: RectSprite
    mainSprite: RotatedSprite
    box: Box

    pos: Vec2
    angle := 0.0

    init: func (=level, =pos, =angle) {
        svgSprite := SvgSprite new(vec2(0), "assets/svg/Vacuum.svg")
        mainSprite = RotatedSprite new(svgSprite)
        mainSprite pos = pos
        mainSprite angle = angle
        mainSprite offset = vec2(-svgSprite width / 2, -svgSprite height / 2)

        level debugSprites add(mainSprite)
    }

    update: func (delta: Float) {
        // bb pos = pos
        mainSprite pos = pos
        mainSprite angle = angle
    }
}

