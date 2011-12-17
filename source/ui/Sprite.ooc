use deadlogger, cairo, rsvg

// game deps
import math/[Vec2, Vec3]

// libs deps
import deadlogger/Log
import cairo/Cairo
import rsvg

Sprite: class {

    logger := static Log getLogger(This name)
    pos: Vec2
    offset := vec2(0.0, 0.0)
    scale := vec2(1.0, 1.0)
    color := vec3(1.0, 0.0, 0.0)

    init: func (=pos) {
        logger debug("Created %s at %s" format(class name, pos _))
    }
   
    /*
     * This is where you have to draw the line between
     * good software construction and pragmatic software
     * construction. You see, if I was still 15, I would
     * have probably started to abstract away Cairo so
     * we can have several graphical backends and shit.
     * Since I'm now 21 and the deadline is in 1 day 12
     * hours 24 minutes and 3 seconds, I'll just embrace
     * the shit out of Cairo and have dependant code.
     * Hellzyeah.
     */
    draw: func (cr: Context) {
        cr save()
        cr translate(pos x + offset x, pos y + offset y)
        cr scale(scale x, scale y)

        paint(cr)

        cr restore()
    }

    /*
     * This is the function you want to overload
     * when you have custom sprites
     */
    paint: func (cr: Context) {
        cr setLineWidth(3)

        cr setSourceRGB(color x, color y, color z)
        cr moveTo(0, 0)
        cr lineTo(0, 50)
        cr relLineTo(50, 0)
        cr closePath()
        cr stroke()

    }

    free: func {
        // in theory, release resources
        // in practice, nothing to do in the base class
    }

}

/**
 * A rectangle, initially a 1x1 square
 */
RectSprite: class extends Sprite {

    init: super func

    size := vec2(1.0, 1.0)
    filled := true

    paint: func (cr: Context) {
        halfWidth  := size x * 0.5
        halfHeight := size y * 0.5

        cr setSourceRGB(color x, color y, color z)
        cr moveTo(-halfWidth, -halfHeight)
        cr lineTo( halfWidth, -halfHeight)
        cr lineTo( halfWidth,  halfHeight)
        cr lineTo(-halfWidth,  halfHeight)
        cr closePath()
        if (filled) {
            cr fill()
        } else {
            cr stroke()
        }
    }

}

SvgSprite: class extends Sprite {

    path: String
    svg: Svg

    // let's hope none of them will be larger than this
    width  := 1024
    height := 1024
    overScaling := 2.0

    cache: ImageSurface

    init: func (=pos, =path) {
        logger debug("Loading svg asset %s" format(path))

        svg = Svg new(path)
        cache = ImageSurface new(CairoFormat ARGB32, width, height)

        // cache one first time
        cache()
    }
    
    cache: func {
        cr := Context new(cache)
        cr setSourceRGBA(0.0, 0.0, 0.0, 0.0)
        cr paint()
        cr scale(overScaling, overScaling)
        svg render(cr)
        cr destroy()
    }

    paint: func (cr: Context) {
        cr setAntialias(CairoAntialias SUBPIXEL)
        cr scale(1.0 / overScaling, 1.0 / overScaling)
        cr setSourceSurface(cache, 0, 0)
        cr rectangle(0.0, 0.0, width, height)
        cr clip()
        cr paint()
    }

    free: func {
        // here we have resources to free
        svg free()
    }

}

