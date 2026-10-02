
/*

TODO:

Make sure the frequencies can be changed.


*/

(
SynthDef(\stochasticA, {|
	demandA = 9.5, demandB = 15,
	envMin = 0.1, envMax = 0.2,
	foldFreqs = #[0.0005, 0.005, 0.00075, 0.0025],
	dry = 0.7, wet = 0.35, decayScale = 1, drive = 0.2, amp = 1.5|
	var sd = SampleDur.ir;
	var freqs = ~f;
	// "soft": amplitude rolls off with rising freq, rings shorten up high
	var amps  = freqs.collect {|f| (freqs.minItem / f).pow(0.5) }.normalizeSum;
	var rings = freqs.collect {|f| (700 / f).clip(0.1, 0.2) } * decayScale;
	var sig, res;

	sig = DemandEnvGen.ar(
		Dseq([envMin, envMin.neg, [envMax.neg, envMax]], inf),
		sd * Dseq([demandA, demandB, Dbrown(demandA, demandB, demandB - demandA, demandA)], inf)
	).fold2(SinOsc.ar(foldFreqs));

	sig = sig * LFNoise1.ar(0.5).range(0.2,0.9);

	res = Klank.ar(`[freqs, amps, rings], sig * drive);
	res = LeakDC.ar(res);

	sig = (sig * dry) + (res * wet);

	sig = BBandStop.ar(sig, 1000, 4, amp);

	sig = sig * EnvGen.ar(Env([1,1,0], [20,15]),doneAction:2);

	Out.ar(0, sig);
}).play;

)


( // VAR A - Simple dynamic noise

SynthDef(\dynamicNoiseSimple, {|
	wfMult = 0.2, amp = 0.2,
	seqMult = 8, envMin = -0.1, envMax = 0.1,
	fadeInTime = 20, fadeInStart = 0.001, fadeInEnd = 1.0,
	dry = 0.7, wet = 0.35, decayScale = 0.1, drive = 0.2
|

	var sd = SampleDur.ir * wfMult;
	var freqs = ~f * 0.125;
	var amps  = freqs.collect {|f| (freqs.minItem / f).pow(0.5) }.normalizeSum;
	var rings = freqs.collect {|f| (700 / f).clip(0.2, 3.0) } * decayScale;
	var sig, res;

	sig = DemandEnvGen.ar(
		Dseq([envMin, envMax], inf),
		Dseq([sd * seqMult, sd * ({ rrand(6, 10) } ! 8) * seqMult, sd * Dwhite(seqMult * 6, seqMult * 9, inf)], inf)
	) * XLine.ar(fadeInStart, fadeInEnd, fadeInTime);

	res = DynKlank.ar(`[freqs, amps, rings], sig * drive);
	res = LeakDC.ar(res);
	sig = (sig * dry) + (res * wet);

	sig = sig * EnvGen.ar(Env([1,1,0], [20,15]),doneAction:2);

	Out.ar(0, sig * amp);
}).play;

)
