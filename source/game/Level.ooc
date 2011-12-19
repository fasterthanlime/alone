use deadlogger

// game deps
import Engine, Camera, Editor
import ui/[Sprite, MainUI]
import Hero, Baddie, Platform, Collision, Vacuum, Decor
    
import math/[Vec2, Vec3, Random]

// libs deps
import structs/ArrayList
import deadlogger/Log

Level: class {

    logger := static Log getLogger("Level")

    engine: Engine
    actors := ArrayList<Actor> new()
    collideables := ArrayList<Collideable> new()
    swarms := ArrayList<Swarm> new()
    platforms := ArrayList<Platform> new()
    vacuums := ArrayList<Vacuum> new()
    decors := ArrayList<Decor> new()

    name := "<untitled>"
    author := "<unknown>"
    backgroundPath := ""

    startPos := vec2(0)

    // different passes
    bgSprites := ArrayList<Sprite> new()
    sprites := ArrayList<Sprite> new()
    fgSprites := ArrayList<Sprite> new()
    debugSprites := ArrayList<Sprite> new()

    camera: Camera
    editor: Editor
    hero: Hero

    init: func (=engine, levelName: String) {
        hero = Hero new(this)
        actors add(hero)

        camera = Camera new(engine ui)
        editor = Editor new(engine ui, this, levelName)
    }

    reset: func {
        // clear temp actors
        iter := actors iterator()
        while (iter hasNext?()) {
            actor := iter next()
            if (!actor permanent?) {
                actor cleanup()
                iter remove()
            }
        }
    
        // set hero to start position and still
        hero body pos set!(startPos)
        hero body speed set!(0, 0)
        hero life = 100
    
        // re-spawn baddies
        swarms each(|swarm|
            this // stupid ooc workaround, tee hee
            swarm population times(||
                baddie := Baddie new(this)

                logger info("Spawning baddie at " + swarm center _)
            
                // this is, like, the ugliest way to generate random
                // points in a circle. Ever.
                randX := Random randInt(-10000000, 10000000)
                randY := Random randInt(-10000000, 10000000)
                v := vec2(randX / 10.0, randY / 10.0) sub(swarm center)
                v = v normalized() mul(Random randInt(0, (swarm radius * 10) as Int) / 10.0)
                baddie body pos set!(v add(swarm center))
                actors add(baddie)
            )
        )
    }

    update: func (delta: Float) {
        if (engine ui mode == UIMode GAME) {
            actors each(|actor|
                actor update(delta)
            )
        }

        swarms each(|swarm| swarm update(delta))
        
        // update those separately, in case
        // we want to clear actors
        camera update(delta)
        editor update(delta)

        engine ui redraw()

        if (hero life <= 0) {
            engine ui mode = UIMode GAME_OVER
        }
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

    _: String {
        get { toString() }
    }

    toString: func -> String {
        "<A %s>" format(class name)
    }

    permanent?: Bool {
        get { isPermanent() }
    }

    isPermanent: func -> Bool {
        true
    }

    cleanup: func { }

}

Swarm: class extends Actor {

    population := 8
    center := vec2(0)
    radius := 100.0

    mainSprite: EllipseSprite

    init: func (=level) {
        mainSprite = EllipseSprite new(vec2(0))
        mainSprite filled = false
        mainSprite color = vec3(1.0, 1.0, 0.3)
        level debugSprites add(mainSprite)
    }

    update: func (delta: Float) {
        mainSprite pos set!(center)
        mainSprite radius = radius
    }

    toString: func -> String {
        "swarm of %d at %s in a radius of %.2f" format(population, center _, radius)
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

