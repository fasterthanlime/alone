use deadlogger

// game deps
import Engine
import ui/[Sprite, MainUI]
    
import math/[Vec2, Vec3]

// libs deps
import gtk/Gtk // for timeouts
import structs/ArrayList
import deadlogger/Log

/**
 * Where we are eventually going to have level loading stuff,
 * probably all hardcoded for a start though
 */
Level: class {

    logger := static Log getLogger(This name)
    FPS := 30.0 // let's target 30FPS

    engine: Engine
    actors := ArrayList<Actor> new()

    init: func (=engine) {
        logger debug("Loading level...")

        // add a bunch of stuff
        actors add(Hero new(this))
        actors add(Ground new(this))
        
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

}

Actor: class {

    level: Level

    init: func (=level)

    update: func (delta: Float)

}

Ground: class extends Actor {

    init: func (=level) {
        engine := level engine

        ground := RectSprite new(vec2(engine ui width * 0.5, engine ui height - 100))
        ground size = vec2(engine ui width, 20)
        ground color = vec3(0.0, 0.0, 0.0)
        engine ui sprites add(ground)
    }

}


GravityObject: class extends Actor {

    pos := vec2(0, 0)
    speed := vec2(0, 0)

    gravity := 0.3

    init: func (=level) {}

    update: func (delta: Float) {
        // update speed
        (speed y += gravity)

        // update position
        (pos x, pos y) = (pos x + speed x * delta, pos y + speed y * delta)
    }

}


Hero: class extends Actor {

    ui: MainUI
    logger := static Log getLogger(This name)
    svgSprite : Sprite
    speed := 5.0
    scale := 0.3

    body: GravityObject
    direction := 1.0 // 1 = right, -1 = left

    init: func (=level) {
        ui = level engine ui

        body = GravityObject new(level)
        body pos = vec2(100, ui height - 300)

        svgSprite = SvgSprite new(body pos, "assets/svg/movingObj_Full.svg")
        svgSprite scale = vec2(scale, scale)
        ui sprites add(svgSprite)
    }

    update: func (delta: Float) {
        if (ui isPressed(Keys LEFT)) {
            body speed x = -speed
            svgSprite scale = vec2(scale, scale)
            direction = -1.0
        } else if (ui isPressed(Keys RIGHT)) {
            body speed x = speed
            svgSprite scale = vec2(-scale, scale)
            direction = 1.0
        } else {
            body speed x = 0
        }

        body update(delta)
    }

}






