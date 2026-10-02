// 05-rc.flucoma.scd
// The material as a corpus. Run 00-rc.load.scd first.
//
// The mono buffers are copied end to end into one long buffer, which is then
// cut into events wherever the sound changes. Every slice keeps the take it
// came from, so the question "which process does this slice belong to" has an
// answer: ~sliceTake.(i). Descriptors are 12 MFCC means per slice, and
// everything after that is a way of asking the corpus about itself: what
// sounds like this, what does the whole thing look like, what groups are in
// it, what is typical and what is singular.
//
// Modelled on the archive patches in Courses/Students/Victoria/Archives.
// The corpus is as big as the families ~rcfamilies loaded, so slice a small
// set while working.

( // 1. settings
~rcdict = ~gmsmono;      // which dictionary becomes the corpus
~rcthreshold = 0.5;      // slicing sensitivity: lower cuts more often
~rcminLength = 10;       // shortest slice, in analysis frames
~rcneighbours = 5;       // how many look-alikes a search returns
~rcgroups = 6;           // how many groups to sort the corpus into
~rcumapN = 15;           // UMAP zoom: small is local clumps, large is the big picture
)


( // 2. build the corpus: every buffer laid end to end, with an index of origins
Routine({
	var keys = ~rckeys.(~rcdict);
	var frames = keys.collect { |k| ~rcdict[k].numFrames };
	var at = 0;

	~corpus = Buffer.alloc(s, frames.sum, 1);
	s.sync;

	~origins = keys.collect { |k, i|
		var entry = [k, at, at + frames[i]];
		~rcdict[k].copyData(~corpus, at, 0, frames[i]);
		at = at + frames[i];
		entry
	};
	s.sync;

	// which take a frame position belongs to
	~takeAt = { |frame|
		var hit = ~origins.detect { |o| (frame >= o[1]) and: { frame < o[2] } };
		if(hit.notNil) { hit[0] } { \unknown }
	};

	"corpus: % takes, % minutes".format(keys.size,
		(~corpus.numFrames / ~corpus.sampleRate / 60).round(0.1)).postln;
}).play;
)


( // 3. cut it into events
Routine({
	~indices = Buffer.alloc(s, 1);
	FluidBufNoveltySlice.processBlocking(s, ~corpus,
		indices: ~indices,
		algorithm: \mfcc,
		threshold: ~rcthreshold,
		minSliceLength: ~rcminLength);
	s.sync;
	~indices.loadToFloatArray(action: { |arr|
		// the slicer returns -1 where it finds no boundary
		~slices = ([0] ++ arr.select { |x| (x > 0) and: { x < ~corpus.numFrames } })
			.add(~corpus.numFrames);
		~numSlices = ~slices.size - 1;
		("% slices".format(~numSlices)).postln;
	});
}).play;
)


( // 4. one slice by its number, and where it came from
~playSlice = { |i, amp = 0.5, rate = 1, pan = 0|
	var start = ~slices[i];
	var dur = (~slices[i + 1] - start) / ~corpus.sampleRate;
	{
		var sig = PlayBuf.ar(1, ~corpus, rate * BufRateScale.kr(~corpus), startPos: start);
		var env = EnvGen.kr(Env([0, 1, 1, 0], [0.01, max(dur - 0.02, 0.01), 0.01]),
			doneAction: 2);
		Pan2.ar(sig * env * amp, pan)
	}.play;
};

~sliceTake = { |i| ~takeAt.(~slices[i]) };
~sliceDur = { |i| (~slices[i + 1] - ~slices[i]) / ~corpus.sampleRate };
)

~playSlice.(0)
~playSlice.(~numSlices.rand)
~sliceTake.(~numSlices.rand)

// see the cuts drawn over the whole corpus
FluidWaveform(~corpus, ~indices, bounds: Rect(0, 0, 1200, 300))


( // 5. the corpus end to end, slice after slice, posting the take as it crosses
Tdef(\rctour, {
	~numSlices.do { |i|
		("% %".format(i, ~sliceTake.(i))).postln;
		~playSlice.(i, 0.6);
		(~sliceDur.(i) + 0.1).wait;
	};
}).play(AppClock);
)

