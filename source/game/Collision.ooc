
// game deps
import math/[Vec2, Vec3]
import ui/Sprite

Bang: class {

    pos := vec2(0, 0)
    dir := vec2(0, 1) // unit vector
    depth := 0.0 // might be negative

}

Collideable: class {

    test: func (c: Collideable) -> Bang {
        null
    }

}

Box: class extends Collideable {

    rect: RectSprite

    init: func (=rect) { }

    test: func (c: Collideable) -> Bang {
        match (c) {
            case b: Box => testRect(b rect)
            case => null
        }
    }

    testRect: func (rect2: RectSprite) -> Bang {
        rect1 := rect

        x1 := rect1 pos x
        y1 := rect1 pos y
        minx1 := x1 - rect1 size x / 2
        maxx1 := x1 + rect1 size x / 2
        miny1 := y1 - rect1 size y / 2
        maxy1 := y1 + rect1 size y / 2

        x2 := rect2 pos x
        y2 := rect2 pos y
        minx2 := x2 - rect2 size x / 2
        maxx2 := x2 + rect2 size x / 2
        miny2 := y2 - rect2 size y / 2
        maxy2 := y2 + rect2 size y / 2

        if (y1 < y2 && maxy1 > miny2) {
            if ((minx1 > minx2 && minx1 < maxx2) ||
                (maxx1 > minx2 && maxx1 < maxx2) ||
                (minx2 > minx1 && minx2 < maxx1) ||
                (maxx2 > minx1 && maxx2 < maxx1)) {
                b := Bang new()
                b depth = maxy1 - miny2
                (b dir x, b dir y) = (0, -1)
                return b
            }
        }

        // TODO: other cases, duh :)

        null
    }
}
