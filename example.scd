// example.scd
// The whole folder in the order it wants to be run. One block at a time.
// Nothing makes a sound until you ask for it: the library instantiates a process
// into its own bus, and only .play puts a monitor on the hardware.

( // 1. load everything (run once)
~here = "/Users/bjarni/Works/Pieces/Genesis/";
(~here ++ "core/material-library.scd").load;   // ~material, ~gen, ~play, ~solo, ~free, ~loaded
(~here ++ "core/fader-specs.scd").load;        // ~specs, the fader range per parameter
(~here ++ "core/ndef-faders.scd").load;        // ~ndefFaders
(~here ++ "core/preset-morph.scd").load;       // ~loadPresets, ~morphCurves, ~presetMorph
~presets = ~loadPresets.(~here ++ "core/presets.scd");
~faders = ~faders ? ();
~material.keys.asArray.sort.postln;       // what is on offer
)


( // 2. hear one process
~play.(\gorse);
)


( // 3. faders for it, with the randomize distributions and reset
~faders[\gorse] = ~ndefFaders.(~gen.(\gorse), ~specs[\gorse]);
)


( // 4. morph between the presets you posted from that window
~morph = ~presetMorph.(~gen.(\gorse), ~presets[\gorse], ~specs[\gorse]);
)


( // 5. or drive the morph from code
~morph.go(3, \zigzag, 20);   // to preset 3, zigzagging, over 20 seconds
)


( // 6. back to no synths
~free.();
)


// 7. or send the material into a workflow instead. Each is its own file with
//    its own source and blocks to run in order, so open one and work down it.
//    They are block-by-block files like this one, not things to .load.
//    All five live in workflows/.
//
//      wf-granulation.scd   ring buffer -> a family of grain readers
//      wf-sediment.scd      the Sediment granulators, chained and cross-driven
//      wf-waveset.scd       waveset distortion off a live ring
//      wf-feedback.scd      a self-regulating feedback network
//      wf-resonance.scd     a resonator bank tuned by the material


/*  the rest of it, once the above makes sense

~solo.(\teasel);              // free everything else and play this one
~free.(\gorse);               // one process back to sleep
~loaded;                      // what is instantiated right now

~faders[\gorse].randomize(\beta);    // uni, beta, exp, walk
~faders[\gorse].resetAll;            // every fader back to the Ndef's own default
~faders[\gorse].printState;          // print the state; paste it into core/presets.scd

~morph.place(0.5);            // sit between the two presets by hand
~morph.cancel;                // abandon a morph in progress
~morphCurves.keys;            // jump hold linear smooth accel decel zigzag steps scatter

*/
