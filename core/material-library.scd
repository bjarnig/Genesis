// material-library.scd
// The processes of sketches/material-combined-v4.scd kept as source functions instead of
// live proxies. Evaluating an Ndef/NF definition instantiates it at once, so a
// file of ten of them runs ten synths whether or not you ever hear them; here
// nothing reaches the server until a key is asked for.
//
//   ~gen.(\fern)        // instantiate, silent: running into its own bus only
//   ~gen.(\fern).play   // ... and out to the hardware
//   ~play.(\fern)       // both in one step
//   ~solo.(\fern)       // free everything else first
//   ~free.(\fern)       // back to no synth, no CPU
//   ~free.()            // free the lot
//   ~loaded             // what is instantiated right now
//   ~material.keys      // what is on offer
//
// ~gen returns the proxy, so it drops straight into a fader setup:
//   ~ndefFaders.(~gen.(\fern), ( ... ))

(

~material = (

	fern: (proxy: NF, func: { |lfnFreq = 0.25, repeats = 1, freqMult = 1, freqMult2 = 1, knumFrom = 1, knumTo = 100,
		ampStep = 0.8, stiffness = 0.05, ampStepB = 0.45, stiffnessB = 0.03,
		harmScale = 0.0625, detuneHi = 0.2, detuneLo = 0.2, templateType = 0, ampDistParam = 0.5,
		seqMode = 0, factorsMult = 1, amp = 0.88|

		var scale = 0.25;
		var factors = [15, 5, 10, 20] * factorsMult;

		// Cyclegen fixes knum and the freqs array when the synth is built: the LFNoise
		// only seeds one knum per channel, so its rate is not a control. Transposition
		// goes through freqMul, which is read live, hence the detune lands there too.
		// depth as a transposition ratio around 1; lfnFreq is only the rate, so it is
		// silent until one of these is opened up. The floor keeps freqMul off zero.
		var detune = LFNoise0.kr(lfnFreq).range((1 - detuneLo).max(0.05), 1 + detuneHi);

		var scatter = Cyclegen.ar(
			LFNoise1.ar(factors).range(knumFrom, knumTo * 5),
			ampStep: ampStep, stiffness: stiffness, templateType: templateType, seqMode: seqMode,
			ampDistParam: ampDistParam, repeats: repeats, freqMul: freqMult,
			freqs: Array.rand(16, 1, 1000) * freqMult2
		) * scale;

		// harmScale sets where this layer sits: 0.0625 keeps it subaudio, 1 puts it at pitch
		var harmonic = Cyclegen.ar(
			LFNoise1.ar(factors).range(knumFrom, knumTo),
			ampStep: ampStepB, stiffness: stiffnessB, templateType: templateType, seqMode: seqMode,
			ampDistParam: ampDistParam, interp: 2,
			repeats: repeats, freqMul: freqMult * harmScale * detune,
			freqs: [65, 87, 98, 131] * freqMult2
		) * scale;

		scatter + harmonic * amp
	}),

	moss: (proxy: NF, func: { |lfnFreq = 5, mod = 20, from = 9, to = 12, freqFrom = 10, freqTo = 1000,
		jitter = 0.5, ampStep = 0.2, duty = 0.4, hpf = 40, sdm = 10, grainGain = 0.5,
		knum = 126, factorsMult = 1, amp = 0.7|

		var min = 0.1, max = 0.3;
		var factors = [1, 2, 0.5, 0.25] * factorsMult;
		var sd = SampleDur.ir * sdm;

		var folded = HPF.ar(
			DemandEnvGen.ar(
				Dseq([min, min.neg, [max.neg, max]], inf),
				sd * Dseq([from, to, Dbrown(from, to, to, from.neg, from)], inf)
			).fold2(SinOsc.ar(factors * mod)) * amp,
			hpf
		);

		var grains = Grainstoch.ar(
			LFNoise1.ar(factors * lfnFreq).range(freqFrom, freqTo), knum,
			duty: duty, ampStep: ampStep, jitter: jitter
		) * amp * grainGain;   // the grain layer sits ~12 dB under the folded one at 0.5

		folded + grains
	}),

	sedge: (proxy: NF, func: { |sdm = 10, ffrom = 10, fto = 100, noiseRate = 50, bsRate = 0.8, bsLo = 600, bsHi = 1200,
		frequencyB = 0.01, surface = 0.2, lop = 18000, hip = 20, hpf = 50, lopVol = 0.5, hipVol = 0.5, amp = 0.7|

		var sd = SampleDur.ir * sdm;
		var factors = [1, 2, 0.5, 4];
		var lfb, fritz;

		lfb = DemandEnvGen.ar(
			Dseq([-0.1, 0.1], inf),
			Dseq([sd * 10, sd * 80, sd * Dwhite(60, 90, inf)], inf)
		) ! 2 * LFDNoise1.ar(noiseRate * factors).range(0.5, 1.5);
		lfb = HPF.ar(BBandStop.ar(lfb, LFDNoise1.ar(bsRate).range(bsLo, bsHi), 3) * 2, hpf);

		fritz = FitzHughNagumo.ar(
			Impulse.kr(LFNoise1.kr(factors).range(ffrom, fto)),
			surface.linlin(0.0, 1.0, 0.0001, 0.4),
			frequencyB.linlin(0.0, 1.0, 0.0001, 0.4),
			frequencyB.linlin(0.0, 1.0, 0.01, 3),
			surface.linlin(0.0, 1.0, 0.01, 4),
			SinOsc.kr(Line.ar(20, 30, 45), 0, 0.7),
			SinOsc.kr(Line.ar(20, 30, 45), 0, 0.8)
		) * 0.7;
		fritz = BLowPass4.ar(fritz, lop, 0.25, mul: lopVol) + BHiPass4.ar(fritz, hip, 0.25, mul: hipVol);

		(lfb + (fritz * 0.2)) * amp
	}),

	nettle: (proxy: NF, func: { |a = 0.5, b = 0.5, c = 0.5, pmFreq = 10, modFrom = 50, wobLo = 500, wobHi = 800,
		filtLo = 8000, filtHi = 19000, hpf = 30, demGain = 4, cScale = 1000, bScale = 1000,
		filtModScale = 0.1, lagTime = 0.15, gritGain = 0.6, eqFreqLo = 4000, eqFreqHi = 10000, amp = 0.7|

		var modfreq = LFDClipNoise.ar(cScale * c).range(modFrom, LFNoise1.ar(0.01).range(wobLo, wobHi));
		var mod = PMOsc.ar(pmFreq * a, modfreq, 1);
		var grav = LeastChange.ar(GravityGrid.ar(0, bScale * b), mod);
		var filtMod = LFDClipNoise.ar(filtModScale * b).range(filtLo, filtHi);
		var grit = gritGain * HPF.ar(LPF.ar(grav, Lag.ar(filtMod, lagTime)), hpf);

		var signal = DemandEnvGen.ar(
			Dseq([-1, 0.1, Dwhite(-0.1, 0.1, 5), Dwhite(-0.2, 0.2, 5)], inf),
			SampleDur.ir * Array.rand(4, 0.8, 100.2), 1, 0, 1, Impulse.ar([10, 40])
		) * XLine.ar(0.0015, 0.15, 120);

		var demwav = BPeakEQ.ar(
			signal, Array.rand(4, eqFreqLo, eqFreqHi), 4,
			EnvGen.ar(Env([0, -1, -7], [4, 12]))
		) * demGain;

		(grit + demwav) * amp
	}),

	bramble: (proxy: NF, func: { |sdm = 1, repeats = 2, from = 1, to = 20, mod = 40,
		rate = 12, trigMin = 40, trigMax = 1000, freq = 1000, mf = 0.3, bw = 12, hpf = 40, amp = 0.7|

		var sd = SampleDur.ir * sdm;
		var trigx = Impulse.kr(rate);
		var seqx = Diwhite(trigMin, trigMax, inf);
		var trig = Demand.kr(trigx, 0, seqx);
		var factors = [0.04, 0.09, 0.02, 0.1];

		var leaf = DemandEnvGen.ar(
			Dseq([Dseries(-1.0, factors, 30)], inf),
			Dseq([
				1, 20, 100, 0.1,
				Dwhite(from, to, repeats),
				Dwhite(from / 1.5, to * 3, repeats)
			], inf) * sd
		).clip(SinOsc.ar(mod)) * mf;

		var gravities = BPeakEQ.ar(
			HPF.ar(
				BBandStop.ar(
					LeastChange.ar(
						GravityGrid.ar(0, Array.fill(4, { freq * rrand(0.25, 1.2) })),
						LoFM.ar(freq)
					),
					Lag.kr(trig), bw
				), hpf
			), 100, 2, -6
		) * 0.5;

		leaf + gravities * amp
	}),

	clover: (proxy: NF, func: { |ser = 500, sdm = 2.5, step = 2.5, brownLo = 1, brownHi = 7,
		mf = 0.008, stepsGain = 0.3, stepsStep = 0.1, stepsLen = 40, amp = 0.85|

		var sd = SampleDur.ir * sdm;

		var foral = DemandEnvGen.ar(
			Dseq([Dseries(-0.5, [0.1, -0.1, -0.05, 0.15], ser)], inf),
			sd * Dbrown(brownLo, brownHi, step)
		) * mf;

		// steps ramps from -1 well past 0 before wrapping, which is most of the DC
		// defect; LeakDC removes it without touching the ramp's audible motion
		var steps = LeakDC.ar(DemandEnvGen.ar(
			Dseq([Dseries(-1.0, stepsStep, stepsLen ! 4)], inf),
			Dseq([
				Dwhite(1, 10, 4),
				Dwhite(0.1, 100, 4)
			], inf) * SampleDur.ir
		)) * stepsGain;

		(foral + steps) * amp
	}),

	// replaces the old thistle (2026-09-15): a bank of 4 bandpasses wandering
	// over a noise-modulated Q, fed by a DemandEnvGen ramp. Kept 4-channel to
	// match the rest of the library, so it still goes through the spatialisers.
	thistle: (proxy: NF, func: { |fspeed = 0.2, sdm = 40, bpresfrom = 0.005, bpresto = 0.2,
		a = 9, b = 5, min = 0.05, max = 0.5, freqLo = 100, freqHi = 2000,
		sdRandLo = 0.125, sdRandHi = 2.0, drive = 20, amp = 0.5|

		var channels = 4;
		var bpfreqs = Array.series(channels, freqLo, (freqHi - freqLo) / channels);
		var sd = SampleDur.ir * sdm * Array.rand(channels, sdRandLo, sdRandHi);
		// one Q-wander rate per channel, fanned out from fspeed so they drift apart
		var fspeedArray = [fspeed, fspeed * 1.2, fspeed * 1.4, fspeed * 1.6];

		var snd = DemandEnvGen.ar(
			Dseq([min, min.neg, max], inf),
			Dseq([sd * a, sd * b, Dwhite(sd * a, sd * b)], inf)
		);
		snd = SoftClipAmp8.ar(snd, drive) * amp;

		Limiter.ar(BBandPass.ar(snd, bpfreqs,
			Lag.ar(LFNoise1.ar(fspeedArray).range(bpresfrom, bpresto))))
	}),

	yarrow: (proxy: NF, func: { |fspeed = 20, fcenter = 200, sdm = 0.1, mfreq = 0.01, filtBw = 6, modFreq = 5, harms = 120,
		drive = 10, bsRate = 5, bsLo = 100, bsHi = 8000, lpf = 12000, hpf = 30, amp = 0.7|

		var a = 9, min = 0.1, max = 0.3;
		var b = XLine.ar(15, 1, 45);
		var sd = SampleDur.ir * sdm;
		var lestas, bloded, freq, sincub;

		lestas = DemandEnvGen.ar(
			Dseq([min, min.neg, [max.neg, max]], inf),
			Dwhite(sd * a, sd * b)
		).wrap2(SinOsc.ar([mfreq, mfreq * 1.1])) * 0.1;
		lestas = SoftClipAmp8.ar(lestas, drive) * 0.8;
		lestas = HPF.ar(BBandStop.ar(
			lestas,
			Lag.ar(LFNoise1.ar([fspeed, fspeed * 2, fspeed * 0.5, fspeed * 1.5]).range(fcenter * 0.2, fcenter * 2), 0.05),
			filtBw
		));

		freq = XLine.ar(20, 10, 45);
		bloded = HPF.ar(
			Blip.ar(Array.series(4, freq, 5), harms)
				.fold2(SinOsc.ar(Array.series(4, modFreq, modFreq * 1.5))),
			hpf
		) * 0.8;
		bloded = BBandStop.ar(bloded, LFNoise1.ar(bsRate).exprange(bsLo, bsHi), 4);
		bloded = LPF.ar(bloded, lpf);

		sincub = SinOsc.ar(LFCub.kr([25, 15, 20, 10], 0, 380, 400), 0, 0.02);

		(lestas + bloded + sincub) * amp
	}),

	gorse: (proxy: NF, func: { |a = 0.5, b = 0.5, c = 0.5, sawFreq = 100, feedback = 1.0002, delay = 0.02,
		aa = 15, bb = 10, peakFreq = 4000, peakGain = -3, hpf = 2000, fbGain = 0.1, amp = 0.7|

		var min = 0.1, max = 0.2;
		var sd = SampleDur.ir;
		var trig, seq, freq, plane;
		var sig, input, snd, fbx;

		sd = sd * c * Array.rand(4, 0.5, 4.0);
		trig = Impulse.kr(LFNoise1.kr([0.2, 0.8, 0.3, 0.8]).range(0.01, 1.0) * a);
		seq = Dseq([Dbrown(10, 30, 2, 16), Dwhite(10, 20, 4)], inf);
		freq = Demand.kr(trig, 0, seq);

		plane = BPeakEQ.ar(HPF.ar(DemandEnvGen.ar(
			Dseq([min, min.neg, [max.neg, max]], inf),
			Dseq([sd * aa, sd * bb], inf)
		).fold2(SinOsc.ar(freq * 2 * b)) * amp, 40 + (200 * a)), peakFreq, 1, peakGain, 2);

		// the band centres ride sawFreq so the feedback layer has a pitch that moves;
		// the ratios between them stay random per build
		sig = Saw.ar(sawFreq);
		input = sig + LocalIn.ar(4);
		snd = SoftClipAmp8.ar(
			BBandPass.ar(input, (sawFreq * Array.rand(4, 0.5, 8)).clip(20, 16000)),
			sig.linlin(-1.0, 1.0, 14.rand, 18.rand));
		snd = DelayC.ar(snd, 1, LFNoise2.ar({ 20.rand } ! 4).range(delay, delay * 1.1));
		LocalOut.ar(snd * feedback * rrand(0.9999, 0.999999));
		fbx = Limiter.ar(HPF.ar(snd, hpf) * fbGain);   // was pinned at 0.1, 12 dB under the plane

		plane + fbx
	}),

	teasel: (proxy: NF, func: { |modRate = 10, modFrom = 100, modTo = 10070, peakFreq = 400, lpf = 1070, hpf = 30,
		carrier = 1, sdm = 0.15, gateRate = 1, sparkleGain = 0.4, demGain = 2, amp = 0.7|

		// carrier scales the 30 s sweep that used to be the only thing setting this
		// layer's pitch, so it can leave the subaudio range
		var mod = PMOsc.ar(XLine.ar(5, 18, 30) * carrier, LFDClipNoise.ar(modRate).range(modFrom, modTo), 1);

		var sparkling = sparkleGain * BPeakEQ.ar(
			LPF.ar(LeastChange.ar(GravityGrid.ar(0, [10, 20, 30, 40] * carrier), mod), lpf),
			peakFreq, 1, -6
		)[0];

		var signal = DemandEnvGen.ar(
			Dseq([-1, 0.1, Dwhite(-0.1, 0.1, 5.2), Dwhite(-0.2, 0.2, 15)], inf),
			SampleDur.ir * sdm, 1, 0, 1,
			Impulse.ar([20, 40] * gateRate) * SinOsc.ar(0.01).range(0.1, 10)
		) * LFClipNoise.ar(XLine.ar(10, 25, 30)).range(0.01, 0.2);

		var demwav = HPF.ar(BPeakEQ.ar(
			signal, Array.rand(4, 1000, 12000), 2,
			LFClipNoise.ar(XLine.ar(16, 25, 40)).range(-19, -1)
		) * demGain, hpf);

		(sparkling + demwav) * amp
	}),

);

~loaded = IdentitySet.new;

// instantiate on demand; re-asking for a live key just hands it back
~gen = { |key|
	var def = ~material[key] ?? { Error("no process called" + key).throw };
	~loaded.add(key);
	def[\proxy].new(key, def[\func])   // .new, not .value: Ndef.(...) would just hand back the class
};

~play = { |key| ~gen.(key).play };

// no key frees everything loaded
~free = { |key|
	(key !? { [key] } ?? { ~loaded.asArray }).do { |k|
		~material[k][\proxy].new(k).clear;
		~loaded.remove(k);
	};
};

~solo = { |key| ~free.(); ~play.(key) };

("material-library: " ++ ~material.size ++ " processes ready: " ++ ~material.keys.asArray.sort).postln;

)
