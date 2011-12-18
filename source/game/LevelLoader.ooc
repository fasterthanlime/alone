
use deadlogger

// game deps
import ui/[Sprite, MainUI]
import Engine, Level
import Hero, Baddie
    
import math/[Vec2, Vec3, Random]

// libs deps
import structs/[ArrayList, HashBag, Bag]
import deadlogger/Log
import text/json
import io/FileReader

LevelLoader: class {

    logger := static Log getLogger("LevelLoader")
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
        }

        level
    }

}
