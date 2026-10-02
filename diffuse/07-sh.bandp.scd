////////////////////////////////////////////////////////////////
//
//              Bandpass filtering (Ora-driven)
//
////////////////////////////////////////////////////////////////



// #1 - One filter per frequency, one output per filter: each Ora frequency becomes a bandpass channel; amplitude modulation speed varies per band.

(

{
	var speed = 1.0;
	var bw = 0.2;
	var snd = PlayBuf.ar(1, ~s3m, loop: 1);
	var amp = 10;
	var numFreqs = ~bpfreqs.size;
	var bands;

	bands = ~bpfreqs.collect { |f, i|
		var modSpeed = (i + 1) / numFreqs * 10.4.rand * speed;
		BBandPass.ar(snd, f, bw, LFNoise1.ar(modSpeed).range(0.0, 1.0))
		* EnvGen.ar(Env([1,1,0], [20,5 + 10.rand]),doneAction:2);
	};

	// Each band to its own output channel
	numFreqs.do { |i|
		Out.ar(i, bands[i] * amp);
	};

	Silent.ar; // SynthDef needs an output
}.play

)


// #2 - Ora-clustered filters: each frequency gets a small cluster of sub-bands around it (frequency +/- jitter); creates a richer, wider spatial image per band.

(

{
	var speed = 0.5;
	var bw = 0.05;
	var amp = 8;
	var clusterSize = 3; // sub-bands per Ora frequency
	var jitter = 0.05;   // frequency spread (ratio)
	var snd = PlayBuf.ar(1, ~s1m, loop: 1);
	var numFreqs = ~bpfreqs.size;
	var bands;

	bands = ~bpfreqs.scramble.collect { |f, i|
		var subFreqs = clusterSize.collect { |j| f * rrand(1 - jitter, 1 + jitter) };
		var modSpeed = rrand(0.01, 10.15) * speed;
		BBandPass.ar(snd, subFreqs, bw, LFNoise1.ar(modSpeed).range(0.0, 1.0)).sum
		* EnvGen.ar(Env([0,1,1,0],[rrand(3,5), rrand(7,11), rrand(7,11)], [5,1,-5]))
	};

	numFreqs.do { |i|
		Out.ar(i, bands[i] * amp);
	};

	Silent.ar;
}.play

)


// #3 - Ora-driven 8-channel decomposition: frequency array padded/wrapped to 8 channels; sine amplitude modulation at different rates per band; optional Ora transforms applied before filtering.

(

{
	var speed = 1.0;
	var bw = 0.1;
	var amp = 10;
	var numChans = 8;
	var snd = PlayBuf.ar(1, ~s4m, loop: 1);
	var freqs = ~bpfreqs.wrapExtend(numChans);
	var bands;

	bands = freqs.collect { |f, i|
		var modSpeed = [0.01, 0.05, 0.1, 0.2, 0.03, 0.08, 0.15, 0.25].wrapAt(i) * speed;
		BBandPass.ar(snd, f, bw, SinOsc.ar(modSpeed).range(0.0, 1.0));
	};

	numChans.do { |i|
		Out.ar(i, bands[i] * amp);
	};

	Silent.ar;
}.play

)


// #4 - Ora transform chain: filter bank with live transform; apply Ora transformations to the frequency array, then use the result as BBandPass centers; shows how to chain multiple transforms before spatialization.

(

{
	var speed = 0.8;
	var bw = 0.12;
	var amp = 8;
	var numChans = 8;
	var snd = PlayBuf.ar(1, ~s2m, loop: 1);
	// Transform: expand intervals, then add formant gap, then detune slightly
	var freqs = Ora(~bpfreqs).expand(amount: 1.3).formantGap(800, 200, 0.2).detune(2).asArray;
	var bands;

	freqs = freqs.wrapExtend(numChans);

	bands = freqs.collect { |f, i|
		var modSpeed = LFNoise2.kr(0.1).range(0.01, 0.2) * speed;
		BBandPass.ar(snd, f.clip(20, 18000), bw,
			LFNoise1.ar(modSpeed).range(0.0, 1.0)
		);
	};

	numChans.do { |i|
		Out.ar(i, bands[i] * amp);
	};

	Silent.ar;
}.play

)

(

	var freqs = ~bpfreqs.wrapExtend(8);

	// var ora = Ora(freqs).intervalFlow();
	// OraPlay(ora, numChannels:2).clusterGrad(0.25, 0.1, 2, 8, \drpm, 0.2, 2.5, 1.0);


	Ndef(\ldst, {|speed=1.0, bw=0.1, amp=5|
		var snd = BrownNoise.ar(0.2);

		var bp1 = BBandPass.ar(snd, freqs[0], bw, SinOsc.ar(0.01*speed).range(0.0,1.0));
		var bp2 = BBandPass.ar(snd, freqs[1], bw, SinOsc.ar(0.05*speed).range(0.0,1.0));
		var bp3 = BBandPass.ar(snd, freqs[2], bw, SinOsc.ar(0.1*speed).range(0.0,1.0));
		var bp4 = BBandPass.ar(snd, freqs[3], bw, SinOsc.ar(0.2*speed).range(0.0,1.0));
		var bp5 = BBandPass.ar(snd, freqs[4], bw, SinOsc.ar(0.01*speed).range(0.0,1.0));
		var bp6 = BBandPass.ar(snd, freqs[5], bw, SinOsc.ar(0.05*speed).range(0.0,1.0));
		var bp7 = BBandPass.ar(snd, freqs[6], bw, SinOsc.ar(0.1*speed).range(0.0,1.0));
		var bp8 = BBandPass.ar(snd, freqs[7], bw, SinOsc.ar(0.2*speed).range(0.0,1.0));
		[bp1,bp2,bp3,bp4,bp5,bp6,bp7,bp8] * XLine.ar(0.0001, 1.0, 3)
	}).play;

	)