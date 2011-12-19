use deadlogger, cairo, rsvg

// game deps
import math/[Vec2, Vec3]

// libs deps
import deadlogger/Log
import cairo/Cairo
import rsvg
import structs/HashMap

Sprite: class {

    logger := static Log getLogger(This name)
    pos: Vec2
    offset := vec2(0.0, 0.0)
    scale := vec2(1.0, 1.0)
    color := vec3(1.0, 0.0, 0.0)
    alpha := 1.0
    visible := true

    init: func (=pos)
   
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
        if (!visible) return

        cr save()
        cr translate(pos x + offset x, pos y + offset y)
        cr scale(scale x, scale y)
        cr setSourceRGBA(color x, color y, color z, alpha)

        paint(cr)

        cr restore()
    }

    /*
     * This is the function you want to overload
     * when you have custom sprites
     */
    paint: func (cr: Context) {
        cr setLineWidth(3)

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
    thickness := 3.0

    paint: func (cr: Context) {
        halfWidth  := size x * 0.5
        halfHeight := size y * 0.5

        cr setLineWidth(thickness)
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

/**
 * An ellipsoid, initially a 1x1 circle
 */
EllipseSprite: class extends Sprite {

    init: super func

    radius := 15.0
    filled := true
    thickness := 3.0

    paint: func (cr: Context) {
        // full circle!
        cr setLineWidth(thickness)
        cr newSubPath()
        cr arc(0.0, 0.0, radius, 0.0, 3.142 * 2)

        if (filled) {
            cr fill()
        } else {
            cr stroke()
        }
    }

}

/**
 * A label that displays text
 */
LabelSprite: class extends Sprite {

    text: String
    fontSize := 22.0
    family := "Impact"
    centered := false

    init: func (=pos, =text) { }

    paint: func (cr: Context) {
        cr selectFontFace(family, CairoFontSlant NORMAL, CairoFontWeight NORMAL)
        cr setFontSize(fontSize)

        if (centered) {
            extents: TextExtents
            cr textExtents(text, extents&)
            cr translate (-extents width / 2, extents height / 2)
        }
        cr showText(text)
    }

}

PngSprite: class extends Sprite {

    path: String
    tiled := false

    image: ImageSurface
    imageCache := static HashMap<String, ImageSurface> new()

    width  := -1
    height := -1

    init: func (=pos, =path) {
        if(imageCache contains?(path)) {
            image = imageCache get(path)
        } else {
            image = ImageSurface new(path)
            logger debug("Loaded png asset %s (%dx%d)" format(path, image getWidth(), image getHeight()))
            imageCache put(path, image)
        }

        width  = image getWidth()
        height = image getHeight()
    }

    paint: func (cr: Context) {
        paintOnce(cr)
        if (tiled) {
            for (x in -3..3) {
                for (y in -3..3) {
                    cr save()
                    cr translate (x * width, y * height)
                    paintOnce(cr)
                    cr restore()
                }
            }
        }
    }

    paintOnce: func (cr: Context) {
        cr save()
        cr setSourceSurface(image, 0, 0)
        cr rectangle(0, 0, width, height)
        cr clip()
        cr paintWithAlpha(alpha)
        cr restore()
    }

}

CachedSvg: class {

    svg: Svg
    image: ImageSurface

    init: func (=svg, =image)

}

SvgSprite: class extends Sprite {

    path: String
    svg: Svg
    svgCache := static HashMap<String, CachedSvg> new()

    width, height: Int
    overScaling := 1.0

    image: ImageSurface

    init: func (=pos, scaling: Float, =width, =height, =path) {
        if(svgCache contains?(path)) {
            cached := svgCache get(path)
            svg   = cached svg
            image = cached image
        } else {
            logger debug("Loading svg asset %s" format(path))
            svg = Svg new(path)
            cache(scaling)
            svgCache put(path, CachedSvg new(svg, image))
        }
    }
    
    cache: func (scaling: Float) {
        image = ImageSurface new(CairoFormat ARGB32, width * overScaling, height * overScaling)
        cr := Context new(image)
        cr setSourceRGBA(0.0, 0.0, 0.0, 0.0)
        cr scale(scaling, scaling)
        cr paint()
        cr scale(overScaling, overScaling)
        svg render(cr)
        cr destroy()
    }

    paint: func (cr: Context) {
        cr scale(1.0 / overScaling, 1.0 / overScaling)
        cr setSourceSurface(image, 0, 0)
        cr rectangle(0.0, 0.0, width, height)
        cr clip()
        cr paintWithAlpha(alpha)
    }

    free: func {
        // don't free anything, what if there's another
        // reference from the cache?
        // TODO: this leaks.
    }

}

