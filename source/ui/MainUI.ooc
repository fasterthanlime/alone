use cairo, gtk

// game deps

// libs deps
import cairo/[Cairo, GdkCairo] 
import gtk/[Gtk, Widget, Window]
import zombieconfig


MainUI: class {
    win: Window

    width, height: Int

    init: func (config: ZombieConfig) {
        win = Window new(config["title"])

        width  = config["screenWidth"] toInt()
        height = config["screenHeight"] toInt()
        win setUSize(width as GInt, height as GInt)
        win setPosition(Window POS_CENTER)

        win connect("delete_event", exit) // exit on window close

        // redraw on each window move, possibly before!
        win connect("expose-event", ||
            cr := GdkContext new(win getWindow())
            draw(cr)
            cr destroy()
        )

        win showAll()
    }

    run: func {
        Gtk main()
    }

    draw: func (cr: Context) {
        background(cr)
        triangle(cr)
    }

    background: func (cr: Context) {
        cr setSourceRGB(0, 0, 0)
        cr paint()
    }

    triangle: func (cr: Context) {
        cr setLineWidth(15)
        cr setSourceRGB(255, 0, 0)
        cr moveTo(0, 0)
        cr lineTo(width / 2, height)
        cr relLineTo(width / 2, -height)
        cr closePath()
        cr stroke()
    }

}
