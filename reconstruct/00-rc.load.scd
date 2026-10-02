// 00-rc.load.scd
// The synthesis material as three buffer dictionaries.
//
//   ~gmscombined[\yarrow06]       the four channels mixed down, one per take
//   ~gmsstereo['yarrow06-12']     the two stereo pairs
//   ~gmsmono['yarrow06-1']        the four channels on their own
//
// Keys are the file names, so a hyphen means the key needs quoting. All three
// sets loaded at once is about 2.9 GB of server memory, so ~rcfamilies filters
// by family. Waveset and spatial work wants ~gmsmono; the montage reads
// ~gmscombined. Evaluate block 1 and wait for the count to post.

( // 1. boot, define, load. The only block that has to run.
~rcpath = PathName(thisProcess.nowExecutingPath).pathOnly ++ "../material/synthesis/";
~rcfamilies = [\clover, \nettle, \yarrow];            // nil takes all 62 takes, 2.9 GB

s.waitForBoot({
	Routine({
		~gmscombined = ();
		~gmsstereo = ();
		~gmsmono = ();

		~rcfamily = { |key| key.asString.select(_.isAlpha).asSymbol };
		~rckeys = { |dict| dict.keys.asArray.sort };

		~rcinfo = {
			var all = [~gmscombined, ~gmsstereo, ~gmsmono];
			var mb = all.sum { |d| d.values.sum { |b| b.numFrames * b.numChannels * 4 } } / 1048576;
			"combined % / stereo % / mono %, % MB in the server".format(
				~gmscombined.size, ~gmsstereo.size, ~gmsmono.size, mb.round(0.1)).postln;
		};

		// the blocking loader: reads, then waits for the server to catch up
		~rcread = { |families|
			[[\combined, ~gmscombined], [\stereo, ~gmsstereo], [\mono, ~gmsmono]].do { |pair|
				var dir, dict;
				# dir, dict = pair;
				PathName(~rcpath ++ dir).files.do { |f|
					var key = f.fileNameWithoutExtension.asSymbol;
					if(f.extension == "wav" and: {
						families.isNil or: { families.asArray.includes(~rcfamily.(key)) }
					}) {
						dict[key] = Buffer.read(s, f.fullPath);
					};
				};
			};
			s.sync;
			~rcinfo.();
		};

		// the same thing from a plain evaluation later on
		~rcload = { |families| { ~rcread.(families) }.fork };

		~rcfree = {
			[~gmscombined, ~gmsstereo, ~gmsmono].do { |d| d.values.do(_.free); d.clear };
		};

		~rctakes = { ~rckeys.(~gmscombined) };
		~rcfam = { |fam, dict| ~rckeys.(dict ? ~gmscombined).select { |k| ~rcfamily.(k) == fam } };
		~rcpair = { |take, pair| ~gmsstereo[(take.asString ++ "-" ++ pair).asSymbol] };
		~rcch = { |take, ch| ~gmsmono[(take.asString ++ "-" ++ ch).asSymbol] };
		~rcbufs = { |dict| ~rckeys.(dict).collect { |k| dict[k] } };

		~rcread.(~rcfamilies);
		("takes: " ++ ~rctakes.()).postln;
	}).play;
});
)


// what is loaded
~rctakes.()
~rcfam.(\yarrow)
~rckeys.(~gmsmono)

// one take, four ways
~gmscombined[\clover01].play
~rcpair.(\yarrow06, 12).play
~rcch.(\yarrow06, 3).play
~rcch.(\yarrow06, 3).plot


( // 2. proof of life: the four mono channels of one take, side by side
{
	var take = \yarrow06;
	var sig = (1..4).collect { |ch| PlayBuf.ar(1, ~rcch.(take, ch), loop: 1) };
	Splay.ar(sig) * 0.4
}.play
)

CmdPeriod.run


// a second family later on, without disturbing what is already loaded
~rcload.([\thistle])

// ~rcfree.()
