use deadlogger

// game deps
import Engine, Camera, Editor
import ui/[Sprite, MainUI]
import Hero, Baddie, Platform, Collision
    
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

    camera: Camera

    editor: Editor

    hero: Hero

    init: func (=engine) {
        hero = Hero new(this, engine ui height - 40)
        actors add(hero)

        camera = Camera new(engine ui)
        editor = Editor new(engine ui, this)
    }

    update: func (delta: Float) {
        if (engine ui mode == UIMode GAME) {
            actors each(|actor|
                actor update(delta)
            )
        }
        
        // update those separately, in case
        // we want to clear actors
        camera update(delta)
        editor update(delta)

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

