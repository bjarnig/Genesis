// ndef-faders.scd
// A fader GUI for an Ndef/NF: a horizontal slider for each parameter you pass a
// spec for. Parameters without a spec are not shown and are left at the Ndef's
// own defaults, untouched. Plus play/stop, reset, four randomize distributions,
// and a per-slider "include" toggle so randomize only moves the opted-in rows.
// Dark-blue theme.
//
// Evaluate this block once to define ~ndefFaders, then:
//
//   g = ~ndefFaders.(NF(\teasel), (
//       modRate: ControlSpec(1, 40, \exp, 0, 10),
//       lpf:     ControlSpec(200, 8000, \exp, 0, 1070),
//       amp:     ControlSpec(0, 1, \amp, 0, 0.7)
//   ));
//   g.randomize(\beta);    // also \uni, \exp, \walk, from code too
//   g.resetAll;
//   g.printState;          // the line to paste into presets.scd
//
// Give the specs a default (5th ControlSpec arg) so reset lands on the Ndef's
// own argument defaults; see ndef-faders-setups.scd.

(
~ndefFaders = { |ndef, specs, keys, bounds|

	var bg      = Color.new255(23, 27, 33);
	var panel   = Color.new255(30, 35, 43);
	var trough  = Color.new255(45, 52, 63);
	var accent  = Color.new255(115, 179, 207);
	var mint    = Color.new255(140, 225, 180);
	var amber   = Color.new255(255, 200, 80);
	var text    = Color.new255(220, 225, 235);
	var white   = Color.white;
	var font    = Font("Menlo", 11);

	var betaA = 2, betaB = 2;   // integer shape params, a = b = 2 favours mid-range
	var lambda = 3;             // exponential decay towards the low end
	var walkStep = 0.22;        // walk step size, in unmapped (0..1) units

	var pairs, rows, grid, footer, transport, dice, win, unmapped, randomize, reset, post, btn;

	specs = specs ? ();
	pairs = ndef.getKeysValues;
	keys = (keys ?? { pairs.collect(_[0]) }).select { |k| specs[k].notNil };

	win = Window("faders: " ++ ndef.key, bounds ?? { Rect(200, 140, 480, (keys.size * 30) + 112) })
		.background_(bg);

	// one slider row per specced parameter: label | slider | numberbox | include
	rows = keys.collect { |key|
		var spec = specs[key].asSpec;
		var val = pairs.detect { |p| p[0] == key } !? { |p| p[1] } ? spec.default;
		// enough decimals to tell neighbouring fader positions apart: a feedback
		// coefficient living between 0.99 and 1.0003 needs more than the usual two
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

	// NB: rows are Events; retrieve slots with r[\key] not r.key; \update and
	// \value collide with real Object/Event methods, so dot-access would misfire.

	// a new unmapped (0..1) position for one row, per distribution. Beta is the
	// gamma ratio X/(X+Y) with integer shapes, each gamma a sum of -log(uniform).
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

	// reset ignores the include toggles: it is a way back to a known state
	reset = { rows.do { |r| r[\update].(r[\spec].default) } };

	post = {
		var body = rows.collect { |r| "\\" ++ r[\key] ++ ", " ++ r[\number].value }.join(", ");
		(ndef.class.name ++ "(" ++ ndef.key.asCompileString ++ ").set(" ++ body ++ ");").postln;
	};

	grid = GridLayout.rows(*rows.collect { |r| [r[\label], r[\slider], r[\number], r[\include]] })
		.hSpacing_(12).vSpacing_(6).margins_(0);
	grid.setColumnStretch(1, 1);   // slider column expands, everything else fixed

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

	win.layout = VLayout(grid, transport, dice).spacing_(10).margins_(12);
	win.front;
	win.onClose_({ rows = nil });

	// Handles are called method-style: g.randomize(\beta), g.resetAll, g.printState.
	// The leading `self` is what Event hands a function under dot access, and these
	// names avoid \reset / \post / \stop / \play, which Event already defines.
	(window: win, ndef: ndef, rows: rows,
		randomize:  { |self, mode = \uni| randomize.(mode) },
		resetAll:   { |self| reset.() },
		printState: { |self| post.() })
};
"~ndefFaders defined".postln;
)
