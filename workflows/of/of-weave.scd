// of-weave.scd
// fern woven against sedge through the OF processing library. Run of-setup.scd first.

( // plain pair
a = ~gen.(\fern).play;
b = ~gen.(\sedge).play;
)

// .stack replaces the filter chain, .transform appends a stage
a.stack([\bfold, \drift], o);
b.stack([\fshift], o);

a.transform( o.processing.dualdist );
b.transform( o.processing.gravch );

// preset-jump functions
(
~fernStates = ~stateFor.(a, \fern);
~sedgeStates = ~stateFor.(b, \sedge);
("fern states: " ++ ~fernStates.size ++ "   sedge states: " ++ ~sedgeStates.size).postln;
)

// scripted pass through states
(
TF(\weaveIntro, {
	0.5.wait; "0".postln;
	~fernStates.first.value; ~sedgeStates.first.value;
	8.wait; "1".postln;
	~fernStates.wrapAt(1).value; ~sedgeStates.wrapAt(2).value;
	8.wait; "2".postln;
	~fernStates.wrapAt(3).value; ~sedgeStates.wrapAt(1).value;
	8.wait; "3".postln;
	~fernStates.wrapAt(5).value; ~sedgeStates.wrapAt(4).value;
	8.wait; "4".postln;
}).play;
)

// random preset jumps until Tdef(\weave).stop
(
Tdef(\weave, {
	inf.do {
		~fernStates.choose.value;
		~sedgeStates.choose.value;
		"weave".postln;
		[6, 8, 10, 14].choose.wait;
	}
}).play;
)

Tdef(\weave).stop;

( // back to silence
~free.(\fern); ~free.(\sedge);
)
