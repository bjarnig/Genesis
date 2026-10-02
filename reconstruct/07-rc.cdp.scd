// 07-rc.cdp.scd
// CDP batch processing over a subset of the mono material.
// Run 00-rc.load.scd first (block 2 needs the loaded buffers).
//
// The waveset processes are the point: delete, repeat and envel, plus the
// neighbours that work on the same units (omit, reverse, telescope, average).
// A wavecycle here is the stretch between zero crossings, so every parameter
// below counts cycles, not seconds.
//
//   distort delete MODE in out cyclecnt         1 keep one, 2 keep strongest, 3 drop weakest
//   distort repeat in out multiplier -cN -sN    repeats each group: it stretches
//   distort envel 1|2 in out cyclecnt -t -e     rising / falling envelope per group
//   distort envel 3 in out cyclecnt troughing   troughed, cyclecnt may be a breakpoint file
//   distort envel 4 in out envfile cyclecnt     envelope read from a breakpoint file
//
// CDP works on mono files only, which is what material/synthesis/mono holds.
// Everything lands in <work dir>/batch_output/.
//
// Blocks 17 to 20 work from groups.scd, which Tools/genesis-corpus/group-material.py
// writes: four groups of five mono files, clustered by timbre, each group handed
// the process family its measurements suit.
//
// Batch system: the CDP quark in downloaded-quarks/CDP (see BATCH_README.md).

( // 1. settings
~cdpsrc = "/Users/bjarni/Works/Pieces/Genesis/material/synthesis/mono/";
~cdpwork = "/Users/bjarni/Works/Pieces/Genesis/material/synthesis/cdp/";
~cdpout = ~cdpwork ++ "batch_output/";

~cdptakes = [\yarrow06, \gorse04];     // which takes go into the subset
~cdpchans = [1, 3];                    // which channels of each
~cdpsecs = 10;                         // 0 copies the whole 50 seconds

// CDP lives here, and the brk files ship with the quark. CDPBatchEnvel looks
// for them under Extensions/CDP, which is wrong when CDP is a quark, so the
// envel blocks below point at the quark and write their own besides.
~cdpbin = "/Users/bjarni/cdpr8/_cdp/_cdprogs";
~cdpbrk = Platform.userAppSupportDir +/+ "downloaded-quarks/CDP/CDP.js/processes/envel/brk/";
)


( // 2. the subset: mono files copied out, optionally as a head excerpt
Routine({
	var made = 0;
	File.mkdir(~cdpwork.withoutTrailingSlash);

	~cdptakes.do { |take|
		~cdpchans.do { |ch|
			var src = ~rcch.(take, ch);
			var name = take.asString ++ "-" ++ ch;
			var out = ~cdpwork ++ name ++ ".wav";
			if(src.isNil) {
				("missing: " ++ name).postln;
			} {
				if(~cdpsecs > 0) {
					var frames = min(~cdpsecs * src.sampleRate, src.numFrames);
					var slice = Buffer.alloc(s, frames, 1);
					s.sync;
					src.copyData(slice, 0, 0, frames);
					s.sync;
					slice.write(out, "wav", "int24");
					s.sync;
					slice.free;
				} {
					File.copy(src.path, out);
				};
				made = made + 1;
			};
		};
	};
	s.sync;
	("subset: % files in %".format(made, ~cdpwork)).postln;
	PathName(~cdpwork).files.do { |f| ("  " ++ f.fileName).postln };
}).play;
)


( // 3. is CDP reachable? Set the path explicitly: the runner otherwise depends
  //    on a login shell picking it up. The check only finds the file, it never
  //    runs it, so it says true for an x86_64 build on an arm64 machine. That
  //    case surfaces later as exit code 127, which the runner reports as "not
  //    in PATH" when the shell actually said "bad CPU type in executable".
CDPBase.setCDPPath(~cdpbin);
CDPBase.checkCDPInstalled;
)


///////////////////////// The waveset batch /////////////////////////

