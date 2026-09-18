// preset-morph.scd
// Move an Ndef/NF from one preset to another: a state to start from, a state to
// go to, a way of travelling, and how long it takes. The presets are the lines
// the fader GUI's post button prints, read straight out of presets.scd.
//
// See ../example.scd for the running order. The short version:
//
//   ~presets = ~loadPresets.("/Users/bjarni/Works/Pieces/Genesis/core/presets.scd");
//   m = ~presetMorph.(\gorse, ~presets[\gorse]);
//   m.ndef.play;
//   m.go(3, \zigzag, 20);    // to preset 3, zigzagging, over 20 seconds
//   m.place(0.5);            // or sit between the two by hand
//   m.cancel;                // abandon a morph in progress
//
// Pass ~specs[\gorse] as a third argument to blend in fader space, so an \exp
// frequency glides geometrically rather than linearly. Without it, blending is
// linear on raw values. go always travels from the `from` preset to the `to` one,
// so the slider stays meaningful and you can walk back; press swap to chain.
// NF inherits from Ndef, so both work the same way here.
//
// dur and curve (5th/6th args) just seed the window's own secs/how controls -
// still yours to change by hand after it opens. See preset-morph-setups.scd
// for one block per process with a duration/curve matched to its own timescale.

(

// presets.scd holds one `NF('gorse').set(\a, 0.75, ...);` line per preset, which
// is exactly what the fader GUI's post button prints. Lines inside /* */ or after
// // are skipped, so parking a preset in a comment takes it out of the set.
~loadPresets = { |path|
	var out = (), inComment = false;
	~presetClasses = ~presetClasses ? ();   // key -> NF or Ndef, as the file writes it
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

// t runs 0 to 1 over the duration; each returns where between A and B to sit.
// Add your own here: any function of t that ends at 1 will do.
~morphCurves = (
	jump:    { |t| t.ceil },                                      // there on the first step
	hold:    { |t| t.floor },                                     // stay on A, arrive at the end
	linear:  { |t| t },
	smooth:  { |t| t.squared * (3 - (2 * t)) },                    // ease in and out
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

	// a symbol resolves through the material library when it is loaded, so the proxy
	// arrives with a source; failing that, through the class named in presets.scd
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

	// one blend position: 0 sits on A, 1 on B. Keys missing from either side hold
	// the value they have on the other, so presets of different vintage still morph.
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

	// travel from where we are now to preset `target` over `dur` seconds
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
			blend.(1.0);            // always land exactly on B
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
		// ~gen instantiates the proxy into its own bus only, so without this the
		// morph runs silently: play is what puts a monitor on the hardware
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

	// method-style handles, named clear of Event's own \stop / \blend / \post
	(window: win, ndef: ndef, presets: presets,
		go:         { |self, target, method, dur| go.(target, method, dur) },
		place:      { |self, t| stop.(); blend.(t) },   // takes over from a running morph, as the slider does
		cancel:     { |self| stop.() },
		printState: { |self| post.() })
};
"~loadPresets, ~morphCurves, ~presetMorph defined".postln;
)
