////////////////////////////////////////////////////////////////
//
//                         SHIFT
//
////////////////////////////////////////////////////////////////

(

Tdef(\mist, {

	inf.do {

OraPlay(Ora(~f).expand(amount: 1.3), numChannels: 2)
	.clusterGrad(
		ampFrom: 0.02, ampTo: 0.08,
		durFrom: 6, durTo: 12,
		synthdef: \drclick,
		offsetFrom: 0.08, offsetTo: 0.3,
		ampComp: 1.0
	);

		5.wait;
	}

}).play;

)

(

Tdef(\oraa, {

	8.do {
		~o = Ora(~f).centroidDilation(1.5); OraPlay(~o.items, numChannels: 8).cluster(0.2, 4, \drsoft, 0.25);
		rrand(6,8).wait;
		~o = Ora(~f).warp(curve: 2.0); OraPlay(~o.items, numChannels: 8).cluster(0.1, 4, \drsoft, 0.25);
		rrand(6,8).wait;
	};

}).play

)

(

f = ~f5;
t = 5.0;
i = \drnoise;

Tdef(\mist, {

	inf.do {

		// Ascending cluster
		OraPlay(f, numChannels: 8).cluster(0.5, 4, i, 0.15);
		t.wait;

		// Descending
		OraPlay(f, numChannels: 8).reverse(0.6, 4, i, 0.15);
		t.wait;

		// Random order
		OraPlay(f, numChannels: 8).random(0.5 
		, 4, i, 0.15);
		t.wait;

		// From center outward
		OraPlay(f, numChannels: 8).fromCenter(0.4, 5, i, 0.18);
		t.wait;

	}

}).play

)

(

f = ~f;
t = 5.0;
i = \drnoise;

Tdef(\mist, {

	inf.do {

		// Dense cloud
		OraPlay(f, numChannels: 8).dense(0.3, 6, i, 0.4);
		t.wait;

		// Sparse irregular timing
		OraPlay(f, numChannels: 8).sparse(0.5, 5, i, 0.3, 1.2);
		t.wait;

		// Simultaneous pairs
		OraPlay(f, numChannels: 8).pairs(0.6, 4, i, 0.3);
		t.wait;

		// Wave (ascending then descending)
		OraPlay(f, numChannels: 8).wave(0.7, 4, i, 0.12);
		t.wait;
	}

}).play

)


(

var durs = Pseq([
	Pseq([0.25], 24),
	Pseq([0.24], 16),
	Pseq([0.23], 24),
	Pseq([0.22], 32),
], inf).asStream;

var durs2 = Pseq([
	Pseq([0.21], 24),
	Pseq([0.20], 16),
	Pseq([0.19], 24),
	Pseq([0.18], 32),
], inf).asStream;

var count = 0;


~o = Ora(~f).centroidDilation(1.5);

Tdef(\orab, {

	 Date.getDate.postln;

	"section - a".postln;

	64.do {

	OraPlay(~o, numChannels: 8).cluster(0.075, 4, \drcl, 0.8, ampComp: 1.0);
		durs.next.wait;
		count.postln;
		count = count + 1;
	};

	~o = Ora(~f).centroidDilation(1.5); ~o2 = Ora(~f * 0.5).centroidDilation(1);

	"section - b".postln;

	64.do {
		OraPlay(~o, numChannels: 8).cluster(0.075, 4, \drcl, 0.8, ampComp: 1.0);
		OraPlay(~o2, numChannels: 8).cluster(0.075, 4, \drcl, 0.8, ampComp: 1.0);
		durs.next.wait;
		count.postln;
		count = count + 1;
	};

	~o = Ora(~f).centroidDilation(1.05); ~o2 = Ora(~f * 0.5).centroidDilation(1.125);

	"section - c".postln;

	64.do {
		OraPlay(~o, numChannels: 8).cluster(0.075, 4, \drclshort, 0.8, ampComp: 1.0);
		OraPlay(~o2, numChannels: 8).cluster(0.075, 4, \drclshort, 0.8, ampComp: 1.0);
		durs2.next.wait;
		count.postln;
		count = count + 1;
	};

	~o = Ora(~f*0.5).centroidDilation(0.5); ~o2 = Ora(~f * 0.25).centroidDilation(2);

	"section - d".postln;

	64.do {
		OraPlay(~o, numChannels: 8).cluster(0.075, 4, \drclshort, 0.8, ampComp: 1.0);
		OraPlay(~o2, numChannels: 8).cluster(0.075, 4, \drclshort, 0.8, ampComp: 1.0);
		durs2.next.wait;
		count.postln;
		count = count + 1;
	};

	Date.getDate.postln;

}).play

)

(

Tdef(\orac, {

	8.do {

		~o = Ora(~f).shatter(pieces: 3, spread: 0.06); OraPlay(~o.items, numChannels: 8).clusterGrad(
		ampFrom: 0.02, ampTo: 0.08,
		durFrom: 6, durTo: 12,
		synthdef: \drclick,
		offsetFrom: 0.08, offsetTo: 0.3,
		ampComp: 1.0
	);
		rrand(4,6).wait;

	};


}).play


)

(

Tdef(\orac, {

	8.do {

		~o = Ora(~f).chaos(0.4); OraPlay(~o.items, numChannels: 8).clusterGrad(
		ampFrom: 0.02, ampTo: 0.08,
		durFrom: 6, durTo: 12,
		synthdef: \drclick,
		offsetFrom: 0.08, offsetTo: 0.3,
		ampComp: 1.0
	);
		rrand(4,6).wait;
	};

}).play

)