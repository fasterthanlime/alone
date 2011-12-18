
use deadlogger

// game deps
import ui/[Sprite, MainUI]
import Engine, Level
import Hero, Baddie
    
import math/[Vec2, Vec3, Random]

// libs deps
import structs/[ArrayList, HashBag, Bag]
import deadlogger/Log
import text/json, text/json/Parser
import io/FileReader

LevelLoader: class {

    logger := static Log getLogger(This name)
    engine: Engine

    init: func (=engine)

    load: func (path: String) -> Level {
        logger debug("Loading json %s!" format(path))
        json := JSON parse(FileReader new(path), HashBag)

        level := Level new(engine)
        level name   = json get("name",   String)
        level author = json get("author", String)

        logger debug("Level '%s', by '%s'" format(level name, level author))

        objects := json get("objects", Bag)
        for(i in 0..objects size) {
            object := objects get(i, HashBag)
            type := object get("type", String)
            logger debug("Got an object of type '%s'" format(type))

            match type {
                case "background" =>
                    bg := PngSprite new(vec2(0, 0), object get("path", String))
                    bg tiled = true
                    level bgSprites add(bg)
                case "hero" =>
                    level hero body pos = readVec2(object, "pos")
                    logger info("Hero starting at position %s" format(level hero body pos _))
                case "swarm" =>
                    object get("population", Int) times(||
                        baddie := Baddie new(level)
                        level actors add(baddie)
                    )
            }
        }

        level
    }

    readVec2: func (hb: HashBag, key: String) -> Vec2 {
        bag := hb get(key, Bag)
        x := bag get(0, Number) value toFloat()
        y := bag get(1, Number) value toFloat()
        vec2(x, y)
    }

}
