
// game deps
import math/[Vec2, Vec3]
import ui/Sprite
import Level

Bang: class {

    pos := vec2(0, 0)
    dir := vec2(0, 1) // unit vector
    depth := 0.0 // might be negative
    other: Collideable

}

Collideable: class {

    actor: Actor

    test: func (c: Collideable) -> Bang {
        null
    }

}

Box: class extends Collideable {

    rect: RectSprite

    init: func (=rect) { }

    test: func (c: Collideable) -> Bang {
        match (c) {
            case b: Box =>
                bang := testRect(b rect)
                if(bang) bang other = c
                bang
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

        // rule out quick cases first
        if (maxx1 < minx2) return null
        if (maxx2 < minx1) return null
        if (maxy1 < miny2) return null
        if (maxy2 < miny1) return null
    
        bangs := false
        b := Bang new()
        b depth = 10000000000.0

    
        if (x1 < x2 && maxx1 > minx2) {
            depth := maxx1 - minx2
            if (depth < b depth) {
                bangs = true
                b depth = depth
                (b dir x, b dir y) = ( 1,  0)
            }
        }

        if (x2 < x1 && maxx2 > minx1) {
            depth := maxx2 - minx1
            if (depth < b depth) {
                bangs = true
                b depth = depth
                (b dir x, b dir y) = (-1,  0)
            }
        }
    
        if (y1 < y2 && maxy1 > miny2) {
            depth := maxy1 - miny2
            if (depth < b depth) {
                bangs = true
                b depth = depth
                (b dir x, b dir y) = ( 0, -1)
            }
        }

        if (y2 < y1 && maxy2 > miny1) {
            depth := maxy2 - miny1
            if (depth < b depth) {
                bangs = true
                b depth = depth
                (b dir x, b dir y) = ( 0,  1)
            }
        }

        bangs ? b : null
    }
}