( // 4. delete, repeat and the neighbours. Cycle counts are integers, and
  //    rrange returns a float even at 0 decimals, so these go through custom
  //    with asInteger rather than through ranges.
CDPBatch.custom(~cdpwork, 1, [
	// keep the strongest wavecycle of every group: a time contraction that
	// holds on to the loudest features
	["distort delete 2", { |b| b.rrange(4, 12).asInteger.asString }, "_delete"],

	// repeat each group: the opposite direction, a stretch with grain in it
	["distort repeat", { |b|
		b.rrange(2, 6).asInteger.asString + "-c8"
	}, "_repeat"],

	// silence some of every group, keeping the timing. A must stay under B.
	["distort omit", { |b|
		b.rrange(1, 3).asInteger.asString + b.rrange(5, 9).asInteger.asString
	}, "_omit"],

	// reverse groups while the file still runs forwards
	["distort reverse", { |b| b.rrange(3, 24).asInteger.asString }, "_reverse"],

	// collapse groups into one cycle: a hard contraction
	["distort telescope", { |b| b.rrange(4, 16).asInteger.asString }, "_telescope"],

	// average the waveshape over a group: smoother, quieter
	["distort average", { |b| b.rrange(12, 80).asInteger.asString }, "_average"]
]);
)


( // 5. the same three with parameters written out, when a range is not enough.
  //    -c is the group size, -s skips cycles at the head of the file.
CDPBatch.custom(~cdpwork, 1, [
	["distort delete 1", { |b| b.rrange(6, 20).asInteger.asString }, "_delete1"],
	["distort delete 3", { |b| b.rrange(3, 10).asInteger.asString }, "_delete3"],
	["distort repeat", { |b|
		b.rrange(3, 8).asInteger.asString + "-c" ++ b.rrange(2, 40).asInteger.asString
			+ "-s" ++ b.rrange(0, 200).asInteger.asString
	}, "_repeatlong"]
]);
)


///////////////////////// Envelope per group /////////////////////////

( // 6. envel 1 and 2: a rising and a falling envelope imposed on every group
  //    of cyclecnt wavecycles. Small groups buzz, large groups pulse.
CDPBatch.custom(~cdpwork, 1, [
	["distort envel 1", { |b|
		b.rrange(20, 200).asInteger.asString + "-t" ++ b.rrange(0, 0.4, 2).asString
			+ "-e" ++ b.rrange(0.3, 3.0, 1).asString
	}, "_envrise"],
	["distort envel 2", { |b|
		b.rrange(20, 200).asInteger.asString + "-t" ++ b.rrange(0, 0.4, 2).asString
			+ "-e" ++ b.rrange(0.3, 3.0, 1).asString
	}, "_envfall"]
]);
)


( // 7. envel 3, troughed, with cyclecnt read from a breakpoint file: the group
  //    size changes as the file runs, so the pulsation speeds up or slows down
CDPBatch.custom(~cdpwork, 1, [
	["distort envel 3", { |b|
		(~cdpbrk ++ "trema.txt") + b.rrange(0.005, 0.02, 3).asString
			+ "-e" ++ b.rrange(0.3, 0.7, 1).asString
	}, "_trema"],
	["distort envel 3", { |b|
		(~cdpbrk ++ "tremc.txt") + b.rrange(0.18, 0.28, 3).asString
			+ "-e" ++ b.rrange(1.5, 2.5, 1).asString
	}, "_tremc"],
	["distort envel 3", { |b|
		(~cdpbrk ++ "tremg.txt") + b.rrange(0.38, 0.48, 3).asString
			+ "-e" ++ b.rrange(28, 36).asInteger.asString
	}, "_tremg"]
]);
)


