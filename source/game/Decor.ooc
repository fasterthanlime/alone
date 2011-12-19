
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

    changeSprite: func (=path) {
        level bgSprites remove(mainSprite)
        mainSprite = SvgSprite new(pos, path)
        level bgSprites add(mainSprite)
        update(1.0)
    }

    update: func (delta: Float) {
        mainSprite pos set!(pos)
        mainSprite scale set!(scale, scale)
    }
}

