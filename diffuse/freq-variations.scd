// freq-variations.scd
// Ways of varying the set without replacing it. freq-sets.scd and
// freq-sets-sharp.scd are untouched; nothing here overwrites ~f.
//
// What the measurements said, so the strategies can be judged rather than
// believed. Local contrast is the band against its own six-semitone
// neighbourhood, in dB, over the material it is derived from:
//
//   rotation        identical spectrum, different roles       0.00 dB, by definition
//   blend           between two family sets                   +0.10 at 56 cents
//   family set      each on its own material            +0.29 to +1.91, 122 to 297 cents
//   harmonic set    on the take's own fundamental        +0.15 to +1.37, 14 to 52 cents
//   low harmonics   a different register entirely       -0.17 to +0.59
//
// Two of those are negative results and worth knowing. A harmonic set built at
// the original register lands within half a semitone of the original whatever
// fundamental it uses, because by the 290th harmonic the spacing is 6 cents:
// as variation it is no variation at all. And the low-harmonic designs differ
// from each other by less than 1 dB of contrast, so choose between them by ear
// and by register, not by the measurement.
//
// Tools/genesis-corpus/freq-variations.py

~fvar = ();


// 1. one set per process, each snapped to its own modes, register kept.
  //    The dB is that set on its own material, then its distance from ~f.
~fvar[\family] = (
	bramble:  [158.00, 237.00, 773.00, 1735.00, 7792.00, 4501.00, 1192.00],   // +0.45, 136c
	clover:   [199.00, 205.00, 868.00, 1735.00, 9044.00, 3896.00, 1300.00],   // +0.45, 130c
	ferna:    [223.00, 298.00, 1032.00, 1502.00, 7570.00, 3785.00, 1062.00],  // +0.29, 297c
	gorse:    [199.00, 281.00, 843.00, 2064.00, 9266.00, 4128.00, 1546.00],   // +0.92, 181c
	moss:     [188.00, 266.00, 974.00, 2064.00, 9817.00, 4908.00, 1459.00],   // +1.24, 167c
	nettle:   [199.00, 281.00, 1093.00, 1638.00, 8255.00, 4248.00, 1377.00],  // +1.91, 177c
	sedge:    [223.00, 205.00, 751.00, 1735.00, 9537.00, 4769.00, 1502.00],   // +0.42, 225c
	teasel:   [182.00, 223.00, 946.00, 2186.00, 10401.00, 3677.00, 1227.00],  // +1.53, 200c
	thistle:  [178.00, 255.00, 730.00, 1546.00, 9044.00, 4473.00, 1502.00],   // +1.34, 122c
	yarrow:   [167.00, 281.00, 751.00, 1839.00, 9002.00, 4633.00, 1158.00]    // +1.07, 123c
);


// 2. the material's own fundamentals. 39 of the 62 takes are harmonic to
  //    within 25 cents over 90% of their peaks, and the fundamentals cluster.
  //    These are rates rather than pitches, which is what you would expect
  //    from a demand-rate engine: they sit where the processes tick.
~fvar[\fundamentals] = (
	f3123: 31.23,   // 12 takes: teasel05, teasel06, moss01, sedge04, ferna03, nettle01 ...
	f3380: 33.80,   // 11 takes: clover06, bramble06, ferna01, ferna04, nettle05, nettle03 ...
	f3945: 39.45,   //  7 takes: sedge03, bramble08, teasel01, bramble04, bramble01 ...
	f4510: 45.10,   //  3 takes: gorse05, moss03, moss04
	f3625: 36.25,   //  2 takes: bramble02, teasel03
	f4767: 47.67,   //  2 takes: nettle02, teasel07
	f5070: 50.70,   //  1 take:  gorse06
	f6505: 65.05    //  1 take:  clover01
);

// the cluster centres stand in near-simple ratio: 47.67/31.23 is within a
// cent of 3:2, and 65.05/31.23 within a few cents of 2:1


// 3. builders. None of these touch ~f: they return a new array.

// nearest harmonic of f0 to each frequency of a set. Close to the original by
// construction, so use it for coherence, not for contrast.
~fvar[\harmonic] = { |f0, set|
	set.collect { |f| max(1, (f / f0).round.asInteger) * f0 };
};

// a set from chosen harmonic numbers: this is the one that actually moves
~fvar[\fromHarmonics] = { |f0, numbers|
	numbers.collect { |n| n * f0 };
};

// designs worth trying, measured on the 33.80 Hz group
~fvar[\designs] = (
	odd:       [3, 5, 7, 9, 11, 13, 15],       // +0.36, one register, evenly packed
	prime:     [2, 3, 5, 7, 11, 13, 17],       // +0.29
	fibonacci: [2, 3, 5, 8, 13, 21, 34],       // +0.59, widest spread of the low sets
	octaves:   [1, 2, 4, 8, 16, 32, 64],       // +0.04, pure octaves
	widePrime: [2, 3, 5, 11, 17, 29, 47]       // +0.25
);

// same pitches, different roles. The cheapest variation there is: the
// spectrum does not move at all, only which frequency drives what.
~fvar[\rotate] = { |set, n| set.rotate(n.neg) };

// geometric blend, a straight line in pitch rather than in Hz
~fvar[\blend] = { |a, b, alpha = 0.5|
	a.collect { |x, i| (x ** (1 - alpha)) * (b[i] ** alpha) };
};


/*  what they give

	~fvar[\rotate].(~fset[\original], 2)
	~fvar[\blend].(~fvar[\family][\yarrow], ~fvar[\family][\nettle], 0.5)
	~fvar[\harmonic].(33.80, ~fset[\original])
	~fvar[\fromHarmonics].(33.80, ~fvar[\designs][\fibonacci])
*/


// 4. a catalogue: every family set, plus a path between two of them
~fvarBank = ~fvar[\family].values.copy;
5.do { |i|
	~fvarBank = ~fvarBank.add(
		~fvar[\blend].(~fvar[\family][\yarrow], ~fvar[\family][\nettle], i / 4));
};
~fvar[\designs].keysValuesDo { |k, h|
	~fvarBank = ~fvarBank.add(~fvar[\fromHarmonics].(33.80, h));
};
("bank: % sets".format(~fvarBank.size)).postln;


/*  using one, still without changing the original

	~f = ~fvarBank.choose;
	~wtfreqs = Ora(~f).asArray;
	~bpfreqs = Ora(~f).asArray;

    Ora already carries the rest of the vocabulary, and all of it returns a
    new array: .rotate, .blend, .otMorph, .inharmonic, .ratioSnap, .detune,
    .drift, .intervalFlow, .expand, .contract, .tilt, .splay, .shatter.
    A slow .drift over the set is the one that would move the whole folder
    without editing any patch.
*/
