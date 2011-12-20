
use deadlogger

// game deps
import ui/[Sprite, MainUI]
import Engine, Level
import Hero, Baddie, Platform, Vacuum, Decor
    
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

    load: func (levelName: String) -> Level {
        path := "assets/levels/%s.json" format(levelName)

        logger debug("Loading json %s!" format(path))
        json := JSON parse(FileReader new(path), HashBag)

        level := Level new(engine, levelName)
        level name   = json get("name",   String)
        level author = json get("author", String)

        if(json contains?("welcomeMessage")) {
            level welcomeMessage = json get("welcomeMessage", String)
        }

        if(json contains?("endMessage")) {
            level endMessage = json get("endMessage", String)
        }

        if(json contains?("nextLevel")) {
            level nextLevel = json get("nextLevel", String)
        }

        if(json contains?("totalHits")) {
            level totalHitsNumber = json get("totalHits", Int)
        }
        if(json contains?("endPos")) {
            level endPos set!(readVec2(json, "endPos"))
        }

        logger debug("Level '%s', by '%s'" format(level name, level author))

        objects := json get("objects", Bag)
        for(i in 0..objects size) {
            object := objects get(i, HashBag)
            type := object get("type", String)

            match type {
                case "background" =>
                    path := object get("path", String)
                    level backgroundPath = path
                    bg := ImageSprite new(vec2(0), path)
                    bg tiled = true
                    level bgSprites add(bg)
                    level bgSprite = bg
                case "hero" =>
                    level startPos = readVec2(object, "pos")
                    logger info("Hero starting at position %s" format(level startPos _))
                case "swarm" =>
                    swarm := Swarm new(level)
                    swarm population = object get("population", Int)
                    swarm center = readVec2(object, "center")
                    swarm radius = readFloat(object, "radius")
                    logger info("Got " + swarm _)
                    level swarms add(swarm)
                case "platform" =>
                    pos := readVec2(object, "pos")
                    kind := object get("kind", String)
                    platform := Platform new(level, pos, kind)
                    level platforms add(platform)
                case "vacuum" =>
                    pos := readVec2(object, "pos")
                    angle := readFloat(object, "angle")
                    logger info("Got vacuum at %s" format(pos _))
                    vacuum := Vacuum new(level, pos, angle)
                    level vacuums add(vacuum)
                case "decor" =>
                    path := object get("path", String)
                    pos := readVec2(object, "pos")
                    scale := readFloat(object, "scale")
                    decor := Decor new(level, path, pos, scale)
                    decor update(1.0)
                    level decors add(decor)
            }
        }

        level reset()
        level
    }

    readVec2: func (hb: HashBag, key: String) -> Vec2 {
        bag := hb get(key, Bag)
        x := bag get(0, Number) value toFloat()
        y := bag get(1, Number) value toFloat()
        vec2(x, y)
    }

    readFloat: func (hb: HashBag, key: String) -> Float {
        hb get(key, Number) value toFloat()
    }

}
