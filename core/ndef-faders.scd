// ndef-faders.scd: fader GUI for an Ndef/NF with randomize, reset, include toggles and 8 preset slots.
// g = ~ndefFaders.(NF(\teasel), (lpf: ControlSpec(200, 8000, \exp, 0, 1070))); g.randomize(\beta); g.printState;

(
~ndefFaders = { |ndef, specs, keys, bounds, presets|

	var bg      = Color.new255(23, 27, 33);
	var panel   = Color.new255(30, 35, 43);
	var trough  = Color.new255(45, 52, 63);
	var accent  = Color.new255(115, 179, 207);
	var mint    = Color.new255(140, 225, 180);
	var amber   = Color.new255(255, 200, 80);
	var text    = Color.new255(220, 225, 235);
	var white   = Color.white;
	var font    = Font("Menlo", 11);

	var betaA = 2, betaB = 2;
	var lambda = 3;
	var walkStep = 0.22;

	var pairs, rows, grid, footer, transport, dice, slots, slotRow, win, unmapped, randomize, reset, post, btn;

	specs = specs ? ();
	pairs = ndef.getKeysValues;
	keys = (keys ?? { pairs.collect(_[0]) }).select { |k| specs[k].notNil };

	slots = Array.newClear(8);
	presets !? { |ps| ps.do { |p, i| if(i < 8) { slots[i] = p.getPairs.clump(2) } } };

	win = Window("faders: " ++ ndef.key, bounds ?? { Rect(200, 140, 480, (keys.size * 30) + 146) })
		.background_(bg);

	rows = keys.collect { |key|
		var spec = specs[key].asSpec;
		var val = pairs.detect { |p| p[0] == key } !? { |p| p[1] } ? spec.default;
		var decimals = (3 - (spec.maxval - spec.minval).log10).ceil.clip(2, 6).asInteger;
		var round = 10 ** decimals.neg;
		var lab, sld, num, inc, update;

		lab = StaticText(win).string_(key).font_(font).stringColor_(white).align_(\left).fixedWidth_(96);
		sld = Slider(win).orientation_(\horizontal).background_(trough).knobColor_(accent).fixedHeight_(20);
		num = NumberBox(win).font_(font).align_(\center).fixedWidth_(60).decimals_(decimals)
			.background_(panel).normalColor_(text).typingColor_(amber);
		inc = Button(win).font_(font).fixedWidth_(40).fixedHeight_(20)
			.states_([["man", text, panel], ["on", bg, mint]]).value_(1);

		update = { |v, moveSlider = true|
			if(moveSlider) { sld.value = spec.unmap(v) };
			num.value = v.round(round);
			ndef.set(key, v);
		};
		sld.action = { update.(spec.map(sld.value), false) };
		num.action = { update.(num.value) };
		sld.value = spec.unmap(val);
		num.value = val.round(round);

		(key: key, spec: spec, label: lab, slider: sld, number: num, include: inc, update: update)
	};

	// rows are Events: use r[\key], not r.key (\update and \value collide with Event methods)

	unmapped = { |mode, r|
		switch(mode.asSymbol,
			\beta, {
				var x = ({ 1.0.rand.log.neg } ! betaA).sum;
				var y = ({ 1.0.rand.log.neg } ! betaB).sum;
				x / (x + y)
			},
			\exp,  { (1.0.rand.log.neg / lambda).clip(0.0, 1.0) },
			\walk, { (r[\slider].value + sum3rand(walkStep)).fold(0.0, 1.0) },
			{ 1.0.rand }
		)
	};

	randomize = { |mode = \uni|
		rows.do { |r| if(r[\include].value == 1) { r[\update].(r[\spec].map(unmapped.(mode, r))) } };
	};

	reset = { rows.do { |r| r[\update].(r[\spec].default) } };

	post = {
		var line = { |kvs|
			var body = kvs.collect { |kv| "\\" ++ kv[0] ++ ", " ++ kv[1] }.join(", ");
			ndef.class.name ++ "(" ++ ndef.key.asCompileString ++ ").set(" ++ body ++ ");"
		};
		var lines = slots.reject(_.isNil).collect(line);
		if(lines.isEmpty) {
			lines = [line.(rows.collect { |r| [r[\key], r[\number].value] })];
		};
		lines.do(_.postln);
	};

	grid = GridLayout.rows(*rows.collect { |r| [r[\label], r[\slider], r[\number], r[\include]] })
		.hSpacing_(12).vSpacing_(6).margins_(0);
	grid.setColumnStretch(1, 1);

	btn = { |label, fg, bgc, action|
		Button(win).font_(font).fixedHeight_(24).states_([[label, fg, bgc]]).action_(action)
	};

	transport = HLayout(
		btn.("play",  bg,   mint,   { ndef.play }),
		btn.("stop",  text, panel,  { ndef.stop }),
		btn.("reset", bg,   accent, { reset.() }),
		btn.("post",  text, panel,  { post.() })
	);

	dice = HLayout(
		btn.("uni",  bg, amber, { randomize.(\uni) }),
		btn.("beta", bg, amber, { randomize.(\beta) }),
		btn.("exp",  bg, amber, { randomize.(\exp) }),
		btn.("walk", bg, amber, { randomize.(\walk) })
	);

	// single click is held one clock tick so a double-click can cancel it; otherwise saving would recall first
	slotRow = HLayout(*(1..8).collect { |i|
		var filled = slots[i - 1].notNil;
		var b = Button(win).font_(font).fixedHeight_(24)
			.states_([[i.asString, if(filled) { bg } { text }, if(filled) { mint } { panel }]]);
		var pendingRecall;
		b.mouseDownAction_({ |v, x, y, modifiers, buttonNumber, clickCount|
			if(clickCount >= 2) {
				pendingRecall = nil;
				slots[i - 1] = rows.collect { |r| [r[\key], r[\number].value] };
				b.states_([[i.asString, bg, mint]]).refresh;
			} {
				pendingRecall = true;
				AppClock.sched(0.4, {
					if(pendingRecall == true) {
						slots[i - 1] !? { |kvs|
							kvs.do { |kv| rows.detect { |r| r[\key] == kv[0] } !? { |r| r[\update].(kv[1]) } };
						};
					};
					nil
				});
			};
		});
		b
	});

	win.layout = VLayout(grid, transport, dice, slotRow).spacing_(10).margins_(12);
	win.front;
	win.onClose_({ rows = nil });

	// self is what Event passes under dot access; names avoid Event's \reset, \post, \stop, \play
	(window: win, ndef: ndef, rows: rows,
		randomize:  { |self, mode = \uni| randomize.(mode) },
		resetAll:   { |self| reset.() },
		printState: { |self| post.() })
};
"~ndefFaders defined".postln;
)