( // 8. breakpoint files of our own, written to span the whole subset duration.
  //    The ones in the quark stop at 10 to 22 seconds; a longer take runs off
  //    the end of them.
// cyclecnt in a breakpoint file is a count, so these are written as integers
~cdpbrkWrite = { |name, pairs|
	var path = ~cdpwork ++ name;
	var f = File(path, "w");
	pairs.do { |p| f.write("% %\n".format(p[0], p[1])) };
	f.close;
	path
};

~cdpdur = ~cdpsecs.max(1);

~brkSlow = ~cdpbrkWrite.("brk-slow.txt",
	(0, 0.25 .. 1).collect { |x| [(x * ~cdpdur).round(0.001), (20 + (x * 180)).asInteger] });
~brkFast = ~cdpbrkWrite.("brk-fast.txt",
	(0, 0.2 .. 1).collect { |x| [(x * ~cdpdur).round(0.001), (600 - (x * 560)).asInteger] });
~brkSwing = ~cdpbrkWrite.("brk-swing.txt",
	(0, 0.1 .. 1).collect { |x| [(x * ~cdpdur).round(0.001), (60 + (sin(x * 6pi) * 55)).asInteger] });

[~brkSlow, ~brkFast, ~brkSwing].do { |p| (p ++ "\n" ++ File.readAllString(p)).postln };
)


( // 9. the same envel 3, driven by those: group size climbing, falling, swinging
CDPBatch.custom(~cdpwork, 1, [
	["distort envel 3", { |b| ~brkSlow + b.rrange(0.02, 0.2, 3).asString + "-e1.0" }, "_envslow"],
	["distort envel 3", { |b| ~brkFast + b.rrange(0.02, 0.2, 3).asString + "-e0.5" }, "_envfast"],
	["distort envel 3", { |b| ~brkSwing + b.rrange(0.02, 0.2, 3).asString + "-e2.0" }, "_envswing"]
]);
)


( // 10. envel 4: the envelope itself comes from a file, time/value pairs
  //     between 0 and 1, stretched over each group
~envPerc = ~cdpbrkWrite.("env-perc.txt", [[0, 0], [0.05, 1], [0.3, 0.25], [1, 0]]);
~envSwell = ~cdpbrkWrite.("env-swell.txt", [[0, 0], [0.5, 1], [1, 0]]);
~envGate = ~cdpbrkWrite.("env-gate.txt", [[0, 1], [0.4, 1], [0.41, 0], [1, 0]]);

CDPBatch.custom(~cdpwork, 1, [
	["distort envel 4", { |b| ~envPerc + b.rrange(30, 300).asInteger.asString }, "_env4perc"],
	["distort envel 4", { |b| ~envSwell + b.rrange(30, 300).asInteger.asString }, "_env4swell"],
	["distort envel 4", { |b| ~envGate + b.rrange(30, 300).asInteger.asString }, "_env4gate"]
]);
)


///////////////////////// Chains /////////////////////////

( // 11. two passes: the second works on what the first made, so delete meets
  //     repeat and the file is contracted and stretched in turn
CDPBatch.custom(~cdpwork, 1, [
	["distort delete 2", { |b| b.rrange(4, 10).asInteger.asString }, "_d"],
	["distort repeat", { |b| b.rrange(2, 4).asInteger.asString + "-c6" }, "_r"]
], passes: 2);
)


( // 12. by hand, one take through a chain of three, each stage named
Routine({
	var name = ~cdptakes.first.asString ++ "-" ++ ~cdpchans.first;
	var a = ~cdpout ++ name ++ "_chain1.wav";
	var b = ~cdpout ++ name ++ "_chain2.wav";
	var c = ~cdpout ++ name ++ "_chain3.wav";
	File.mkdir(~cdpout.withoutTrailingSlash);
	CDPBase.cdpRunnerSync("distort delete 2", ~cdpwork ++ name ++ ".wav", a, "6");
	CDPBase.cdpRunnerSync("distort envel 3", a, b, ~brkSwing + "0.05 -e1.5");
	CDPBase.cdpRunnerSync("distort repeat", b, c, "3 -c12");
	("chain done: " ++ c).postln;
}).play;
)


///////////////////////// Back into SuperCollider /////////////////////////

