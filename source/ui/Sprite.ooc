use deadlogger, cairo

// game deps
import math/Vec2

// libs deps
import deadlogger/Log
import cairo/Cairo

Sprite: class {

    logger := static Log getLogger(This name)
    pos: Vec2

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
        cr translate(pos x, pos y)

        paint(cr)

        cr restore()
    }

    /*
     * This is the function you want to overload
     * when you have custom sprites
     */
    paint: func (cr: Context) {
        cr setLineWidth(3)
        cr setSourceRGB(255, 0, 0)

        cr moveTo(0, 0)
        cr lineTo(0, 50)
        cr relLineTo(50, 0)
        cr closePath()
        cr stroke()

    }

}

