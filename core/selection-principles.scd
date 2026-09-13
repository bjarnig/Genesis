// Koenig's six selection principles (SSP 1979, pp. 19-23), as value generators.
// Each returns an Array of N integers, ready for Dseq(arr, inf) into DemandEnvGen.
// Elements are indices into a list, exactly as SELECT and SEGMENT use them in SSP.

( // ALEA - N random values between A and Z, repetition unchecked
~alea = { |a, z, n|
	Array.fill(n, { rrand(a, z) });
};
);

( // SERIES - draw without replacement; refill the pool when it empties
~series = { |a, z, n|
	var pool = (a..z);
	var passes = (n / pool.size).ceil.max(1);
	// a fresh scramble per pass: Dshuf would reuse one shuffle for the whole stream
	Array.fill(passes, { pool.scramble }).flatten.keep(n);
};
);

( // RATIO - per-element weights; a drawn element's factor is spent, SUM refills at zero
~ratio = { |a, z, n, factors|
	var half = factors.copy;      // HALF in the original; RATCOP is the untouched copy
	var sum = half.sum;
	var out = Array.new(n);
	n.do {
		var x = 0, y;
		if(sum <= 0) { half = factors.copy; sum = half.sum };
		y = rrand(1, sum);
		while { y > 0 } { y = y - half[x]; x = x + 1 };
		x = x - 1;
		half[x] = half[x] - 1;
		sum = sum - 1;
		out = out.add(a + x);
	};
	out;
};
);

( // GROUP - values repeated in runs; TYPE crosses alea/series for value and run length
// Returns the drawn structure as [[value, length], ...]; ~group flattens it.
// Adjacent groups that draw the same value fuse into one longer run: these are the
// "pseudo-groups" of p. 75, and they are why observed runs can exceed LZ for types 1-2.
~groupPairs = { |a, z, n, type, la, lz|
	var vals = (a..z), lens = (la..lz);
	var valPool = vals.scramble, lenPool = lens.scramble;
	var nextVal, nextLen, pairs = Array.new, total = 0;
	// types 1-4: 1 alea/alea, 2 alea/series, 3 series/alea, 4 series/series
	nextVal = { if(type < 3) { vals.choose } {
		if(valPool.isEmpty) { valPool = vals.scramble }; valPool.pop } };
	nextLen = { if(type.even) {
		if(lenPool.isEmpty) { lenPool = lens.scramble }; lenPool.pop } { lens.choose } };
	while { total < n } {
		var v = nextVal.value, l = nextLen.value.min(n - total);   // last group truncates
		pairs = pairs.add([v, l]);
		total = total + l;
	};
	pairs;
};

~group = { |a, z, n, type, la, lz|
	~groupPairs.(a, z, n, type, la, lz).collect({ |p| Array.fill(p[1], p[0]) }).flatten;
};
);

( // SEQUENCE - the composer's own order; CHUNKS syntax "1,2,3,5*6,1-10"
~chunks = { |str|
	var out = Array.new;
	str.replace(" ", "").split($,).do { |c|
		case
		{ c.includes($*) } {                       // count*value
			var p = c.split($*);
			p[0].asInteger.do { out = out.add(p[1].asInteger) };
		}
		{ c.includes($-) } {                       // ascending or descending run
			var p = c.split($-), from = p[0].asInteger, to = p[1].asInteger;
			out = out ++ if(from <= to) { (from..to) } { (from, from-1 .. to) };
		}
		{ out = out.add(c.asInteger) };
	};
	out;
};

~seq = { |count, str|
	var arr = ~chunks.(str);
	if(arr.size != count) { "SEQ: counting error, % values for COUNT %".format(arr.size, count).warn };
	arr;
};
);

( // TENDENCY - masks whose edges drift; alea inside the moving window (p. 122)
~tend = { |n, masks|
	var out = Array.new(n);
	// masks: [[nn, a1, a2, z1, z2], ...]
	masks.do { |m|
		var nn = m[0], a1 = m[1], a2 = m[2], z1 = m[3], z2 = m[4];
		var s1 = (z1 - a1) / (nn - 1).max(1), s2 = (z2 - a2) / (nn - 1).max(1);
		var ss1 = 0, ss2 = 0;
		nn.do {
			var l1 = a1 + ss1.asInteger, l2 = a2 + ss2.asInteger;
			out = out.add(rrand(l1, l2));
			ss1 = ss1 + s1; ss2 = ss2 + s2;
		};
	};
	out.keep(n);
};
);

( // COPY - the reference list passed through unchanged (SELECT and SEGMENT only)
~copy = { |list| list.copy };
);

// ---------------------------------------------------------------------------
// The SSP hierarchy in Genesis's own idiom: LIST -> SELECT -> SEGMENT ->
// PERMUTATION -> SOUND (SSP p. 26). Each level draws with a selection principle
// from the level below, referencing indices, not values. SOUND is DemandEnvGen:
// SSP's "triplet" (clock rate, increment, count) is linear interpolation between
// amplitude points at a per-flank rate, which is what DemandEnvGen does natively.

( // ~ssp - build one process from a plan; returns a function for Ndef/NodeProxy
~ssp = { |plan, channels = 4|
	var ampList  = plan[\ampList].value;        // LIST, amplitude values 0-4095
	var timeList = plan[\timeList].value;       // LIST, time values in samples
	var ampSel   = plan[\ampSelect].value(ampList);    // SELECT, indices into LIST
	var timeSel  = plan[\timeSelect].value(timeList);
	var segs     = plan[\segments].value(ampSel, timeSel);   // SEGMENT
	var amps = segs.collect({ |s| s[0] }), times = segs.collect({ |s| s[1] });
	// one PERMUTATION per channel: same segment set, different orderings, so the
	// four channels are decorrelated by construction rather than duplicated
	var perms = Array.fill(channels, { plan[\permutation].value(segs.size) });
	{ |amp = 0.2|
		perms.collect({ |perm|
			var a = Dseq(perm.collect({ |i| Dseq(amps[i - 1].linlin(0, 4095, -1.0, 1.0), 1) }), inf);
			var t = Dseq(perm.collect({ |i| Dseq(times[i - 1], 1) }), inf);
			DemandEnvGen.ar(a, t * SampleDur.ir);
		}) * amp;
	};
};
)
