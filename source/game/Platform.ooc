
// game deps
import ui/[Sprite, MainUI]
import Engine, Level, Hero, Collision

import math/[Vec2, Vec3, Random]

Platform: class extends Actor {

    bb: RectSprite
    mainSprite: Sprite
    box: Box

    pos: Vec2
    kind: String

    width  := 150
    height := 40

    init: func (=level, =pos, =kind) {
        bb = RectSprite new(pos)
        bb filled = false
        bb size = vec2(150, 40)
        bb color = vec3(1.0, 0.0, 1.0)
        // level sprites add(bb)

        mainSprite = PngSprite new(pos, "assets/png/platforms/%s.png" format(kind))
        mainSprite scale = vec2(0.51, 0.51)
        mainSprite offset = vec2(-width / 2, -height / 2)
        level sprites add(mainSprite)

        box = Box new(bb)
        level collideables add(box)
    }

    update: func (delta: Float) {
        bb pos = pos
        mainSprite pos = pos
    }
}
