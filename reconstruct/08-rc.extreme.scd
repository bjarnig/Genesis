// 08-rc.extreme.scd
// nettle06 pushed hard. Run 00-rc.load.scd first, then block 1 here.
//
// nettle06 is the most tonal material in the set: spectral flatness 0.004, a
// wavecycle of 74 samples (649 Hz) holding steady across all four channels,
// crest 3 to 4. Well-defined cycles are exactly what the waveset processes
// need, so the ratio operations bite much harder here than on the noisy
// families, and the numbers below are far past what 07-rc.cdp.scd uses.
//
// A recipe is a list of stages. One stage is [program, parameters], and each
// stage reads what the one before it wrote, so the chains are where the real
// damage happens: a 30 to 1 contraction followed by a 12 to 1 re-stretch does
// not return the material, it returns what survived the round trip.

( // 1. settings and source
~xdir = "/Users/bjarni/Works/Pieces/Genesis/material/synthesis/extreme/";
~xout = ~xdir ++ "out/";
~xsecs = 15;
~xtakes = [\nettle06];
~xchans = [1, 3];
~cdpbin = "/Users/bjarni/cdpr8/_cdp/_cdprogs";
CDPBase.setCDPPath(~cdpbin);
)


( // 2. the excerpts, written straight from the loaded buffers
Routine({
	File.mkdir(~xdir.withoutTrailingSlash);
	File.mkdir(~xout.withoutTrailingSlash);
	~xtakes.do { |take|
		~xchans.do { |ch|
			var src = ~rcch.(take, ch);
			var frames = min(~xsecs * src.sampleRate, src.numFrames);
			var slice = Buffer.alloc(s, frames, 1);
			s.sync;
			src.copyData(slice, 0, 0, frames);
			s.sync;
			slice.write(~xdir ++ take.asString ++ "-" ++ ch ++ ".wav", "wav", "int24");
			s.sync;
			slice.free;
		};
	};
	s.sync;
	("excerpts: " ++ PathName(~xdir).files.collect(_.fileName)).postln;
}).play;
)


( // 3. the recipes. Single operations first, pushed to the edge of their
  //    ranges, then the chains.
~xrecipes = [
	// one operation, as far as it goes
	[\erase,      [["distort delete 1",   "40"]]],                    // one cycle in forty
	[\blip,       [["distort telescope",  "40 -a"]]],                 // forty collapsed into one
	[\stretch16,  [["distort repeat",     "16 -c1"]]],
	[\deepdivide, [["distort divide",     "12"]]],
	[\up16,       [["distort multiply",   "16 -s"]]],
	[\clicks,     [["distort reform 6",   ""]]],                      // click stream
	[\square,     [["distort reform 2",   ""]]],
	[\halfcycle,  [["distort reform 5",   ""]]],                      // inverted half-cycles
	[\fractal60,  [["distort fractal",    "60 0.6"]]],
	[\octavewarp, [["distort pitch",      "8.0 -c2"]]],            // octvary tops out at 8
	[\gutted,     [["distort omit",       "31 32"]]],                 // all but one in thirty-two
	[\buzz,       [["distort envel 3",    "2 0.0 -e12"]]],            // two cycles per envelope

	// chains: each stage reads the one before
	[\roundtrip,  [["distort telescope",  "30 -a"],
	               ["distort repeat",     "12 -c1"],
	               ["distort overload 1", "0.3 0.95"]]],
	[\clickcloud, [["distort reform 6",   ""],
	               ["distort repeat",     "8 -c2"],
	               ["distort envel 3",    "12 0.0 -e3"]]],
	[\wrecked,    [["distort divide",     "8"],
	               ["distort shuffle",    "abcd-aaaaaaddddddaaaaaa -c4"],
	               ["distort multiply",   "8 -s"]]],
	[\sieve,      [["distort delete 1",   "20"],
	               ["distort fractal",    "60 0.6"],
	               ["distort pitch",      "1.0 -c4"]]],
	[\compound,   [["distort fractal",    "40 0.5"],
	               ["distort fractal",    "40 0.5"],
	               ["distort fractal",    "40 0.5"]]],               // the same insult, thrice
	[\grind,      [["distort telescope",  "16"],
	               ["distort reform 2",   ""],
	               ["distort repeat",     "10 -c1"],
	               ["distort omit",       "3 4"]]]
];
)


( // 4. run them. Intermediate stages are kept as _s1, _s2 so a chain can be
  //    unpicked when one stage turns out to be the interesting one.
Routine({
	var srcs = PathName(~xdir).files.select { |f| f.extension == "wav" };
	var made = 0, failed = 0;
	srcs.do { |src|
		var stem = src.fileNameWithoutExtension;
		~xrecipes.do { |pair|
			var name, stages, input;
			# name, stages = pair;
			input = src.fullPath;
			stages.do { |st, i|
				var prog, params, last, out;
				# prog, params = st;
				last = i == (stages.size - 1);
				out = ~xout ++ stem ++ "_" ++ name
					++ if(last, "", "_s" ++ (i + 1)) ++ ".wav";
				if(CDPBase.cdpRunnerSync(prog, input, out, params) == 0) {
					input = out;
					if(last) { made = made + 1 };
				} {
					("FAILED " ++ stem ++ " " ++ name ++ " stage " ++ (i + 1) ++ ": " ++ prog).postln;
					failed = failed + 1;
				};
			};
		};
	};
	("### % recipes written, % stages failed".format(made, failed)).postln;
}).play;
)


( // 5. hear them
Routine({
	~xbufs = ();
	PathName(~xout).files.do { |f|
		if(f.extension == "wav" and: { f.fileName.contains("_s").not }) {
			~xbufs[f.fileNameWithoutExtension.asSymbol] = Buffer.read(s, f.fullPath);
		};
	};
	s.sync;
	~xkeys = ~xbufs.keys.asArray.sort;
	("% results".format(~xkeys.size)).postln;
}).play;
)

~xbufs[~xkeys.choose].play

( // 6. every result in turn
Tdef(\xtour, {
	~xkeys.do { |k|
		var b = ~xbufs[k];
		("% : % s".format(k, b.duration.round(0.1))).postln;
		{ PlayBuf.ar(1, b, BufRateScale.kr(b), doneAction: 2) ! 2 * 0.5 }.play;
		(min(b.duration, 12) + 0.3).wait;
	};
}).play;
)

Tdef(\xtour).stop; CmdPeriod.run
