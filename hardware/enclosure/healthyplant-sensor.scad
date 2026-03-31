// HealthyPlant Sensor Enclosure — Parametric OpenSCAD Design
// Print with PETG, 0.2mm layer height, 20% gyroid infill
// Generates: main body, lid, stake, battery tray
//
// Usage:
//   openscad -o main_body.stl -D 'part="body"' healthyplant-sensor.scad
//   openscad -o lid.stl -D 'part="lid"' healthyplant-sensor.scad
//   openscad -o stake.stl -D 'part="stake"' healthyplant-sensor.scad
//   openscad -o battery_tray.stl -D 'part="battery"' healthyplant-sensor.scad
//   openscad -o assembly.stl -D 'part="assembly"' healthyplant-sensor.scad

// ── Parameters ──────────────────────────────────

part = "assembly";  // "body", "lid", "stake", "battery", "assembly"

// Electronics box (internal dimensions)
box_w = 55;   // width (X)
box_d = 45;   // depth (Y)
box_h = 28;   // height (Z)
wall  = 2.0;  // wall thickness
tol   = 0.2;  // print tolerance for snap-fit

// Stake
stake_len   = 150;  // total length
stake_dia   = 10;   // diameter
probe_chan   = 4;    // channel diameter for soil probe wire

// Lid
lid_h       = 4;    // lid height
vent_slots  = 6;    // number of ventilation slots
vent_w      = 18;   // slot width
vent_h      = 1.5;  // slot height

// USB-C port
usbc_w = 10;
usbc_h = 4;
usbc_z = 6;  // height from bottom of box interior

// Snap-fit clips
clip_w = 8;
clip_h = 2;
clip_depth = 1.2;

// 18650 battery
batt_dia = 18.5;
batt_len = 65.5;

// ── Modules ─────────────────────────────────────

module rounded_box(w, d, h, r=3) {
    hull() {
        for (x = [r, w-r], y = [r, d-r])
            translate([x, y, 0])
                cylinder(h=h, r=r, $fn=32);
    }
}

module main_body() {
    ow = box_w + wall*2;
    od = box_d + wall*2;
    oh = box_h + wall;

    difference() {
        // Outer shell
        rounded_box(ow, od, oh);

        // Inner cavity
        translate([wall, wall, wall])
            rounded_box(box_w, box_d, box_h + 1, r=2);

        // USB-C port (left side)
        translate([-1, (od - usbc_w)/2, wall + usbc_z])
            cube([wall + 2, usbc_w, usbc_h]);

        // Drain hole (bottom center)
        translate([ow/2, od/2, -1])
            cylinder(d=3, h=wall+2, $fn=16);
    }

    // Snap-fit clip recesses (inside walls)
    for (y_pos = [od*0.25, od*0.75]) {
        // Left wall clip
        translate([wall - clip_depth, y_pos - clip_w/2, oh - clip_h - 2])
            cube([clip_depth, clip_w, clip_h]);
        // Right wall clip
        translate([ow - wall, y_pos - clip_w/2, oh - clip_h - 2])
            cube([clip_depth, clip_w, clip_h]);
    }

    // Stake mount (bottom center, tube going down)
    translate([ow/2, od/2, -stake_dia])
        difference() {
            cylinder(d=stake_dia + wall*2, h=stake_dia, $fn=32);
            translate([0, 0, -1])
                cylinder(d=stake_dia + tol, h=stake_dia + 2, $fn=32);
        }
}

module lid() {
    ow = box_w + wall*2;
    od = box_d + wall*2;

    difference() {
        union() {
            // Lid plate
            rounded_box(ow, od, lid_h);

            // Inner lip for snug fit
            translate([wall + tol, wall + tol, -3])
                rounded_box(box_w - tol*2, box_d - tol*2, 3, r=1.5);
        }

        // Ventilation slots (angled downward for rain protection)
        for (i = [0 : vent_slots - 1]) {
            x_pos = ow * (i + 1) / (vent_slots + 1);
            translate([x_pos - vent_w/2, wall + 2, lid_h - vent_h])
                cube([vent_w, box_d - 4, vent_h + 1]);
        }

        // Solar panel mount holes (4 corners)
        for (x = [8, ow-8], y = [8, od-8])
            translate([x, y, -1])
                cylinder(d=2.5, h=lid_h + 2, $fn=16);
    }

    // Snap-fit clips on lid inner lip
    for (y_pos = [od*0.25, od*0.75]) {
        // Left clip
        translate([wall + tol - 0.5, y_pos - clip_w/2, -3])
            cube([clip_depth + 0.5, clip_w, clip_h]);
        // Right clip
        translate([ow - wall - tol - clip_depth, y_pos - clip_w/2, -3])
            cube([clip_depth + 0.5, clip_w, clip_h]);
    }
}

module stake() {
    difference() {
        union() {
            // Main stake cylinder
            cylinder(d=stake_dia, h=stake_len, $fn=32);

            // Top plug (inserts into body mount)
            translate([0, 0, stake_len])
                cylinder(d=stake_dia - tol, h=stake_dia - 1, $fn=32);
        }

        // Probe wire channel (runs full length)
        translate([stake_dia/2 - probe_chan/2 - 1, -probe_chan/2, -1])
            cube([probe_chan, probe_chan, stake_len + stake_dia + 2]);

        // Pointed tip
        translate([0, 0, -1])
            cylinder(d1=0, d2=stake_dia + 2, h=20, $fn=32);
    }
}

module battery_tray() {
    // Tray that holds an 18650 battery, slides into the main body
    tray_w = box_w - 2;
    tray_d = batt_len + 4;
    tray_h = batt_dia/2 + 3;

    difference() {
        cube([tray_w, min(tray_d, box_d - 2), tray_h]);

        // Battery cradle (semi-circular channel)
        translate([tray_w/2, 2, tray_h])
            rotate([-90, 0, 0])
                cylinder(d=batt_dia + 0.5, h=batt_len + 1, $fn=32);

        // Wire slots at each end
        for (y = [0, min(tray_d, box_d - 2) - 3])
            translate([tray_w/2 - 3, y, -1])
                cube([6, 4, tray_h + 2]);
    }
}

// ── Part Selection ──────────────────────────────

if (part == "body") {
    main_body();
} else if (part == "lid") {
    lid();
} else if (part == "stake") {
    stake();
} else if (part == "battery") {
    battery_tray();
} else if (part == "assembly") {
    // Exploded assembly view
    color("#2a2a2a") main_body();

    ow = box_w + wall*2;
    od = box_d + wall*2;
    oh = box_h + wall;

    color("#00C853", 0.7)
        translate([0, 0, oh + 10])
            lid();

    color("#8B4513")
        translate([ow/2, od/2, -stake_len - stake_dia - 10])
            stake();

    color("#444")
        translate([wall + 1, wall + 1, wall + 1])
            battery_tray();
}
