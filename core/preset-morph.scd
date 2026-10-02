// preset-morph.scd
// Morph an Ndef/NF between two presets read from presets.scd.
//
//   ~presets = ~loadPresets.(~here ++ "core/presets.scd");
//   m = ~presetMorph.(\gorse, ~presets[\gorse]);
//   m.ndef.play;
//   m.go(3, \zigzag, 20);    // to preset 3, zigzagging, over 20 seconds
//   m.place(0.5);            // or sit between the two by hand
//   m.cancel;                // abandon a morph in progress
//
// Pass ~specs[\gorse] as third argument to blend in fader space (else raw values).

(

// Lines inside /* */ or after // are skipped, so a parked preset is out of the set.
~loadPresets = { |path|
	var out = (), inComment = false;
	~presetClasses = ~presetClasses ? ();
	File.readAllString(path.standardizePath).split($\n).do { |line|
		var l = line.stripWhiteSpace, m;
		if(l.contains("/*")) { inComment = true };
		if(l.contains("*/")) { inComment = false; l = "" };
		if(inComment.not and: { l.beginsWith("//").not }) {
			m = l.findRegexp("(NF|Ndef)\\('?([a-zA-Z0-9_]+)'?\\)\\.set\\((.+)\\);");
			if(m.size > 0) {
				var key = m[2][1].asSymbol;
				~presetClasses[key] = m[1][1].asSymbol.asClass;
				out[key] = (out[key] ? []).add(().putPairs(("[" ++ m[3][1] ++ "]").interpret));
			};
		};
	};
	out.keysValuesDo { |k, v| ("presets: " ++ k ++ " " ++ v.size).postln };
	out
};

// t runs 0 to 1; each returns the position between A and B.
~morphCurves = (
	jump:    { |t| t.ceil },
	hold:    { |t| t.floor },
	linear:  { |t| t },
	smooth:  { |t| t.squared * (3 - (2 * t)) },
	accel:   { |t| t.cubed },
	decel:   { |t| 1 - (1 - t).cubed },
	zigzag:  { |t| (t + (sin(t * 8 * pi) * 0.4 * sin(t * pi))).clip(0, 1) },
	steps:   { |t| (t * 5).round / 5 },
	scatter: { |t| if(t >= 1) { 1 } { (t + 0.35.rand2).clip(0, 1) } }
);

~presetMorph = { |ndef, presets, specs, bounds, dur = 10, curve = \linear|

	var bg     = Color.new255(23, 27, 33);
	var resolved;
	var panel  = Color.new255(30, 35, 43);
	var trough = Color.new255(45, 52, 63);
	var accent = Color.new255(115, 179, 207);
	var mint   = Color.new255(140, 225, 180);
	var amber  = Color.new255(255, 200, 80);
	var text   = Color.new255(220, 225, 235);
	var font   = Font("Menlo", 11);

	var names  = (1 .. presets.size).collect(_.asString);
	var curves = ~morphCurves.keys.asArray.sort;

	var from = 0, to = 1, pos = 0, task;
	var win, fromMenu, toMenu, methodMenu, durBox, posSlider, posBox;
	var blend, go, stop, post, btn, label;

	// a symbol resolves through the material library, else the class named in presets.scd
	if(ndef.isKindOf(Symbol)) {
		resolved = if(~gen.notNil) { ~gen.(ndef) } { (~presetClasses[ndef] ? Ndef).new(ndef) };
		ndef = resolved;
	};
	if(ndef.isKindOf(NodeProxy).not) {
		Error("presetMorph: first argument is not a proxy. Pass NF(\\gorse), or a bare"
			" \\gorse after loading material-library.scd.").throw;
	};
	if(ndef.source.isNil) {
		("presetMorph: " ++ ndef.key ++ " has no source yet, so it will stay silent."
			" Run ~gen.(\\" ++ ndef.key ++ ") or define it first.").warn;
	};

	win = Window("morph: " ++ ndef.key, bounds ?? { Rect(200, 460, 460, 230) }).background_(bg);

	label = { |s| StaticText(win).string_(s).font_(font).stringColor_(text).fixedWidth_(46) };
	btn = { |str, fg, bgc, action|
		Button(win).font_(font).fixedHeight_(24).states_([[str, fg, bgc]]).action_(action)
	};

	// 0 sits on A, 1 on B; keys missing from one side hold the other's value
	blend = { |t|
		var a = presets[from], b = presets[to], args = [];
		(a.keys | b.keys).do { |k|
			var va = a[k] ? b[k], vb = b[k] ? a[k], spec = (specs ? ())[k];
			args = args.add(k).add(
				if(spec.notNil) {
					spec.asSpec.map(spec.asSpec.unmap(va).blend(spec.asSpec.unmap(vb), t))
				} {
					va.blend(vb, t)
				}
			);
		};
		pos = t;
		ndef.set(*args);
		{ posSlider.value = t; posBox.value = t.round(0.001) }.defer;
		t
	};

	stop = { task.stop; task = nil };

	go = { |target, method, dur|
		var curve, dt = 0.02, steps;
		target !? { to = (target - 1).clip(0, presets.size - 1); { toMenu.value = to }.defer };
		method = method ?? { curves[methodMenu.value] };
		dur = (dur ?? { durBox.value }).max(0.02);
		curve = ~morphCurves[method.asSymbol] ?? { ~morphCurves[\linear] };
		steps = (dur / dt).round.max(1);
		stop.();
		task = Routine {
			(steps + 1).do { |i| blend.(curve.(i / steps)); dt.wait };
			blend.(1.0);
		}.play(AppClock);
		task
	};

	post = {
		var body = ndef.getKeysValues.collect { |p| "\\" ++ p[0] ++ ", " ++ p[1].round(0.01) }.join(", ");
		(ndef.class.name ++ "(" ++ ndef.key.asCompileString ++ ").set(" ++ body ++ ");").postln;
	};

	fromMenu = PopUpMenu(win).items_(names).value_(0).font_(font)
		.background_(panel).stringColor_(text).action_({ |v| from = v.value });
	toMenu = PopUpMenu(win).items_(names).value_(1).font_(font)
		.background_(panel).stringColor_(text).action_({ |v| to = v.value });
	methodMenu = PopUpMenu(win).items_(curves.collect(_.asString)).font_(font)
		.background_(panel).stringColor_(text).value_(curves.indexOf(curve.asSymbol).max(0));
	durBox = NumberBox(win).font_(font).align_(\center).fixedWidth_(60).decimals_(2)
		.background_(panel).normalColor_(text).typingColor_(amber).value_(dur);

	posSlider = Slider(win).orientation_(\horizontal).background_(trough).knobColor_(accent)
		.fixedHeight_(20).action_({ |v| stop.(); blend.(v.value) });
	posBox = NumberBox(win).font_(font).align_(\center).fixedWidth_(60).decimals_(3)
		.background_(panel).normalColor_(text).typingColor_(amber).value_(0)
		.action_({ |v| stop.(); blend.(v.value.clip(0, 1)) });

	win.layout = VLayout(
		HLayout(label.("from"), fromMenu, label.("to"), toMenu,
			btn.("swap", text, panel, { var t = from; from = to; to = t;
				fromMenu.value = from; toMenu.value = to })),
		HLayout(label.("how"), methodMenu, label.("secs"), durBox, nil),
		HLayout(posSlider, posBox),
		// ~gen runs into its own bus only; play adds the hardware monitor
		HLayout(
			btn.("play", bg,   mint,   { ndef.play }),
			btn.("stop", text, panel,  { ndef.stop }),
			btn.("go",   bg,   mint,   { go.() }),
			btn.("halt", text, panel,  { stop.() })
		),
		HLayout(
			btn.("A",    bg,   accent, { stop.(); blend.(0) }),
			btn.("B",    bg,   accent, { stop.(); blend.(1) }),
			btn.("post", bg,   amber,  { post.() })
		)
	).spacing_(8).margins_(12);

	win.front;
	win.onClose_({ stop.() });

	// method-style handles, named clear of Event's \stop / \blend / \post
	(window: win, ndef: ndef, presets: presets,
		go:         { |self, target, method, dur| go.(target, method, dur) },
		place:      { |self, t| stop.(); blend.(t) },
		cancel:     { |self| stop.() },
		printState: { |self| post.() })
};
"~loadPresets, ~morphCurves, ~presetMorph defined".postln;
)
