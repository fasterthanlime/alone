use deadlogger, cairo, rsvg

// game deps
import math/[Vec2, Vec3]

// libs deps
import deadlogger/Log
import cairo/Cairo
import rsvg
import structs/[HashMap, ArrayList]

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

GroupSprite: class extends Sprite {

    children := ArrayList<Sprite> new()

    init: func {
        super(vec2(0, 0))
    }

    draw: func (cr: Context) {
        if (!visible) return

        children each(|child| child draw(cr))
    }

    add: func (s: Sprite) {
        children add(s)
    }

}

RotatedSprite: class extends Sprite {

    sub: Sprite
    angle := 0.0
    
    init: func (=sub) {
        super(vec2(0))     
    }

    draw: func (cr: Context) {
        if (!visible) return

        cr save()
        cr translate(pos x, pos y)
        cr rotate(angle)
        cr translate(offset x, offset y)
        cr scale(scale x, scale y)
        cr setSourceRGBA(color x, color y, color z, alpha)

        sub paint(cr)

        cr restore()
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

    radius := 15.0
    filled := true
    thickness := 3.0

    init: func (=pos) {}

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

LineSprite: class extends Sprite {

    start := vec2(0)
    end   := vec2(200)
    thickness := 3.0

    init: func {
        super(vec2(0))
    }

    paint: func (cr: Context) {
        cr setLineWidth(thickness)
        cr moveTo(start x, start y)
        cr lineTo(end x, end y)
        cr closePath()
        cr stroke()
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
        cr newSubPath()
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

ImageSprite: class extends Sprite {

    tiled := false

    width  := -1
    height := -1

    path: String

    init: func ~ohshutuprock {}

    new: static func (pos: Vec2, path: String) -> This {
        low := path toLower()
        if (low endsWith?(".png")) {
            PngSprite new(pos, path)
        } else if (low endsWith?(".svg")) {
            SvgSprite new(pos, 1.0, path)
        } else {
            Exception new("Unknown image type (neither PNG nor SVG): %s" format(path)) throw()
            null
        }
    }

    paint: func (cr: Context) {
        if (tiled) {
            for (x in -3..3) {
                for (y in -3..3) {
                    cr save()
                    cr translate (x * (width - 1), y * (height - 1))
                    paintOnce(cr)
                    cr restore()
                }
            }
        } else {
            cr save()
            paintOnce(cr)
            cr restore()
        }
    }

    paintOnce: func (cr: Context) {
        cr setSourceRGB(1.0, 0.0, 0.0)
        cr setFontSize(80)
        cr showText("MISSING IMAGE %s" format(path))
    }

}

PngSprite: class extends ImageSprite {

    image: ImageSurface
    imageCache := static HashMap<String, ImageSurface> new()

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

    paintOnce: func (cr: Context) {
        cr setSourceSurface(image, 0, 0)
        cr rectangle(0, 0, width, height)
        cr clip()
        if (alpha == 1.0) {
            cr paint()
        } else {
            cr paintWithAlpha(alpha)
        }
    }

}

CachedSvg: class {

    svg: Svg
    image: ImageSurface

    imgWidth, imgHeight: Int
    width, height: Int

    init: func (=svg) {
        width  = svg getWidth()
        height = svg getHeight()
    }

}

SvgSprite: class extends ImageSprite {

    svg: Svg
    svgCache := static HashMap<String, CachedSvg> new()

    cached: CachedSvg
    scaling: Float

    init: func (=pos, =scaling, =path) {
        if(svgCache contains?(path)) {
            cached = svgCache get(path)
        } else {
            svg = Svg new(path)
            cached = CachedSvg new(svg)
            cache(scaling)
            logger debug("Loaded svg asset %s (size %dx%d)" format(path, cached width, cached height))

            svgCache put(path, cached)
        }

        width  = cached width
        height = cached height
    }
    
    cache: func (scaling: Float) {
        cached image = ImageSurface new(CairoFormat ARGB32, cached width * scaling, cached height * scaling)
        cr := Context new(cached image)
        cr scale(scaling, scaling)
        svg render(cr)
        cr destroy()
    }

    paintOnce: func (cr: Context) {
        cr setSourceSurface(cached image, 0, 0)
        cr rectangle(0.0, 0.0, width * scaling, height * scaling)
        cr clip()

        if (alpha == 1.0) {
            cr paint()
        } else {
            cr paintWithAlpha(alpha)
        }
    }

    free: func {
        // don't free anything, what if there's another
        // reference from the cache?
        // TODO: this leaks.
    }

}