Tdef(\rctour).stop


( // 6. shuffled: the order of the material dissolved
Pdef(\rcshuffle, Pbind(
	\type, \rest,
	\dur, Pwhite(0.15, 0.4),
	\callback, Pfunc({ ~playSlice.(~numSlices.rand, 0.6) })
)).play;
)

Pdef(\rcshuffle).stop


///////////////////////// Descriptors /////////////////////////

( // 7. a timbre fingerprint per slice: 13 MFCCs, drop the loudness one, average
Routine({
	var feat = Buffer.alloc(s, 1);
	var stat = Buffer.alloc(s, 1);
	var point = Buffer.alloc(s, 1);

	~ds = FluidDataSet(s);
	~ids = [];
	~numSlices.do { |i|
		var start = ~slices[i], end = ~slices[i + 1];
		if((end - start) >= 1024) {              // shorter than the FFT window: skip
			FluidBufMFCC.processBlocking(s, ~corpus,
				startFrame: start, numFrames: end - start,
				features: feat, numCoeffs: 13, startCoeff: 1);
			FluidBufStats.processBlocking(s, feat, stats: stat, numChans: 12);
			FluidBufFlatten.processBlocking(s, stat, numFrames: 1, destination: point);
			~ds.addPoint(i.asString, point);
			~ids = ~ids.add(i);
		};
	};
	s.sync;
	("described % slices".format(~ids.size)).postln;
}).play;
)


( // 8. a search tree over the fingerprints, normalised so each counts equally
~norm = FluidNormalize(s);
~dsNorm = FluidDataSet(s);
~tree = FluidKDTree(s);
~norm.fitTransform(~ds, ~dsNorm, {
	~tree.fit(~dsNorm, { "tree ready".postln });
	~dsNorm.dump({ |d| ~points = d["data"] });
});
)


( // 9. what sounds like this? The question, then the answers.
~findSimilar = { |i, howMany|
	var query = Buffer.alloc(s, 12);
	howMany = howMany ? ~rcneighbours;
	~dsNorm.getPoint(i.asString, query, {
		~tree.kNearest(query, howMany + 1, { |ids|
			var found = ids.asArray.collect(_.asInteger).reject { |x| x == i }.keep(howMany);
			("% (%) sounds like %".format(i, ~sliceTake.(i),
				found.collect { |j| ~sliceTake.(j) })).postln;
			Routine({
				~playSlice.(i, 0.8);
				0.45.wait;
				found.do { |j| ~playSlice.(j, 0.5); 0.4.wait };
			}).play(AppClock);
		});
	});
};
)

~findSimilar.(~ids.choose)
~findSimilar.(~ids.choose, 8)


( // 10. browse: a new question every few seconds
Pdef(\rcbrowse, Pbind(
	\type, \rest,
	\dur, 3,
	\callback, Pfunc({ ~findSimilar.(~ids.choose) })
)).play;
)

Pdef(\rcbrowse).stop


///////////////////////// The map /////////////////////////

( // 11. 12 numbers down to 2, drawn as dots. Move the mouse over them.
Routine({
	~std = FluidStandardize(s);
	~dsStd = FluidDataSet(s);
	~umap = FluidUMAP(s, 2, min(~rcumapN, max(~ids.size - 1, 2)), 0.1);
	~mapNorm = FluidNormalize(s, 0, 1);
	~map = FluidDataSet(s);

	~nearest = { |x, y|
		var best, bestDist = inf;
		~mapPoints.keysValuesDo { |id, xy|
			var d = ((xy[0] - x).squared) + ((xy[1] - y).squared);
			if(d < bestDist) { bestDist = d; best = id };
		};
		best
	};

	~stepAt = { |x, y, amp = 0.6, rate = 1, pan = 0|
		var id = ~nearest.(x, y);
		if(id.notNil) {
			~playSlice.(id.asInteger, amp, rate, pan);
			~plotter !? { |p| { p.highlight_([id]) }.defer };
		};
	};

	~std.fitTransform(~ds, ~dsStd, {
		~umap.fitTransform(~dsStd, ~map, {
			~mapNorm.fitTransform(~map, ~map, {
				~map.dump({ |d|
					~mapPoints = d["data"];
					{
						~plotter = FluidPlotter(nil, Rect(50, 50, 760, 760), d,
							mouseMoveAction: { |view, x, y| ~stepAt.(x, y) });
					}.defer;
					("map ready, % points".format(~ids.size)).postln;
				});
			});
		});
	});
}).play;
)


