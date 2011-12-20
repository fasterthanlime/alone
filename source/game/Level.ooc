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
    smokeSources := ArrayList<SmokeSource> new()

    name := "<untitled>"
    author := "<unknown>"

    welcomeMessage := "Good luck soldier!"
    endMessage := "You did it!"
    nextLevel := "<win>"

    backgroundPath := ""

    startPos := vec2(0)
    endPos := vec2(-100000, -100000)

    // different passes
    bgSprites := ArrayList<Sprite> new()
    bgSprite: Sprite
    sprites := ArrayList<Sprite> new()
    fgSprites := ArrayList<Sprite> new()
    debugSprites := ArrayList<Sprite> new()

    totalHitsNumber := 10
    hitsNumber := 0

    camera: Camera
    editor: Editor
    hero: Hero

    haveWon := false
    haveLost := false
    wonCounter := 0

    endSprite: ImageSprite

    init: func (=engine, levelName: String) {
        endSprite = ImageSprite new(endPos clone(), "assets/svg/fusee.svg")
        endSprite offset set!(- endSprite width / 2, - endSprite height / 2)
        sprites add(endSprite)

        hero = Hero new(this)
        actors add(hero)

        camera = Camera new(engine ui)
        editor = Editor new(engine ui, this, levelName)
    }

    reset: func {
        // reset score
        haveWon = false
        haveLost = false
        hitsNumber = 0

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
        hero state = HeroState NORMAL

        // set end position to end position
        endSprite pos set!(endPos)
    
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

        // display friendly message
        engine ui notify(welcomeMessage)    
    }

    update: func (delta: Float) {
        if(bgSprite) {
            parallax := 0.3
            bgSprite pos set!(engine ui translation mul(-parallax))
        }

        if (engine ui mode == UIMode GAME) {
            actors each(|actor|
                actor update(delta)
            )
        }

        swarms each(|swarm| swarm update(delta))
        smokeSources each(|ss| ss update(delta))
        
        // update those separately, in case
        // we want to clear actors
        camera update(delta)
        editor update(delta)

        engine ui redraw()

        if (haveWon) {
            if (wonCounter > 0) {
                wonCounter -= 1
            } else if(wonCounter == 0) {
                wonCounter = -1
                if (nextLevel == "<win>") {
                    engine ui mode = UIMode ULTIMATE_WIN
                } else {
                    engine load(nextLevel)
                }
            }
        } else {
            if (hero life <= 0 && !haveLost) {
                haveLost = true
                engine ui mode = UIMode GAME_OVER
            }

            endDist := hero body pos dist(endPos)
            if (endDist < 120.0) {
                if (hitsNumber < totalHitsNumber) {
                    engine ui notify("Uh oh. The planet still wants to be fed %d baddies." format(totalHitsNumber - hitsNumber), 10)
                } else {
                    // Okay, so from that point on you can pretty much assume
                    // that we're going to wreck the level in ways that only
                    // reset() can repair. Abandon all hope of doing anything
                    // useful with hero beyond this point. Just load another
                    // level. Just do it.
                    wonCounter = 120
                    haveWon = true
                    hero body pos set!(endPos)
                    hero body speed set!(0, 0)
                    hero state = HeroState MR_FAHRENHEIT
                    engine ui notify(endMessage)
                }
            }
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

SmokeSource: class extends Actor {

    center := vec2(0)
    mainSprite: EllipseSprite

    counter := 0

    init: func (=level) {
        mainSprite = EllipseSprite new(vec2(0))
        mainSprite filled = false
        mainSprite color = vec3(1.0, 0.3, 1.0)
        level debugSprites add(mainSprite)
    }

    update: func (delta: Float) {
        mainSprite pos set!(center)

        counter -= 1
        if (counter < 0) {
            s := Smoke new(level, center clone())
            level actors add(s)
            counter = Random randInt(20, 120)
        }
    }

    toString: func -> String {
        "source of smoke at $s" format(center _)
    }

}

Smoke: class extends Actor {

    pos: Vec2
    mainSprite: ImageSprite
    bb: RectSprite

    ttl := Random randInt(60, 120)

    init: func (=level, =pos) {
        mainSprite = ImageSprite new(vec2(0), "assets/svg/greenSmoke.svg")
        mainSprite offset set!(- mainSprite width / 2, - mainSprite height / 2)
        level fgSprites add(mainSprite)

        bb = RectSprite new(vec2(0))
        bb size set!(50, 50)
        level debugSprites add(bb)
    }
    
    update: func (delta: Float) {
        pos y -= 2.2
        ttl -= 1
        mainSprite alpha = (ttl / 100.0)

        if(ttl <= 0) {
            level debugSprites remove(bb)
            level fgSprites remove(mainSprite)
            level actors remove(this)
        }
        mainSprite pos set!(pos)
        bb pos set!(pos)

        if (level hero body pos dist(pos) < 50) {
            level hero life -= 1
            level hero bloody = true
        }
    }

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

