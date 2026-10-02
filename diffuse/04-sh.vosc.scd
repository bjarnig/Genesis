////////////////////////////////////////////////////////////////
//
//                           VOSC
//
////////////////////////////////////////////////////////////////


(

SynthDef(\voscDrift, {|
	attack = 6, decay = 10, sustain = 8, release = 15,
	amp = 0.5,
	curve = 8,
	modRate = 0.075, modFrom = 20, modTo = 10,
	freqFrom = 600, freqTo = 610, freqMult = 1.001,
	bufNoiseRates = #[0.04, 0.02, 0.08, 0.01],
	bufIndexMin = 5.0, bufIndexMax = 10.0,
	oscFreqMults = #[1.0, 1.025, 1.0, 1.05],
	envTimeRandMin = 0.5, envTimeRandMax = 1.5,
	reverbChans = #[4, 5, 6, 7],
	ampModMin = 0.01, ampModMax = 0.3,
	hpfEnvLevels = #[800, 2400, 600, 4000, 10000]
|
	var wtName = "OrganicSine";
	var mod, freqf, freq, bufindexa, bufindexb, bufindexc, bufindexd;
	var osca, oscb, oscc, oscd, envLevels, envTimes, envCurves, sig;

	mod = SinOsc.ar(modRate).range(modFrom, modTo);
	freqf = rrand(freqFrom, freqTo);
	freq = SinOsc.ar(mod).range(freqf, freqf * freqMult);
	bufindexa = LFNoise2.ar(bufNoiseRates[0]).range(bufIndexMin, bufIndexMax) + ~wtb[wtName].bufnum;
	bufindexb = LFNoise2.ar(bufNoiseRates[1]).range(bufIndexMin, bufIndexMax) + ~wtb[wtName].bufnum;
	bufindexc = LFNoise2.ar(bufNoiseRates[2]).range(bufIndexMin, bufIndexMax) + ~wtb[wtName].bufnum;
	bufindexd = LFNoise2.ar(bufNoiseRates[3]).range(bufIndexMin, bufIndexMax) + ~wtb[wtName].bufnum;
	osca = VOsc.ar(bufindexa, freq * oscFreqMults[0]);
	oscb = VOsc.ar(bufindexb, freq * oscFreqMults[1]);
	oscc = VOsc.ar(bufindexc, freq * oscFreqMults[2]);
	oscd = VOsc.ar(bufindexd, freq * oscFreqMults[3]);
	envLevels = [0.0, 1.0, 0.5, 0.8, 0.0] * amp;
	envTimes = [attack, decay, sustain, release] * rrand(envTimeRandMin, envTimeRandMax);
	envCurves = [curve, curve / 3.0, curve / 1.5, curve.neg];
	osca = osca * EnvGen.ar(Env(envLevels, envTimes, envCurves), doneAction: 2);
	oscb = oscb * EnvGen.ar(Env(envLevels, envTimes, envCurves));
	oscc = oscc * EnvGen.ar(Env(envLevels, envTimes, envCurves));
	oscd = oscd * EnvGen.ar(Env(envLevels, envTimes, envCurves));

	sig = HPF.ar(
		[osca, oscb, oscc, oscd].tanh * SinOsc.ar(mod).range(ampModMin, ampModMax),
		EnvGen.ar(Env(hpfEnvLevels, [attack, decay, sustain, release]))
	);

	Out.ar(0, sig[0]);
	Out.ar(2, sig[1]);
	Out.ar(4, sig[2]);
	Out.ar(6, sig[3]);
}).play(args: [\freqFrom, rrand(884.64,884.64), \freqTo, rrand(884.64,884.64), \modFrom, rrand(10,25), \modTo, rrand(10,25)]);

)

// VAR A - Beating VOsc cluster: each frequency gets its own VOsc; since they are so close, the natural beating between voices dominates the texture; very slow wavetable drift, long envelopes.

(

{
	var wtName = "SineDelicateHarmonics";
	var freqs = ~wtfreqs ++ (~wtfreqs * 0.5);
	var numFreqs = freqs.size;
	var lo = freqs.minItem;
	var hi = freqs.maxItem;

	var sig = freqs.collect { |f, i|
		var bufindex = LFNoise2.kr(rrand(0.05, 0.15)).range(0, 5) + ~wtb[wtName].bufnum;
		var fadeIn = rrand(5, 12);
		var sustain = rrand(8, 18);
		var fadeOut = rrand(6, 15);
		var env = EnvGen.ar(Env([0, 1, 1, 0], [fadeIn, sustain, fadeOut], [5, -5]));
		var ampMod = LFDNoise3.ar(rrand(0.05, 0.3)).range(0.0, 1.0);
		VOsc.ar(bufindex, f * LFNoise2.ar(0.002).range(0.998, 1.002)) / numFreqs * env * ampMod;
	};

	numFreqs.do { |i|
		Out.ar(i.mod(8), sig[i] * 0.4);
	};

	Silent.ar;
}.play

)

// VAR D - BBandPass: cluster as filter bank; broadband VOsc filtered through BPF at each cluster freq; the tight spacing creates an almost continuous resonant band.

(

{
	var wtName = "POS_ClippDivPoly";
	var bw = 0.04;
	var amp = 8;
	var numFreqs = ~wtfreqs.size;
	var chaos = LFNoise1.ar(0.3).range(0, 3);
	var bufindex = ~wtb[wtName].bufnum + chaos;
	var src = VOsc.ar(bufindex, 30);

	var bands = ~wtfreqs.collect { |f, i|
		BBandPass.ar(src, f, bw,
			LFDNoise3.ar(rrand(0.05, 0.2)).range(0.0, 1.0)
			* EnvGen.ar(Env([1,1,0], [20,5 + 10.rand]),doneAction:2);
		);
	};

	numFreqs.do { |i|
		var env = EnvGen.ar(Env([0, 1, 1, 0],
			[rrand(3, 8), rrand(12, 20), rrand(6, 12)], [5, -5]));
		Out.ar(i.mod(8), bands[i] * amp * env);
	};

	Silent.ar;
}.play

)

// VAR E - Resonz halo in the cluster zone: very narrow Resonz filters at cluster frequencies; since the cluster is tight, this produces a shimmering band of pitch rather than separated tones.

(

{
	var wtName = "SharpPolynomial";
	var numFreqs = ~wtfreqs.size;
	var chaos = LFNoise2.ar(0.05).range(0, 3);
	var bufindex = ~wtb[wtName].bufnum + chaos;
	var src = VOsc.ar(bufindex, 25) * 0.4;
	var bw = 0.003;

	var resonated = ~wtfreqs.collect { |f, i|
		var bandAmp = LFNoise2.ar(rrand(0.02, 0.08)).range(0.0, 1.5);
		var drift = LFNoise2.ar(0.003).range(0.998, 1.002);
		Resonz.ar(src, f * drift, bw) * bandAmp;
	};

	numFreqs.do { |i|
		var env = EnvGen.ar(Env([0, 1, 1, 0],
			[rrand(5, 10), rrand(12, 20), rrand(8, 14)], [4, -4]));
		Out.ar(i.mod(8), HPF.ar(resonated[i], 40) * 18 * env);
	};

	Silent.ar;
}.play

)