( // 12. a slow circle over the map
Tdef(\rcpath, {
	var a = 0;
	loop {
		~stepAt.(0.5 + (cos(a) * 0.4), 0.5 + (sin(a) * 0.4));
		a = a + 0.15;
		0.18.wait;
	};
}).play(AppClock);
)

( // 13. three walkers at once, each with its own gait and register
Tdef(\rcwalkers, {
	var walkers = [
		[0.08, 0.13, 1.0, -0.6],
		[0.03, 0.31, 0.5, 0.0],
		[0.15, 0.07, 2.0, 0.6]
	];
	walkers.do { |w|
		var stepSize, wait, rate, pan;
		# stepSize, wait, rate, pan = w;
		Routine({
			var x = 0.5, y = 0.5;
			loop {
				x = (x + stepSize.rand2).clip(0, 1);
				y = (y + stepSize.rand2).clip(0, 1);
				~stepAt.(x, y, 0.4, rate, pan);
				wait.wait;
			};
		}).play(AppClock);
	};
}).play(AppClock);
)

Tdef(\rcpath).stop; Tdef(\rcwalkers).stop; CmdPeriod.run


///////////////////////// Groups /////////////////////////

( // 14. k-means: categories nobody named, and how they line up with the takes
~kmeans = FluidKMeans(s, ~rcgroups);
~labels = FluidLabelSet(s);
~kmeans.fitPredict(~dsStd, ~labels, {
	~labels.dump({ |ld|
		~groups = Array.fill(~rcgroups, { [] });
		~groupOf = ();
		ld["data"].keysValuesDo { |id, val|
			var g = val[0].asInteger;
			~groups[g] = ~groups[g].add(id.asInteger);
			~groupOf[id.asSymbol] = g;
		};
		if(~plotter.notNil) { { ~plotter.categories_(ld) }.defer };
		("groups: %".format(~groups.collect(_.size))).postln;
		~groups.do { |g, i|
			("  % : %".format(i, g.collect { |j| ~sliceTake.(j) }.as(Bag).contents)).postln;
		};
	});
});
)

( // 15. one group at a time
~playGroup = { |g, howMany = 10, gap = 0.4|
	Routine({
		~groups[g].scramble.keep(howMany).do { |i| ~playSlice.(i, 0.6); gap.wait };
	}).play(AppClock);
};
)

~playGroup.(0)
~playGroup.(~rcgroups.rand)


( // 16. each group becomes a layer, running at its own tempo
Tdef(\rclayers, {
	~rcgroups.do { |g|
		Routine({
			var wait = 0.2 * (g + 1);
			loop { ~playSlice.(~groups[g].choose, 0.35, 1, (g / (~rcgroups - 1) * 2) - 1); wait.wait };
		}).play(AppClock);
	};
}).play(AppClock);
)

Tdef(\rclayers).stop; CmdPeriod.run


///////////////////////// Typical and singular /////////////////////////

( // 17. the nearest slices, then the one that resembles nothing nearby
~distance = { |a, b| (a - b).squared.sum.sqrt };

~typicalAndSingular = { |i, howMany = 6|
	var here = ~points[i.asString];
	var ranked = ~ids.reject { |j| j == i }
		.collect { |j| [j, ~distance.(here, ~points[j.asString])] }
		.sort { |a, b| a[1] < b[1] };
	var typical = ranked.keep(howMany).collect(_[0]);
	var singular = ranked.last[0];

	("typical %  singular % (%)".format(typical, singular, ~sliceTake.(singular))).postln;
	Routine({
		~playSlice.(i, 0.8);
		0.5.wait;
		typical.do { |j| ~playSlice.(j, 0.4); 0.35.wait };
		0.8.wait;
		~playSlice.(singular, 0.85);
	}).play(AppClock);
};
)

