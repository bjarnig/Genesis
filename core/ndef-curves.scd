// ndef-curves.scd: trajectory editor for an Ndef/NF, one 512-point curve per specced parameter.
// c = ~ndefCurves.(~gen.(\sedge), ~specs[\sedge], presets: ~presets[\sedge]); c.run(20); c.halt; c.rewind; c.recallSlot(3);

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

	var dt = 0.01;

	var pairs, rows, grid, transport, slotRow, win;
	var durBox, posSlider, posBox, posLabel, playBtn, btn, label;
	var setCurve, apply, recall, startTask, stopTask, rewind, task, pos = 0;

	specs = specs ? ();
	pairs = ndef.getKeysValues;
	keys = (keys ?? { pairs.collect(_[0]) }).select { |k| specs[k].notNil };

	win = Window("curves: " ++ ndef.key,
		bounds ?? {
			var wanted = (keys.size * 56) + 170;
			Rect(120, 80, 820, wanted.min(Window.availableBounds.height - 80))
		}).background_(bg);

	rows = keys.collect { |key|
		var spec = specs[key].asSpec;
		var val = pairs.detect { |p| p[0] == key } !? { |p| p[1] } ? spec.default;
		var flat = Array.fill(steps, spec.unmap(val).clip(0.0, 1.0));
		var lab, msv, r;

		lab = StaticText(win).string_(key).font_(font).stringColor_(white)
			.align_(\left).fixedWidth_(96);

		msv = MultiSliderView(win).size_(steps).value_(flat).minHeight_(28)
			.elasticMode_(1).gap_(0).drawRects_(false).drawLines_(true).isFilled_(false)
			.background_(trough).strokeColor_(accent).fillColor_(accent);

		r = (key: key, spec: spec, label: lab, msv: msv, curve: flat);
		msv.action = { |v| r[\curve] = v.value };
		r
	};

	// rows are Events: read r[\curve], never r.curve

	setCurve = { |r, arr| r[\msv].value = arr; r[\curve] = arr };

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

	stopTask = { task !? { task.stop }; task = nil };

	startTask = {
		stopTask.();
		if(pos >= 1.0) { pos = 0 };
		task = Routine {
			while { pos < 1.0 } {
				apply.(pos);
				dt.wait;
				pos = pos + (dt / durBox.value.max(dt));
			};
			apply.(1.0);
			task = nil;
		}.play(AppClock);   // AppClock: GUI writes in apply need no defer
	};

	rewind = {
		pos = 0;
		apply.(0);
		if(playBtn.value == 1) { startTask.() };
	};

	recall = { |i|
		(presets !? { |ps| ps[i] }) !? { |preset|
			rows.do { |r|
				preset[r[\key]] !? { |v|
					setCurve.(r, Array.fill(steps, r[\spec].unmap(v).clip(0.0, 1.0)))
				}
			};
			apply.(pos);
		}
	};

	btn = { |str, fg, bgc, action|
		Button(win).font_(font).fixedHeight_(24).states_([[str, fg, bgc]]).action_(action)
	};
	label = { |s| StaticText(win).string_(s).font_(font).stringColor_(text).fixedWidth_(40) };

	durBox = NumberBox(win).font_(font).align_(\center).fixedWidth_(60).decimals_(2)
		.background_(panel).normalColor_(text).typingColor_(amber).value_(dur);

	posSlider = Slider(win).orientation_(\horizontal).background_(trough).knobColor_(accent)
		.fixedHeight_(20).action_({ |v| apply.(v.value) });
	posBox = NumberBox(win).font_(font).align_(\center).fixedWidth_(60).decimals_(3)
		.background_(panel).normalColor_(text).typingColor_(amber).value_(0)
		.action_({ |v| apply.(v.value.clip(0.0, 1.0)) });
	posLabel = StaticText(win).string_("playhead").font_(font).stringColor_(text)
		.align_(\left).fixedWidth_(96);

	grid = GridLayout.rows(*([[posLabel, posSlider]] ++ rows.collect { |r| [r[\label], r[\msv]] }))
		.hSpacing_(12).vSpacing_(6).margins_(0);
	grid.setColumnStretch(1, 1);
	grid.setRowStretch(0, 0);

	playBtn = Button(win).font_(font).fixedHeight_(24)
		.states_([["play", bg, mint], ["stop", text, panel]])
		.action_({ |v|
			if(v.value == 1) { ndef.play; startTask.() } { stopTask.(); ndef.stop }
		});

	transport = HLayout(
		playBtn,
		btn.("reset", bg, accent, { rewind.() }),
		label.("secs"), durBox,
		label.("at"), posBox
	);

	slotRow = HLayout(*(1..8).collect { |i|
		var filled = (presets ? []).size >= i;
		btn.(i.asString, if(filled) { bg } { text }, if(filled) { mint } { panel },
			{ recall.(i - 1) })
	});

	win.layout = VLayout(transport, slotRow, grid).spacing_(10).margins_(12);
	win.front;
	win.onClose_({ stopTask.() });

	(window: win, ndef: ndef, rows: rows, presets: presets,
		run:        { |self, secs|
			secs !? { durBox.value = secs };
			playBtn.value = 1; ndef.play; startTask.() },
		halt:       { |self| playBtn.value = 0; stopTask.(); ndef.stop },
		rewind:     { |self| rewind.() },
		recallSlot: { |self, i| recall.(i - 1) },
		place:      { |self, t| apply.(t.clip(0.0, 1.0)) },
		curves:     { |self| rows.collect { |r| r[\curve] } })
};
"~ndefCurves defined".postln;
)
