use cairo, gtk

// game deps
import Sprite

// libs deps
import cairo/[Cairo, GdkCairo] 
import gtk/[Gtk, Widget, Window]
import gdk/[Event]
import structs/[ArrayList]
import zombieconfig


MainUI: class {
    win: Window

    width, height: Int

    sprites := ArrayList<Sprite> new()

    init: func (config: ZombieConfig) {
        win = Window new(config["title"])

        width  = config["screenWidth"] toInt()
        height = config["screenHeight"] toInt()
        win setUSize(width as GInt, height as GInt)
        win setPosition(Window POS_CENTER)

        win connect("delete-event", exit) // exit on window close

        // redraw on each window move, possibly before!
        win connect("expose-event", || this draw())

        // capture key events!
        win connectNaked("key-press-event", this, keyPressed)

        win showAll()
    }

    run: func {
        Gtk main()
    }

    keyPressed: func (ev: EventKey*) {
        "Key pressed! event = %p" printfln(ev)
    }

    redraw: func {
        gdkWin := win getWindow()
        gdkWin invalidateRegion(gdkWin getClipRegion(), false)
    }

    draw: func {
        gdkWin := win getWindow()
        cr := GdkContext new(gdkWin)
        paint(cr)
        cr destroy()
    }

    paint: func (cr: Context) {
        background(cr)
        sprites each(|sprite|
            sprite draw(cr)
        )
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
