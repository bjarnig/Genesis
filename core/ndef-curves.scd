// ndef-curves.scd
// A trajectory editor for an Ndef/NF: one multislider per specced parameter,
// each holding a curve of 512 points that the parameter walks along over one
// duration, global to every row. The fader GUI edits a state, the morph GUI
// travels between two of them; this one draws the shape of the journey.
//
// Evaluate this block once to define ~ndefCurves, then:
//
//   c = ~ndefCurves.(~gen.(\sedge), ~specs[\sedge], presets: ~presets[\sedge]);
//   c.run(20);          // walk every curve, left to right, over 20 seconds
//   c.halt;
//   c.recallSlot(3);    // preset 3 as a flat line in every row
//   c.place(0.5);       // sit halfway along the curves by hand
//
// A preset button flattens every curve it names onto that preset's own value,
// so recalling one sounds exactly like the preset does in the fader window -
// that is the state to start drawing from. Parameters a preset does not mention
// keep the curve they have, as the fader window's own recall leaves them alone.
//
// Points are read with blendAt and set every 10 ms, so the 512 steps glide into
// each other instead of stair-stepping, whatever the duration. Changing the
// duration changes how far each step travels, never how often one happens.
//
// The window is tall by nature - one drawable row per parameter - so it opens no
// taller than the screen and puts the transport, presets and playhead along the
// top, above the rows. The rows take whatever height is left and compress when
// there are many: drag the window taller on a big display to draw more finely.

