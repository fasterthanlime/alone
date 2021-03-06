use deadlogger 
// game deps
import ui/[Sprite, MainUI]
import Engine, Level
import Hero, Baddie, Platform, Vacuum, Decor
    
import math/[Vec2, Vec3, Random]

// libs deps
import structs/[ArrayList, HashBag, Bag]
import deadlogger/Log
import text/json, text/json/[Parser, Generator, DSL] // Parser for Number
import io/File

LevelSaver: class {

    logger := static Log getLogger(This name)

    init: func () {}

    save: func (level: Level, levelName: String) {
        path := "assets/levels/%s.json" format(levelName)

        logger debug("Saving json %s!" format(path))

        result := DSL new() json(|make|
            make object(
                "name", level name,
                "author", level author,
                "welcomeMessage", level welcomeMessage,
                "endMessage", level endMessage,
                "nextLevel", level nextLevel,
                "totalHits", level totalHitsNumber,
                "endPos", toArray(level endPos),
                "objects", objects(make, level)
            )
        )

        File new(path) write(result)
    }

    objects: func (make: DSL, level: Level) -> Bag {
        bag := Bag new()
        bag add(make object(
            "type", "background",
            "path", level backgroundPath
        ))

        bag add(make object(
            "type", "hero",
            "pos", toArray(level startPos)
        ))

        level swarms each(|swarm|
            bag add(make object(
                "type", "swarm",
                "population", intToNumber(swarm population),
                "radius", floatToNumber(swarm radius),
                "center", toArray(swarm center)
            ))
        )

        level vacuums each(|vacuum|
            bag add(make object(
                "type", "vacuum",
                "pos", toArray(vacuum pos),
                "angle", floatToNumber(vacuum angle)
            ))
        )

        level platforms each(|p|
            bag add(make object(
                "type", "platform",
                "pos", toArray(p pos),
                "kind", p kind
            ))
        )

        level decors each(|d|
            bag add(make object(
                "type", "decor",
                "pos", toArray(d pos),
                "scale", floatToNumber(d scale),
                "path", d path
            ))
        )

        level smokeSources each(|s|
            bag add(make object(
                "type", "smokeSource",
                "center", toArray(s center)
            ))
        )

        level deathSpots each(|s|
            bag add(make object(
                "type", "deathSpot",
                "center", toArray(s center)
            ))
        )

        bag
    }

    floatToNumber: func (f: Float) -> Number {
        Number new(f toString())
    }

    intToNumber: func (i: Int) -> Number {
        Number new(i toString())
    }

    toArray: func (v: Vec2) -> Bag {
        bag := Bag new()
        bag add(floatToNumber(v x))
        bag add(floatToNumber(v y))
        bag
    }
}


