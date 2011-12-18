
// libs deps
import math

/**
 * A 2-dimensional vector class with a few
 * utility things.
 *
 * I've never been good at math
 */
Vec2: class {

    x, y: Float

    init: func (=x, =y)

    norm: func -> Float {
        sqrt(squaredNorm())
    }

    squaredNorm: func -> Float {
        x * x + y * y
    }

    normalized: func -> This {
        mul(1.0 / norm())
    }

    mul: func (f: Float) -> This {
        new(x * f, y * f)
    }

    set!: func (v: This) {
        x = v x
        y = v y
    }

    set!: func ~twofloats (px, py: Float) {
        x = px
        y = py
    }

    sub: func (v: This) -> This {
        new(x - v x, y - v y)
    }

    add: func (v: This) -> This {
        new(x + v x, y + v y)
    }

    add!: func (v: This) {
        x += v x
        y += v y
    }

    perp: func -> This {
        new(y, -x)
    }
   
    project!: func (v: This) {
        v = v normalized()
        d := dot(v)
        (x, y) = (v x * d, v y * d)
    }

    dot: func (v: This) -> Float {
        x * v x + y * v y
    }

    interpolate!: func (target: This, alpha: Float) {
        (x, y) = (x * (1 - alpha) + target x * alpha,
                  y * (1 - alpha) + target y * alpha)
    }

    interpolateX!: func (target: Float, alpha: Float) {
        x = x * (1 - alpha) + target * alpha
    }

    isubnterpolateY!: func (target: Float, alpha: Float) {
        y = y * (1 - alpha) + target * alpha
    }
    toString: func -> String {
        "(%.2f, %.2f)" format(x, y)
    }

    _: String { get { toString() } }

}

// cuz I'm lazy
vec2: func (x, y: Float) -> Vec2 { Vec2 new(x, y) }
vec2: func ~square (xy: Float) -> Vec2 { Vec2 new(xy, xy) }
vec: func ~two (x, y: Float) -> Vec2 { Vec2 new(x, y) }