(
~ndefCurves = { |ndef, specs, keys, bounds, presets, dur = 20, steps = 512|

	var bg     = Color.new255(23, 27, 33);
	var panel  = Color.new255(30, 35, 43);
	var trough = Color.new255(45, 52, 63);
	var accent = Color.new255(115, 179, 207);
	var mint   = Color.new255(140, 225, 180);
	var amber  = Color.new255(255, 200, 80);
	var text   = Color.new255(220, 225, 235);
	var white  = Color.white;
	var font   = Font("Menlo", 11);

	var dt = 0.01;   // control step: 100 sets a second, whatever the duration is

	var pairs, rows, grid, transport, slotRow, win;
	var durBox, posSlider, posBox, posLabel, btn, label;
	var setCurve, apply, recall, run, stop, task, pos = 0;

	specs = specs ? ();
	pairs = ndef.getKeysValues;
	keys = (keys ?? { pairs.collect(_[0]) }).select { |k| specs[k].notNil };

	// the window has to fit the screen, not the parameter count: a tall process
	// asked for more height than the display had, and the controls fell off the
	// bottom edge where a screenshot still found them but the mouse could not
	win = Window("curves: " ++ ndef.key,
		bounds ?? {
			var wanted = (keys.size * 56) + 170;
			Rect(120, 80, 820, wanted.min(Window.availableBounds.height - 80))
		}).background_(bg);

	// one multislider per specced parameter, starting flat at the value the proxy
	// already holds, so opening the window changes nothing about the sound
	rows = keys.collect { |key|
		var spec = specs[key].asSpec;
		var val = pairs.detect { |p| p[0] == key } !? { |p| p[1] } ? spec.default;
		// presets predating a spec edit can sit outside it, so unmapped positions
		// are clipped: a curve point is always somewhere on the slider
		var flat = Array.fill(steps, spec.unmap(val).clip(0.0, 1.0));
		var lab, msv, r;

		lab = StaticText(win).string_(key).font_(font).stringColor_(white)
			.align_(\left).fixedWidth_(96);

		// minHeight, so a process with many parameters squeezes its rows instead of
		// pushing the window past the bottom of the screen
		msv = MultiSliderView(win).size_(steps).value_(flat).minHeight_(28)
			.elasticMode_(1).gap_(0).drawRects_(false).drawLines_(true).isFilled_(false)
			.background_(trough).strokeColor_(accent).fillColor_(accent);

		r = (key: key, spec: spec, label: lab, msv: msv, curve: flat);
		msv.action = { |v| r[\curve] = v.value };
		r
	};

	// NB: rows are Events; read a slot with r[\curve], never r.curve. Dot access
	// on an Event calls whatever it finds there, as noted in ndef-faders.scd.

	setCurve = { |r, arr| r[\msv].value = arr; r[\curve] = arr };

	// every parameter at one point along its own curve. blendAt interpolates
	// between the drawn points, so t is continuous, not one of 512 positions.
	apply = { |t|
		var args = [];
		rows.do { |r|
			args = args.add(r[\key]).add(r[\spec].map(r[\curve].blendAt(t * (steps - 1))))
		};
		ndef.set(*args);
		pos = t;
		posSlider.value = t;
		posBox.value = t.round(0.001);
		t
	};

	stop = { task !? { task.stop }; task = nil };

	// one pass, left to right, over the duration in the secs box. The duration is
	// read once at the start, so a pass keeps the speed it began with.
	run = {
		var secs = durBox.value.max(dt);
		stop.();
		task = Routine {
			var t = 0;
			while { t < 1.0 } {
				apply.(t);
				dt.wait;
				t = t + (dt / secs);
			};
			apply.(1.0);     // always land exactly on the right-hand edge
			task = nil;
		}.play(AppClock);    // AppClock, so apply's GUI writes need no defer
		task
	};

	// a preset flattens every curve it names onto that value: the trajectory
	// becomes a held state again, and sounds like the preset does in the faders
	recall = { |i|
		(presets !? { |ps| ps[i] }) !? { |preset|
			rows.do { |r|
				preset[r[\key]] !? { |v|
					setCurve.(r, Array.fill(steps, r[\spec].unmap(v).clip(0.0, 1.0)))
				}
			};
			stop.();
			apply.(0.0);
		}
	};

	btn = { |str, fg, bgc, action|
		Button(win).font_(font).fixedHeight_(24).states_([[str, fg, bgc]]).action_(action)
	};
	label = { |s| StaticText(win).string_(s).font_(font).stringColor_(text).fixedWidth_(40) };

	durBox = NumberBox(win).font_(font).align_(\center).fixedWidth_(60).decimals_(2)
		.background_(panel).normalColor_(text).typingColor_(amber).value_(dur);

	// drag to scrub the whole set of curves by hand, as the morph window's does
	posSlider = Slider(win).orientation_(\horizontal).background_(trough).knobColor_(accent)
		.fixedHeight_(20).action_({ |v| stop.(); apply.(v.value) });
	posBox = NumberBox(win).font_(font).align_(\center).fixedWidth_(60).decimals_(3)
		.background_(panel).normalColor_(text).typingColor_(amber).value_(0)
		.action_({ |v| stop.(); apply.(v.value.clip(0.0, 1.0)) });
	posLabel = StaticText(win).string_("playhead").font_(font).stringColor_(text)
		.align_(\left).fixedWidth_(96);

	// the playhead is a row of the same grid as the curves, so the column sizing
	// itself keeps it aligned: its ends are the ends of the multisliders, and its
	// knob sits over the point in the curves that is sounding
	grid = GridLayout.rows(*([[posLabel, posSlider]] ++ rows.collect { |r| [r[\label], r[\msv]] }))
		.hSpacing_(12).vSpacing_(6).margins_(0);
	grid.setColumnStretch(1, 1);   // the curves take the width, labels stay fixed
	grid.setRowStretch(0, 0);      // the playhead keeps its 20px, the rows share the rest

	// the readout lives up here rather than beside the playhead, so the playhead
	// itself can run the full width of the curve column
	transport = HLayout(
		btn.("play", bg,   mint,   { ndef.play }),
		btn.("stop", text, panel,  { ndef.stop }),
		btn.("run",  bg,   mint,   { run.() }),
		btn.("halt", text, panel,  { stop.() }),
		label.("secs"), durBox,
		label.("at"), posBox
	);

	// eight preset buttons, lit where presets.scd actually has a line for this one
	slotRow = HLayout(*(1..8).collect { |i|
		var filled = (presets ? []).size >= i;
		btn.(i.asString, if(filled) { bg } { text }, if(filled) { mint } { panel },
			{ recall.(i - 1) })
	});

	// controls first, curves underneath: the rows are the part that grows with the
	// process, so they are the part that gets to run out of room, never the transport.
	// The playhead is inside grid, as its first row.
	win.layout = VLayout(transport, slotRow, grid).spacing_(10).margins_(12);
	win.front;
	win.onClose_({ stop.() });

	// method-style handles, as in the fader and morph windows
	(window: win, ndef: ndef, rows: rows, presets: presets,
		run:        { |self, secs| secs !? { durBox.value = secs }; run.() },
		halt:       { |self| stop.() },
		recallSlot: { |self, i| recall.(i - 1) },
		place:      { |self, t| stop.(); apply.(t.clip(0.0, 1.0)) },
		curves:     { |self| rows.collect { |r| r[\curve] } })
};
"~ndefCurves defined".postln;
)
