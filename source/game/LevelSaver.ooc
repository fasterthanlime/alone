
use deadlogger

// game deps
import ui/[Sprite, MainUI]
import Engine, Level
import Hero, Baddie, Platform
    
import math/[Vec2, Vec3, Random]

// libs deps
import structs/[ArrayList, HashBag, Bag]
import deadlogger/Log
import text/json, text/json/[Parser, Generator, DSL] // Parser for Number
import io/FileWriter

LevelSaver: class {

    logger := static Log getLogger(This name)

    init: func () {}

    save: func (level: Level, path: String) {
        logger debug("Saving json %s!" format(path))

        result := DSL new() json(|make|
            make object(
                "name", level name,
                "author", level author,
                "objects", objects(make, level)
            )
        )
        logger debug("Generated json:")
        result println()
    }

    objects: func (make: DSL, level: Level) -> Bag {
        bag := Bag new()
        bag add(make object(
            "type", "background",
            "path", level backgroundPath
        ))

        level swarms each(|swarm|
            bag add(make object(
                "population", toNumber(swarm population),
                "radius", toNumber(swarm radius),
                "center", toArray(swarm center)
            ))
        )
        bag
    }

    toNumber: func ~float (f: Float) -> Number {
        Number new(f toString())
    }

    toNumber: func ~int (i: Int) -> Number {
        Number new(i toString())
    }

    toArray: func (v: Vec2) -> Bag {
        bag := Bag new()
        bag add(toNumber(v x))
        bag add(toNumber(v y))
        bag
    }
}