( // 13. read the subset and the results back in, each in its own dictionary
Routine({
	~gmscdpsrc = ();
	~gmscdp = ();
	PathName(~cdpwork).files.do { |f|
		if(f.extension == "wav") {
			~gmscdpsrc[f.fileNameWithoutExtension.asSymbol] = Buffer.read(s, f.fullPath);
		};
	};
	if(File.exists(~cdpout.withoutTrailingSlash)) {
		PathName(~cdpout).files.do { |f|
			if(f.extension == "wav") {
				~gmscdp[f.fileNameWithoutExtension.asSymbol] = Buffer.read(s, f.fullPath);
			};
		};
	};
	s.sync;
	~cdpkeys = ~gmscdp.keys.asArray.sort;
	("subset % / results %".format(~gmscdpsrc.size, ~gmscdp.size)).postln;
	~cdpkeys.do { |k| ("  " ++ k).postln };
}).play;
)

~gmscdp[~cdpkeys.choose].play


( // 14. the source against one result, left and right
{
	var name = (~cdptakes.first.asString ++ "-" ++ ~cdpchans.first).asSymbol;
	var src = ~gmscdpsrc[name];
	var out = ~gmscdp[~cdpkeys.detect { |k| k.asString.beginsWith(name.asString) }];
	Pan2.ar(PlayBuf.ar(1, src, BufRateScale.kr(src), loop: 1), -1, 0.5)
		+ Pan2.ar(PlayBuf.ar(1, out, BufRateScale.kr(out), loop: 1), 1, 0.5)
}.play
)


( // 15. every result in turn, posting what made it
Tdef(\rccdp, {
	~cdpkeys.do { |k|
		var b = ~gmscdp[k];
		k.postln;
		{ PlayBuf.ar(1, b, BufRateScale.kr(b), doneAction: 2) ! 2 * 0.6 }.play;
		(b.duration + 0.3).wait;
	};
}).play;
)

Tdef(\rccdp).stop; CmdPeriod.run


( // 16. the results as a corpus: hand them to 05 and slice them
~rcdict = ~gmscdp;     // then run blocks 2 and 3 of 05-rc.flucoma.scd
)


///////////////////////// The measured groups /////////////////////////

