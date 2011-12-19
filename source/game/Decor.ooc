
// game deps
import ui/[Sprite, MainUI]
import Engine, Level, Hero, Collision

import math/[Vec2, Vec3, Random]

Decor: class extends Actor {

    mainSprite: Sprite

    pos: Vec2
    scale := 1.0
    path: String

    init: func (=level, =path, =pos, =scale) {
        mainSprite = SvgSprite new(pos, path)
        mainSprite scale set!(scale, scale)

        level bgSprites add(mainSprite)
    }

    update: func (delta: Float) {
        mainSprite pos = pos
        mainSprite scale set!(scale, scale)
    }
}

