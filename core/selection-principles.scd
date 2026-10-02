// Koenig's six selection principles (SSP 1979, pp. 19-23), as value generators.
// Koenig's six selection principles (SSP 1979, pp. 19-23) as value generators.
// Each returns an Array of N integers (indices into a list) for Dseq(arr, inf) into DemandEnvGen.
( // ALEA
~alea = { |a, z, n|
	Array.fill(n, { rrand(a, z) });
};
);

( // SERIES
~series = { |a, z, n|
	var pool = (a..z);
	var passes = (n / pool.size).ceil.max(1);
	// fresh scramble per pass: Dshuf would reuse one shuffle for the whole stream
	Array.fill(passes, { pool.scramble }).flatten.keep(n);
};
);

( // RATIO
~ratio = { |a, z, n, factors|
	var half = factors.copy;
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

( // GROUP
// Returns [[value, length], ...]; ~group flattens it.
// Adjacent groups drawing the same value fuse into one run (pseudo-groups, p. 75).
~groupPairs = { |a, z, n, type, la, lz|
	var vals = (a..z), lens = (la..lz);
	var valPool = vals.scramble, lenPool = lens.scramble;
	var nextVal, nextLen, pairs = Array.new, total = 0;
	// types 1-4: alea/alea, alea/series, series/alea, series/series
	nextVal = { if(type < 3) { vals.choose } {
		if(valPool.isEmpty) { valPool = vals.scramble }; valPool.pop } };
	nextLen = { if(type.even) {
		if(lenPool.isEmpty) { lenPool = lens.scramble }; lenPool.pop } { lens.choose } };
	while { total < n } {
		var v = nextVal.value, l = nextLen.value.min(n - total);
		pairs = pairs.add([v, l]);
		total = total + l;
	};
	pairs;
};

~group = { |a, z, n, type, la, lz|
	~groupPairs.(a, z, n, type, la, lz).collect({ |p| Array.fill(p[1], p[0]) }).flatten;
};
);

( // SEQUENCE
~chunks = { |str|
	var out = Array.new;
	str.replace(" ", "").split($,).do { |c|
		case
		{ c.includes($*) } {
			var p = c.split($*);
			p[0].asInteger.do { out = out.add(p[1].asInteger) };
		}
		{ c.includes($-) } {
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

( // TENDENCY (p. 122)
~tend = { |n, masks|
	var out = Array.new(n);
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

( // COPY
~copy = { |list| list.copy };
);

// SSP hierarchy (p. 26): LIST -> SELECT -> SEGMENT -> PERMUTATION -> SOUND (DemandEnvGen).
( // ~ssp
~ssp = { |plan, channels = 4|
	var ampList  = plan[\ampList].value;
	var timeList = plan[\timeList].value;
	var ampSel   = plan[\ampSelect].value(ampList);
	var timeSel  = plan[\timeSelect].value(timeList);
	var segs     = plan[\segments].value(ampSel, timeSel);
	var amps = segs.collect({ |s| s[0] }), times = segs.collect({ |s| s[1] });
	// one PERMUTATION per channel: same segments, different orderings
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
