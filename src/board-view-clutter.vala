/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

private class Light : Clutter.Group
{
    private Clutter.Actor off;
    private Clutter.Actor on;
    private bool _is_lit;
    
    private const double SCALE_OFF = 0.9;
    private const double SCALE_ON = 1.0;
    public bool is_lit
    {
        get { return _is_lit; }
        set
        {
            value = value != false;
            if (value != _is_lit)
                toggle_pixel ();
        }
    }

    public Light (Clutter.Actor off_actor, Clutter.Actor on_actor)
    {
        set_scale (SCALE_OFF, SCALE_OFF);

        off = new Clutter.Clone (off_actor);
        off.set_pivot_point (0.5f, 0.5f);
        add_child (off);

        on = new Clutter.Clone (on_actor);
        on.set_pivot_point (0.5f, 0.5f);
        on.opacity = 0;
        add_child (on);

        // Add a 2 px margin around the tile image, center tiles within it.
        off.set_position (2, 2);
        on.set_position (2, 2);

        off.set_easing_duration (300);
        on.set_easing_duration (300);
        off.set_easing_mode (Clutter.AnimationMode.EASE_OUT_SINE);
        on.set_easing_mode (Clutter.AnimationMode.EASE_OUT_SINE);
        set_easing_duration (300);
        set_easing_mode (Clutter.AnimationMode.EASE_OUT_SINE);

    }

    public void toggle_pixel (Clutter.Timeline? timeline = null)
    {
        _is_lit = !_is_lit;

        save_easing_state ();
        if (timeline == null)
            set_easing_duration (0);

        // Animate the opacity of the 'off' tile to match the state.
        off.set_opacity (is_lit ? 0 : 255);
        on.set_opacity (is_lit ? 255 : 0);

        set_scale (is_lit ? SCALE_ON : SCALE_OFF, is_lit ? SCALE_ON : SCALE_OFF);

        restore_easing_state ();
    }
}

public class BoardViewClutter : Clutter.Group, BoardView
{

    private PuzzleGenerator puzzle_generator;

    public bool playable = true;

    private int _moves = 0;
    public int moves
    {
        get { return _moves;}
    }
    public int get_moves() { return _moves;}

    private Clutter.Actor off_texture;
    private Clutter.Actor on_texture;
    private Light[,] lights;

    public BoardViewClutter (Clutter.Actor off_texture, Clutter.Actor on_texture)
    {
        this.off_texture = off_texture;
        this.on_texture = on_texture;
        puzzle_generator = new PuzzleGenerator (size);
        lights = new Light [size, size];
        for (var x = 0; x < size; x++)
        {
            for (var y = 0; y < size; y++)
            {
                var l = new Light (off_texture, on_texture);

                l.reactive = true;
                var tap = new Clutter.TapAction ();
                l.add_action (tap);
                tap.tap.connect ((tap, actor) => handle_toggle (actor));

                float xx, yy;
                get_light_position (x, y, out xx, out yy);
                l.set_pivot_point (0.5f, 0.5f);
                l.set_position (xx, yy);

                lights[x, y] = l;
                add_child (l);
            }
        }
        _moves = 0;
    }

    public void get_light_position (int x, int y, out float xx, out float yy)
    {
        xx = x * off_texture.width;
        yy = y * off_texture.height;
    }

    public void slide_in (int direction, int sign, Clutter.Timeline timeline)
    {
        /* Place offscreen */
        x = -sign * direction * width;
        y = -sign * (1 - direction) * height;

        /* Slide onscreen */
        animate_with_timeline (Clutter.AnimationMode.EASE_OUT_BOUNCE, timeline, "x", 0.0, "y", 0.0);
    }

    public void slide_out (int direction, int sign, Clutter.Timeline timeline)
    {
        /* Slide offscreen */
        animate_with_timeline (Clutter.AnimationMode.EASE_OUT_BOUNCE, timeline,
                               "x", sign * direction * width,
                               "y", sign * (1 - direction) * height);
    }

    // Toggle a light and those in each cardinal direction around it.
    public void toggle_light (int x, int y, bool animate = true)
    {
        if (!playable)
            return;

        Clutter.Timeline? timeline = null;
        if (animate)
        {
            timeline = new Clutter.Timeline (300);
        }

        if ((int) x + 1 < size)
            lights[(int) x + 1, (int) y].toggle_pixel (timeline);
        if ((int) x - 1 >= 0)
            lights[(int) x - 1, (int) y].toggle_pixel (timeline);
        if ((int) y + 1 < size)
            lights[(int) x, (int) y + 1].toggle_pixel (timeline);
        if ((int) y - 1 >= 0)
            lights[(int) x, (int) y - 1].toggle_pixel (timeline);

        lights[(int) x, (int) y].toggle_pixel (timeline);

        if (animate)
            timeline.start ();
    }

    public PuzzleGenerator get_puzzle_generator ()
    {
        return puzzle_generator;
    }

    public void clear_level ()
    {
        /* Clear level */
        for (var x = 0; x < size; x++)
            for (var y = 0; y < size; y++)
                lights[x, y].is_lit = false;
    }

    public bool is_light_active (int x, int y)
    {
        return lights[x, y].is_lit;
    }

    public GLib.Object get_light_at (int x, int y)
    {
        return lights[x, y];
    }

    public void increase_moves ()
    {
        _moves += 1;
    }

}