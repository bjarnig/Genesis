////////////////////////////////////////////////////////////////
//
//          03 - Pulsar Synthesis (Ora-driven)
//
////////////////////////////////////////////////////////////////

// Pulsar synthesis voiced across Ora frequency arrays (~f / ~pfreqs): comb, ringz, and bandpass-filter variants with organic formant/fundamental drift, then Ora transforms (retrograde, inversion, centroid dilation) and a dynamic morph walking formant/comb freq through the array.

s.boot

(

~f.do { |f, i|
	var formDrift = 1.0;  // state: organic multiplier for formant
	var fundDrift = 1.0;  // state: organic multiplier for fund

	Pmono(\pulsarComb,
		\wavebuf, ~pulsarbuf,
		\envbuf, ~envbuf,

		\formBase, Prand([f, f * 15.2, f, f * 0.85, f], inf),
		\fundBase, Env(
			[6, 28, 0.2],
			[10, 10],
			\sin
		),

		// --- Organic drift (the jitter): slow random walk, bounded so it never runs away ---
		\formDrift, Pfunc({
			formDrift = formDrift * rrand(0.985, 1.015);
			formDrift = formDrift.clip(0.75, 1.35);
			formDrift;
		}),
		\fundDrift, Pfunc({
			fundDrift = fundDrift * rrand(0.99, 1.01);
			fundDrift = fundDrift.clip(0.8, 1.25);
			fundDrift;
		}),

		// --- Combined: base * drift ---
		\form, Pkey(\formBase) * Pkey(\formDrift),
		\fund, Pkey(\fundBase) * Pkey(\fundDrift),

		// Comb delay tuned to this Ora frequency
		\combFreq, f * Pseq([4, 4.02, 3.998], inf),
		\combDecay, 0.75,
		\combMix, 0.2,
		\amp, 0.8 / ~f.size,
		\out, i.mod(8),
		\dur, 0.001
	).play;
};

)


(

~f.do { |f, i|
	var lo = f * rrand(0.05, 0.2);
	var hi = f * rrand(4.0, 12.0);
	var dur = rrand(0.5, 2.5);
	var fundLevels = [4, 80, 2, 120, 6, 200, 0.5, 60, 3, 1];
	var fundWeights = fundLevels.collect(_.reciprocal).normalizeSum;

	Pmono(\pulsarComb,
		\wavebuf, ~pulsarbuf,
		\envbuf, ~envbuf,
		\form, Env(
			[f, hi, lo, f, hi * 0.5, lo * 3, f, hi, lo * 0.5, f],
			[dur, dur * 0.3, dur * 0.8, dur * 0.2, dur * 0.6, dur * 0.15, dur, dur * 0.4, dur * 0.5],
			[\exp, \sin, -6, \welch, 4, \sin, \exp, -8, \sin]
		),
		\fund, Pseg(Pwrand(fundLevels, fundWeights, inf), Pwhite(dur * 0.2, dur * 0.6, inf), \sin),
		\combFreq, f * Pseq([8, 8, 8, 4, 2], inf),
		\combDecay, 3.4,
		\combMix, 0.5,
		\amp, 0.5 / ~pfreqs.size,
		\out, i.mod(8),
		\dur, 0.01
	).play;
};

)


(

~pfreqs.do { |f, i|
	var form = rrand(60, 300);
	var decay = rrand(0.08, 0.25);

	Pmono(\pulsarRingz,
		\wavebuf, ~complexPulsarBuf, \envbuf, ~envbuf,
		\form, 50*8,
		\ringFreq, f*16,
		\ringMix, 0.5,
		\amp, Env([0.5, 0.3, 0.1, 0.0], [12, 6, 4], \sin),
		\out, i.mod(8),
		\fund, Pbrown(1,30,2),
		\ringDecay, Env([decay, decay * 1.6, decay * 0.8, decay], [12, 16, 14], \sin),
		\dur, 0.2
	).play;
};

)



(

~pfreqs.do { |f, i|
	var fund = 1;
	var form = 200;
	var rq = rrand(0.03, 0.15);

	Pmono(\pulsarBPF,
		\wavebuf, ~pulsarbuf, \envbuf, ~envbuf,
		\form, form * (i + 1) * Prand([2,4],inf),
		\bpFreq, f,
		\amp, 5 / ~pfreqs.size,
		\out, i.mod(8),
		\fund, Env([7,0.01,8] * i,[4,8]),
		\bpRQ, Env([rq, rq * 1.5, rq * 0.6, rq], [14, 12, 14], \sin),
		\dur, 0.05
	).play;
};

)



(

var transforms = [
	Ora(~pfreqs).asArray,
	Ora(~pfreqs).retrograde().asArray,
	Ora(~pfreqs).inversion().asArray,
	Ora(~pfreqs).centroidDilation(0.7).asArray
];

transforms.do { |freqs, layer|
	freqs.do { |f, i|
		Synth(\pulsarComb, [
			\wavebuf, ~pulsarbuf, \envbuf, ~envbuf,
			\fund, f.linlin(freqs.minItem, freqs.maxItem, 5, 30),
			\form, f.linlin(freqs.minItem, freqs.maxItem, 60, 300),
			\combFreq, f,
			\combDecay, rrand(0.15, 0.5),
			\combMix, 0.55,
			\amp, Env([0.1, 0.05, 0.01, 0.0], [12, 6, 4], \sin),
			\out, i.mod(8)
		]);
	};
};

)

0.8 / (4 * 7)


// Example 11: Dynamic parameter walks through Ora space; gradually morph formant through the Ora array, comb frequency follows along.

(

{
	var synths;

	synths = ~pfreqs.collect { |f, i|
		Synth(\pulsarComb, [
			\wavebuf, ~pulsarbuf, \envbuf, ~envbuf,
			\fund, 15, \form, f,
			\combFreq, f*4, \combDecay, 0.4, \combMix, 0.5,
			\amp, 0.5 / ~pfreqs.size,
			\out, i.mod(8)
		]);
	};

	// Morph: each synth walks to the next frequency in the array
	Routine({
		20.do { |step|
			synths.do { |syn, i|
				var nextIdx = (i + step + 1).mod(~pfreqs.size);
				var nextFreq = ~pfreqs[nextIdx];
				syn.set(\form, nextFreq*4);
				syn.set(\combFreq, nextFreq*4);
			};
			0.2.wait;
		};
	}).play;

}.fork

)
