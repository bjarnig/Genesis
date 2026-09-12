// fader-specs.scd
// The fader range for every parameter of every process: min, max, warp, step and
// the Ndef's own default. One evaluable block, so both the fader GUI and the
// preset morpher can have it without opening a window.
//
//   ControlSpec(min, max, warp, step, default)
//
// This is the file to edit when a knob feels too narrow. A parameter left out of
// a table gets no fader and keeps whatever the Ndef starts it at.

(
~specs = ~specs ? ();

~specs[\fern] = (
	// knumFrom / knumTo are deliberately absent: Cyclegen fixes knum when the synth
	// is built, so they only bite on the next ~gen.(\fern), not on a fader move.
	lfnFreq:    ControlSpec(0.005, 40, \exp, 0, 0.25),
	repeats:    ControlSpec(1, 16, \lin, 1, 1),
	freqMult:   ControlSpec(0.25, 10, \exp, 0, 1),
	harmScale:  ControlSpec(0.02, 4, \exp, 0, 0.0625),
	ampStep:    ControlSpec(0.0, 1.0, \lin, 0, 0.8),
	stiffness:  ControlSpec(0.0, 1.0, \lin, 0, 0.05),
	ampStepB:   ControlSpec(0.0, 1.0, \lin, 0, 0.45),
	stiffnessB: ControlSpec(0.0, 1.0, \lin, 0, 0.03),
	detuneHi:   ControlSpec(0.0, 4.0, \lin, 0, 0.2),
	detuneLo:   ControlSpec(0.0, 0.95, \lin, 0, 0.2),
	amp:        ControlSpec(0, 1, \amp, 0, 0.7)
);

~specs[\moss] = (
	lfnFreq:   ControlSpec(0.02, 40, \exp, 0, 5),
	mod:       ControlSpec(1, 200, \exp, 0, 20),
	from:      ControlSpec(1, 40, \exp, 0, 9),
	to:        ControlSpec(1, 60, \exp, 0, 12),
	freqFrom:  ControlSpec(1, 500, \exp, 0, 10),
	freqTo:    ControlSpec(100, 8000, \exp, 0, 1000),
	jitter:    ControlSpec(0.0, 1.0, \lin, 0, 0.5),
	ampStep:   ControlSpec(0.0, 1.0, \lin, 0, 0.2),
	duty:      ControlSpec(0.0, 1.0, \lin, 0, 0.4),
	hpf:       ControlSpec(20, 2000, \exp, 0, 40),
	sdm:       ControlSpec(1, 60, \exp, 0, 10),
	grainGain: ControlSpec(0, 4, \amp, 0, 0.5),
	amp:       ControlSpec(0, 1, \amp, 0, 0.7)
);

~specs[\sedge] = (
	sdm:        ControlSpec(1, 40, \exp, 0, 10),
	ffrom:      ControlSpec(1, 200, \exp, 0, 10),
	fto:        ControlSpec(10, 800, \exp, 0, 100),
	noiseRate:  ControlSpec(1, 200, \exp, 0, 50),
	bsRate:     ControlSpec(0.05, 10, \exp, 0, 0.8),
	bsLo:       ControlSpec(100, 4000, \exp, 0, 600),
	bsHi:       ControlSpec(200, 8000, \exp, 0, 1200),
	frequencyB: ControlSpec(0.0, 1.0, \lin, 0, 0.01),
	surface:    ControlSpec(0.0, 1.0, \lin, 0, 0.2),
	lop:        ControlSpec(1000, 20000, \exp, 0, 18000),
	hip:        ControlSpec(20, 2000, \exp, 0, 20),
	hpf:        ControlSpec(20, 2000, \exp, 0, 50),
	lopVol:     ControlSpec(0.0, 1.0, \lin, 0, 0.5),
	hipVol:     ControlSpec(0.0, 1.0, \lin, 0, 0.5),
	amp:        ControlSpec(0, 1, \amp, 0, 0.7)
);

~specs[\nettle] = (
	a:       ControlSpec(0.0, 1.0, \lin, 0, 0.5),
	b:       ControlSpec(0.0, 1.0, \lin, 0, 0.5),
	c:       ControlSpec(0.0, 1.0, \lin, 0, 0.5),
	pmFreq:  ControlSpec(1, 100, \exp, 0, 10),
	modFrom: ControlSpec(10, 500, \exp, 0, 50),
	wobLo:   ControlSpec(100, 2000, \exp, 0, 500),
	wobHi:   ControlSpec(200, 4000, \exp, 0, 800),
	filtLo:  ControlSpec(1000, 15000, \exp, 0, 8000),
	filtHi:  ControlSpec(5000, 20000, \exp, 0, 19000),
	hpf:     ControlSpec(20, 2000, \exp, 0, 30),
	demGain: ControlSpec(0.5, 12, \exp, 0, 4),
	amp:     ControlSpec(0, 1, \amp, 0, 0.7)
);

~specs[\bramble] = (
	sdm:     ControlSpec(0.25, 8, \exp, 0, 1),
	repeats: ControlSpec(1, 16, \lin, 1, 2),
	from:    ControlSpec(1, 40, \exp, 0, 1),
	to:      ControlSpec(2, 80, \exp, 0, 20),
	mod:     ControlSpec(1, 200, \exp, 0, 40),
	rate:    ControlSpec(0.5, 60, \exp, 0, 12),
	trigMin: ControlSpec(10, 400, \exp, 0, 40),
	trigMax: ControlSpec(200, 4000, \exp, 0, 1000),
	freq:    ControlSpec(100, 8000, \exp, 0, 1000),
	mf:      ControlSpec(0.0, 1.0, \lin, 0, 0.3),
	bw:      ControlSpec(1, 40, \exp, 0, 12),
	hpf:     ControlSpec(20, 2000, \exp, 0, 40),
	amp:     ControlSpec(0, 1, \amp, 0, 0.7)
);

~specs[\clover] = (
	ser:       ControlSpec(50, 2000, \exp, 0, 500),
	sdm:       ControlSpec(0.5, 10, \exp, 0, 2.5),
	step:      ControlSpec(0.1, 10, \exp, 0, 2.5),
	brownLo:   ControlSpec(0.5, 20, \exp, 0, 1),
	brownHi:   ControlSpec(1, 40, \exp, 0, 7),
	mf:        ControlSpec(0.001, 0.05, \exp, 0, 0.008),
	stepsGain: ControlSpec(0.0, 1.0, \lin, 0, 0.3),
	amp:       ControlSpec(0, 1, \amp, 0, 0.7)
);

~specs[\thistle] = (
	modFreq: ControlSpec(0.01, 4, \exp, 0, 0.1),
	modFrom: ControlSpec(1, 40, \exp, 0, 5),
	modTo:   ControlSpec(2, 60, \exp, 0, 7),
	ser:     ControlSpec(50, 2000, \exp, 0, 600),
	step:    ControlSpec(0.1, 10, \exp, 0, 2.5),
	brownLo: ControlSpec(0.5, 20, \exp, 0, 1),
	brownHi: ControlSpec(1, 40, \exp, 0, 7),
	sdm:     ControlSpec(0.1, 4, \exp, 0, 0.5),
	mf:      ControlSpec(0.001, 0.05, \exp, 0, 0.008),
	amp:     ControlSpec(0, 1, \amp, 0, 0.7)
);

~specs[\yarrow] = (
	fspeed:  ControlSpec(1, 100, \exp, 0, 20),
	fcenter: ControlSpec(40, 2000, \exp, 0, 200),
	sdm:     ControlSpec(0.02, 2, \exp, 0, 0.1),
	mfreq:   ControlSpec(0.001, 1, \exp, 0, 0.01),
	filtBw:  ControlSpec(1, 40, \exp, 0, 6),
	modFreq: ControlSpec(0.5, 40, \exp, 0, 5),
	harms:   ControlSpec(10, 400, \exp, 0, 120),
	drive:   ControlSpec(1, 40, \exp, 0, 10),
	bsRate:  ControlSpec(0.5, 40, \exp, 0, 5),
	bsLo:    ControlSpec(50, 2000, \exp, 0, 100),
	bsHi:    ControlSpec(1000, 16000, \exp, 0, 8000),
	lpf:     ControlSpec(2000, 20000, \exp, 0, 12000),
	hpf:     ControlSpec(20, 2000, \exp, 0, 30),
	amp:     ControlSpec(0, 1, \amp, 0, 0.7)
);

~specs[\gorse] = (
	// a, b and c are floored: at 0 they mute or freeze the plane layer, and
	// randomize would keep landing on those duds
	a:        ControlSpec(0.05, 1.0, \lin, 0, 0.5),
	b:        ControlSpec(0.05, 1.0, \lin, 0, 0.5),
	c:        ControlSpec(0.05, 4.0, \exp, 0, 0.5),
	sawFreq:  ControlSpec(20, 4000, \exp, 0, 100),
	feedback: ControlSpec(0.99, 1.0003, \lin, 0, 1.0002),
	delay:    ControlSpec(0.0002, 0.2, \exp, 0, 0.02),
	aa:       ControlSpec(0.25, 200, \exp, 0, 15),
	bb:       ControlSpec(0.25, 200, \exp, 0, 10),
	peakFreq: ControlSpec(200, 16000, \exp, 0, 4000),
	peakGain: ControlSpec(-24, 12, \lin, 0, -3),
	hpf:      ControlSpec(50, 8000, \exp, 0, 2000),
	fbGain:   ControlSpec(0, 2, \amp, 0, 0.1),
	amp:      ControlSpec(0, 1, \amp, 0, 0.7)
);

~specs[\teasel] = (
	// carrier, sdm and gateRate were hardcoded: they are what sets the pitch here
	carrier:     ControlSpec(0.5, 200, \exp, 0, 1),
	sdm:         ControlSpec(0.02, 40, \exp, 0, 0.15),
	gateRate:    ControlSpec(0.05, 20, \exp, 0, 1),
	modRate:     ControlSpec(0.1, 200, \exp, 0, 10),
	modFrom:     ControlSpec(5, 4000, \exp, 0, 100),
	modTo:       ControlSpec(200, 20000, \exp, 0, 10070),
	peakFreq:    ControlSpec(100, 8000, \exp, 0, 400),
	lpf:         ControlSpec(200, 18000, \exp, 0, 1070),
	hpf:         ControlSpec(20, 2000, \exp, 0, 30),
	sparkleGain: ControlSpec(0.0, 2.0, \amp, 0, 0.4),
	demGain:     ControlSpec(0.1, 16, \exp, 0, 2),
	amp:         ControlSpec(0, 1, \amp, 0, 0.7)
);

("fader-specs: " ++ ~specs.size ++ " tables").postln;
)
