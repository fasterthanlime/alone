use deadlogger

// game deps
import Engine
import ui/[Sprite, MainUI]
    
import math/Vec2

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
        actors add(Hero new(this))
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

Hero: class extends Actor {

    logger := static Log getLogger(This name)
    svgSprite : Sprite
    speed := 1.0

    init: func (=level) {
        svgSprite = SvgSprite new(vec2(100, 100), "assets/svg/movingObj_Full.svg", "Layer_1")
        level engine ui sprites add(svgSprite)
    }

    update: func (delta: Float) {
        logger debug("Updating hero with delta %.2f" format(delta))
        svgSprite pos x += delta * speed
    }

}
