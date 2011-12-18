
use deadlogger

// game deps
import ui/[Sprite, MainUI]
import Engine, Level
import Hero, Baddie
    
import math/[Vec2, Vec3, Random]

// libs deps
import structs/[ArrayList, HashBag]
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

        logger debug("Loaded level %s, by %s!" format(level name, level author))

        level
    }

}
