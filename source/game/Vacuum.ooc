
// game deps
import ui/[Sprite, MainUI]
import Engine, Level, Hero, Collision

import math/[Vec2, Vec3, Random]

Vacuum: class extends Actor {

    bb: RectSprite
    mainSprite: RotatedSprite
    box: Box

    pos: Vec2
    angle := 0.0

    init: func (=level, =pos, =angle) {
        svgSprite := SvgSprite new(pos, "assets/svg/Vacuum.svg")
        svgSprite offset = vec2(-svgSprite width / 2, -svgSprite height / 2)
        mainSprite = RotatedSprite new(svgSprite)
        mainSprite angle = angle
        level sprites add(mainSprite)

        // bb = RectSprite new(pos)
        // bb filled = false
        // bb size = vec2(mainSprite width, mainSprite height)
        // bb color = vec3(1.0, 0.0, 1.0)
        // level debugSprites add(bb)

        // box = Box new(bb)
        // level collideables add(box)
    }

    update: func (delta: Float) {
        bb pos = pos
        mainSprite pos = pos
    }
}

