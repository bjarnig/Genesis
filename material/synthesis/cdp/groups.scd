// groups.scd, written by Tools/genesis-corpus/group-material.py
// One entry per group: its folder, its files, the CDP processes it
// suits, and cyclecnt sized from the group's own median wavecycle.
~cdpgroups = (
	thin: (
		folder: "/Users/bjarni/Works/Pieces/Genesis/material/synthesis/cdp/thin/",
		files: ['sedge03-4', 'moss05-2', 'bramble05-3', 'gorse05-2', 'bramble06-4'],
		processes: ["distort delete 2", "distort omit", "distort telescope"],
		cycHz: 9600.0, cycMedian: 5.0,
		cyclecnt: (ms8: 77, ms30: 288, ms120: 1152, ms400: 3840),
		why: "shortest wavecycles: dense and bright, so take cycles away"
	),
	pitchy: (
		folder: "/Users/bjarni/Works/Pieces/Genesis/material/synthesis/cdp/pitchy/",
		files: ['bramble04-3', 'moss05-4', 'teasel06-4', 'bramble01-3', 'moss02-2'],
		processes: ["distort pitch", "distort reform 1", "distort filter 1"],
		cycHz: 6400.0, cycMedian: 7.5,
		cyclecnt: (ms8: 51, ms30: 192, ms120: 768, ms400: 2560),
		why: "brightest: pitchwarping the cycles stays audible"
	),
	scatter: (
		folder: "/Users/bjarni/Works/Pieces/Genesis/material/synthesis/cdp/scatter/",
		files: ['yarrow03-2', 'moss08-3', 'sedge01-3', 'teasel01-3', 'yarrow04-4'],
		processes: ["distort shuffle", "extend scramble 1", "distshift distshift 1"],
		cycHz: 6000.0, cycMedian: 8.0,
		cyclecnt: (ms8: 48, ms30: 180, ms120: 720, ms400: 2400),
		why: "busiest: reordering needs events to reorder"
	),
	shape: (
		folder: "/Users/bjarni/Works/Pieces/Genesis/material/synthesis/cdp/shape/",
		files: ['moss03-1', 'nettle06-1', 'teasel07-2', 'bramble07-4', 'yarrow05-1'],
		processes: ["distort envel 1", "distort envel 2", "distort envel 3"],
		cycHz: 1500.0, cycMedian: 32.0,
		cyclecnt: (ms8: 12, ms30: 45, ms120: 180, ms400: 600),
		why: "peakiest: a per-group envelope has something to bite on"
	),
	stretch: (
		folder: "/Users/bjarni/Works/Pieces/Genesis/material/synthesis/cdp/stretch/",
		files: ['ferna04-2', 'moss06-2', 'teasel02-2', 'clover05-3', 'yarrow05-3'],
		processes: ["distort repeat", "distort repeat2", "distort replim"],
		cycHz: 203.4, cycMedian: 236.0,
		cyclecnt: (ms8: 2, ms30: 6, ms120: 24, ms400: 81),
		why: "longest wavecycles: repeating them reads as granular stretch"
	),
	rough: (
		folder: "/Users/bjarni/Works/Pieces/Genesis/material/synthesis/cdp/rough/",
		files: ['clover03-2', 'bramble08-4', 'teasel03-4', 'moss07-1', 'nettle02-2'],
		processes: ["distort fractal", "distort overload 1", "distort harmonic"],
		cycHz: 137.5, cycMedian: 349.0,
		cyclecnt: (ms8: 1, ms30: 4, ms120: 17, ms400: 55),
		why: "most tonal: there is room to put grit inside the cycles"
	),
);
