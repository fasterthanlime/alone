use deadlogger

// game deps
import Engine
import ui/[Sprite, MainUI]
import Hero, Baddie
    
import math/[Vec2, Vec3, Random]

// libs deps
import gtk/Gtk // for timeouts
import structs/ArrayList
import deadlogger/Log


Level: class {

    logger := static Log getLogger("Level")
    FPS := 30.0 // let's target 30FPS

    engine: Engine
    actors := ArrayList<Actor> new()
    collideables := ArrayList<Collideable> new()

    name := "<untitled>"
    author := "<unknown>"

    // different passes
    bgSprites := ArrayList<Sprite> new()
    sprites := ArrayList<Sprite> new()
    fgSprites := ArrayList<Sprite> new()
    debugSprites := ArrayList<Sprite> new()

    hero: Hero

    init: func (=engine) {
        hero = Hero new(this, engine ui height - 40)
        actors add(hero)
    }

    update: func (delta: Float) {
        actors each(|actor|
            actor update(delta)
        )
        engine ui redraw()
    }

    start: func {
        // doing a fixed delta for now
        delta := 1000.0 / FPS
        Gtk addTimeout(delta, ||
            update(delta / delta)
            true // so the callback gets ran again
        )
        engine ui run()
    }

    bind2: func (src, dst: Vec2) {
        actors add(Binder2 new(this, src, dst))
    }

    bind3: func (src, dst: Vec3) {
        actors add(Binder3 new(this, src, dst))
    }

    collides?: func (c: Collideable, onCollision: Func (Bang)) {
        for (c2 in collideables) {
            if (c == c2) continue
            b := c test(c2)
            if (b) onCollision(b)
        }
    }

}

Actor: class {

    level: Level

    init: func (=level)

    update: func (delta: Float)

}

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

        if (x1 > x2 && minx1 < maxx2) {
            b := Bang new()
            return b
        }

        if (x1 < x2 && maxx1 > minx2) {
            b := Bang new()
            return b
        }

        // TODO: other cases, duh :)

        null
    }
}


Body: class extends Actor {

    pos := vec2(0, 0)
    speed := vec2(0, 0)

    gravity := 2.2

    init: func (=level) {}

    update: func (delta: Float) {
        // update speed
        (speed y += gravity)

        // update position
        (pos x, pos y) = (pos x + speed x * delta, pos y + speed y * delta)
    }

}

Binder2: class extends Actor {

    src, dst: Vec2

    init: func (=level, =src, =dst) { }

    update: func (delta: Float) {
        dst x = src x
        dst y = src y
    }

}

Binder3: class extends Actor {

    src, dst: Vec3

    init: func (=level, =src, =dst) { }

    update: func (delta: Float) {
        dst x = src x
        dst y = src y
        dst z = src z
    }

}

