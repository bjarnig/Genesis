// Renders the three windows to docs/*.png. Run: sclang docs/screenshots.scd
(
Routine({
	var here = thisProcess.nowExecutingPath.dirname +/+ "../";
	var shot = { |name, build|
		var window = build.value, image;
		0.6.wait;
		image = Image.fromWindow(window);
		image.write(here ++ "docs/" ++ name ++ ".png");
		image.free;
		window.close;
		0.3.wait;
	};
	(here ++ "core/material-library.scd").load;
	(here ++ "core/fader-specs.scd").load;
	(here ++ "core/ndef-faders.scd").load;
	(here ++ "core/ndef-curves.scd").load;
	(here ++ "core/preset-morph.scd").load;
	~presets = ~loadPresets.(here ++ "core/presets.scd");
	shot.("faders", { ~ndefFaders.(~gen.(\gorse), ~specs[\gorse], presets: ~presets[\gorse]).window });
	shot.("morph", { ~presetMorph.(~gen.(\gorse), ~presets[\gorse], ~specs[\gorse]).window });
	shot.("curves", {
		var c = ~ndefCurves.(~gen.(\sedge), ~specs[\sedge], presets: ~presets[\sedge]);
		c[\rows].do { |r, i|
			r[\msv].value = Array.fill(512, { |k| (0.5 + (0.4 * sin((k / 512) * 2pi * (1 + (i % 3)) + i))).clip(0, 1) });
		};
		c.window
	});
	0.exit;
}).play(AppClock);
)