~typicalAndSingular.(~ids.choose)


///////////////////////// Taking a take apart /////////////////////////

( // 18. one take pulled into three layers: what persists, what strikes,
  //     what flickers. A smooth take has nothing sharp in it, so ~flicker can
  //     come back empty: lower threshFwd if it does.
Routine({
	var src = ~rcch.(~rctakes.().first, 1);
	~rest = Buffer.alloc(s, 1);
	~flicker = Buffer.alloc(s, 1);
	~persist = Buffer.alloc(s, 1);
	~strike = Buffer.alloc(s, 1);
	s.sync;
	FluidBufTransients.processBlocking(s, src,
		transients: ~flicker, residual: ~rest, threshFwd: 1.5, threshBack: 1.1);
	FluidBufHPSS.processBlocking(s, ~rest,
		harmonic: ~persist, percussive: ~strike, harmFilterSize: 17, percFilterSize: 31);
	"three layers ready".postln;
}).play;
)

{ PlayBuf.ar(1, ~persist, BufRateScale.kr(~persist), doneAction: 2).dup * 0.8 }.play
{ PlayBuf.ar(1, ~strike, BufRateScale.kr(~strike), doneAction: 2).dup * 0.8 }.play
{ PlayBuf.ar(1, ~flicker, BufRateScale.kr(~flicker), doneAction: 2).dup * 0.8 }.play


( // 19. the three layers as three patterns, each on its own clock
SynthDef(\rclayer, { |buf, amp = 0.3, dur = 0.3, rate = 1, pan = 0|
	var pos = Rand(0, BufFrames.kr(buf) - (SampleRate.ir * dur));
	var sig = PlayBuf.ar(1, buf, rate * BufRateScale.kr(buf), startPos: pos);
	OffsetOut.ar(0, Pan2.ar(sig * EnvGen.kr(Env.sine(dur), doneAction: 2) * amp, pan));
}).add;
s.sync;

Pdef(\rcpersist, Pbind(\instrument, \rclayer, \buf, Pfunc({ ~persist }),
	\dur, Pwhite(0.3, 0.7), \rate, Pwhite(0.85, 1.15), \amp, 0.3, \pan, -0.4)).play;
Pdef(\rcstrike, Pbind(\instrument, \rclayer, \buf, Pfunc({ ~strike }),
	\dur, 0.125, \amp, Pseq([0.4, 0.15, 0.3, 0.2], inf), \pan, 0.4)).play;
Pdef(\rcflicker, Pbind(\instrument, \rclayer, \buf, Pfunc({ ~flicker }),
	\dur, Pwhite(0.05, 0.4), \rate, Prand([0.5, 1, 2], inf), \amp, 0.5, \pan, 0)).play;
)

[Pdef(\rcpersist), Pdef(\rcstrike), Pdef(\rcflicker)].do(_.stop)


( // 20. one take heard through another: the shape of the first, the palette
  //     of the second
Routine({
	var takes = ~rctakes.();
	var secs = 8;                                  // NMFCross is slow: cross excerpts
	var frames = s.sampleRate * secs;
	~shape = Buffer.alloc(s, frames, 1);
	~palette = Buffer.alloc(s, frames, 1);
	~memory = Buffer.alloc(s, 1);
	s.sync;
	~rcch.(takes[0], 1).copyData(~shape, 0, 0, frames);
	~rcch.(takes.last, 3).copyData(~palette, 0, 0, frames);
	1.wait;
	"crossing".postln;
	FluidBufNMFCross.processBlocking(s, ~palette, ~shape, ~memory,
		timeSparsity: 4, polyphony: 3, continuity: 20, windowSize: 2048,
		action: { "crossed".postln });
}).play;
)

{ PlayBuf.ar(1, ~memory, BufRateScale.kr(~memory), doneAction: 2).dup * 0.8 }.play

CmdPeriod.run