( // 17. the groups, and a parameter per process.
  //
  //     cyclecnt means two different things and they must not be mixed up.
  //     For envel and reverse it is a SPAN: how many wavecycles pass under one
  //     envelope, or get reversed together, so it belongs in milliseconds and
  //     comes from the group's own measurement. For delete, omit, telescope,
  //     average and the multipliers it is a RATIO: the file contracts or
  //     stretches by that factor, so it stays a small integer whatever the
  //     material is. Sizing a ratio in milliseconds gives delete a cyclecnt of
  //     240 and a file 240 times shorter.
(~cdpwork ++ "groups.scd").load;

// distort harmonic reads harmonic_number/amplitude pairs from a file
~cdpharm = ~cdpbrkWrite.("harmonics.txt", [[2, 0.5], [3, 0.25], [5, 0.12], [7, 0.06]]);

~cdpparams = (
	// spans, measured from the group's own wavecycle length
	'distort envel 1':          { |g| g[\cyclecnt][\ms120].asString + "-t0.2 -e1.5" },
	'distort envel 2':          { |g| g[\cyclecnt][\ms120].asString + "-t0.2 -e0.6" },
	'distort envel 3':          { |g| g[\cyclecnt][\ms30].asString + "0.05 -e1.5" },
	'distort reverse':          { |g| g[\cyclecnt][\ms30].asString },
	'distort shuffle':          { |g|
		["abcd-aacccbdd", "abcd-dcba", "abc-acbabc", "abcd-dac"].choose
			+ "-c" ++ g[\cyclecnt][\ms8].asString },
	'distshift distshift 1':    { |g| g[\cyclecnt][\ms8].asString + rrand(1, 4).asString },

	// frequencies, measured: the group's own median cycle frequency is the
	// hinge, so the filter and the limit sit in the middle of the material
	'distort filter 1':         { |g| g[\cycHz].round.asInteger.asString + "-s0" },
	// -f has a floor of 440 Hz, whatever the group's own rate is
	'distort replim':           { |g| rrand(2, 6).asString + "-c" ++ g[\cyclecnt][\ms30].asString
		+ "-f" ++ max(440, g[\cycHz].round).asInteger.asString },

	// ratios, held small whatever the material
	'distort delete 2':         { |g| rrand(4, 10).asString },
	'distort omit':             { |g| rrand(1, 3).asString + rrand(5, 9).asString },
	'distort telescope':        { |g| rrand(4, 16).asString },
	'distort average':          { |g| rrand(12, 60).asString },
	'distort interpolate':      { |g| rrand(2, 8).asString },
	'distort divide':           { |g| rrand(2, 8).asString },
	'distort multiply':         { |g| rrand(2, 16).asString + "-s" },
	'distort repeat':           { |g| rrand(2, 4).asString + "-c" ++ g[\cyclecnt][\ms30].asString },
	// its cycle search overruns on long wavecycles: clover05-3 fails at -c4
	// whatever the multiplier, while shorter-cycle material takes -c6 happily.
	// So the group size follows the measurement rather than the clock.
	'distort repeat2':          { |g| rrand(2, 5).asString
		+ "-c" ++ if(g[\cycMedian] > 150, 2, min(8, g[\cyclecnt][\ms30])).asString },
	'distwarp distwarp 1':      { |g| rrand(1.5, 6.0).round(0.01).asString },

	// shapes and amounts
	'distort pitch':            { |g| rrand(0.1, 0.8).round(0.01).asString
		+ "-c" ++ g[\cyclecnt][\ms8].asString },
	'distort reform 1':         { |g| "" },                      // modes 1-7 take no parameter
	'distort fractal':          { |g| rrand(4, 60).asString + rrand(0.1, 0.6).round(0.01).asString },
	// clip-level is also the output ceiling, so a small value returns a file
	// 30 dB down: 0.02 measured -34 dBFS peak, 0.5 measured -9.5
	'distort overload 1':       { |g| rrand(0.15, 0.6).round(0.01).asString
		+ rrand(0.8, 0.99).round(0.01).asString },
	'distort harmonic':         { |g| ~cdpharm + "-p0.5" },
	// minseglen has a floor of 0.031 s
	'extend scramble 1':        { |g| rrand(0.04, 0.12).round(0.001).asString
		+ rrand(0.2, 0.5).round(0.01).asString + ~cdpsecs.asString }
);

~cdpgroups.keysValuesDo { |name, g|
	("% : % files, wavecycle % samp (% Hz)".format(
		name, g[\files].size, g[\cycMedian], g[\cycHz])).postln;
	("   " ++ g[\why]).postln;
	g[\processes].do { |proc|
		("   " ++ proc ++ "  ->  " ++ ~cdpparams[proc.asSymbol].(g)).postln;
	};
};
)


( // 18. hear a group before processing it: its five files in turn
~cdpplay = { |name|
	var g = ~cdpgroups[name];
	Tdef(\rccdpgroup, {
		g[\files].do { |f|
			var b = Buffer.read(s, g[\folder] ++ f ++ ".wav");
			s.sync;
			("  " ++ f).postln;
			{ PlayBuf.ar(1, b, BufRateScale.kr(b), doneAction: 2) ! 2 * 0.6 }.play;
			(b.duration + 0.2).wait;
			b.free;
		};
	}).play;
};
)

~cdpplay.(\thin)
~cdpplay.(\shape)
~cdpplay.(\smear)
~cdpplay.(\stretch)


( // 19. run every group: each folder through its own processes, into its own
  //     batch_output
~cdpgroups.keysValuesDo { |name, g|
	("=== " ++ name).postln;
	CDPBatch.custom(g[\folder], 1,
		g[\processes].collect { |proc|
			[proc, { |b| ~cdpparams[proc.asSymbol].(g) }, "_" ++ proc.split($ ).drop(1).join]
		}
	);
};
)


( // 20. one group only, when a family is worth pushing on its own
var name = \shape;
var g = ~cdpgroups[name];
CDPBatch.custom(g[\folder], 1,
	g[\processes].collect { |proc|
		[proc, { |b| ~cdpparams[proc.asSymbol].(g) }, "_" ++ proc.split($ ).drop(1).join]
	},
	passes: 2
);
)
