use deadlogger

// game deps
import Engine
import ui/[Sprite, MainUI]
    
import math/Vec2

// libs deps
import structs/ArrayList
import deadlogger/Log

/**
 * Where we are eventually going to have level loading stuff,
 * probably all hardcoded for a start though
 */
Level: class {

    logger := static Log getLogger(This name)

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
    }

    start: func {
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

    init: func (=level) {
        level engine ui sprites add(SvgSprite new(vec2(100, 100), "assets/svg/lameTest1.svg"))
        level engine ui sprites add(Sprite new(vec2(200, 100)))
    }

    update: func (delta: Float) {
        logger debug("Updating hero with delta %.2f" format(delta))
    }

}
