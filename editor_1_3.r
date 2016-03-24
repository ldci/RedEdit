#! /usr/local/bin/rebol
REBOL [
	Title: "Red Cross-Platform Code Editor 1.3"
	File: "editor.r"
	Author: "Francois Jouen(LDCI)"
	Version: 2.0
	Date: "03-24-16"
	Email: "francois.jouen@ephe.sorbonne.fr"
	Copyright: "Red Language"
	Rights: {BSD License
�
Copyright (c) 2011-2016, Red Language
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.

    * Neither the name of the <ORGANIZATION> nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.}
]



sv*: system/view
ssize: sv*/screen-face/size
xmax: ssize/1 - 300
ymax: ssize/2 - 300

xmax: 1024
ymax: 600; 768
y1: ((ymax / 3) * 2)
y2: (ymax / 3)


set 'appDir what-dir

sourceDir: join appDir "template/"
docDir: join appDir "doc/"
binaryDir: join appDir "binaries/"
redExec: join appDir "binaries/red"
empty: join sourceDir "basic.reds"
helperMaker: join docDir "makedoc2.r" 
helperTxt: join docDir "red-system-specs.txt"
helper: join docDir "red-system-specs.html"


if not exists? helperMaker [ 
	flash "Downloading makedoc2.r..."
	read-thru/to http://www.rebol.org/library/scripts/makedoc2.r helperMaker
	unview
]

if not exists? helper  [do/args helperMaker helperTxt]
change-dir appDir

targets: ["Darwin" "Linux" "Windows" "MSDOS" "Syllable" "Android"]
;compilation default options
debug: "No"
Verbose: "No"
Verbose_Level: 1


;compilerArgs: join " -v " [ Verbose_Level " -g -t "]

ccok: false
fName: fPath: sFname: "";

count: tnLines: nChar: tnPages: tnWords: tnParas: tnFiles: tnChars: nPage: 0
nLine: pIndex: nLinePage: tnPages: nChar: 1
fontSize: 14
lineHeight: 16
tmpList: []
tmpFiles: []
xy: 0x35

cx: 35
cy: lineHeight + 4
bxs: to-pair reduce [cx cy]

line-list: make sv*/line-info []

; to highlight our text cursor
tr: 128
cl: to-tuple reduce [101 98 95 tr]
lCursor: copy [ fill-pen cl
				pen none
				box 0x0 bxs ]
 
 
windowStyles: stylize [
        app-btn: btn 0.0.0 font [colors: [255.255.255 255.255.255]] bold
        app-sld: slider 0.0.0 255.255.255 edge [size: 1x1]
        app-status: text 0.0.0 229.227.218 no-wrap
        app-info: info 101.98.95 101.98.95 font [color: 255.255.255] bold 
        	edge [size: 0x0] para [ origin: 6x2]
        app-fld:  field 101.98.95 101.98.95 font [color: 255.255.255] bold 
        	edge [size: 0x0] para [ origin: 6x2]
]

 
 	

getOs: does [
	switch system/version/4 [
		3 [os: "Windows" compilerTarget: fourth targets] ; msdos console by defaut for tests
		2 [os: "Mac OS X" compilerTarget: first targets]
		4 [os: "Linux"  compilerTarget: second targets]
		5 [os: "BeOS" compilerTarget: fifth targets]
		7 [os: "NetBSD" compilerTarget: second targets]
		9 [os: "OpenBSD" compilerTarget: second targets]
		10 [os: "SunSolaris" compilerTarget: second targets]
	]
	return os
]
 	
GetOs
compilerArgs: join "-c -t " compilerTarget

quitRequested: does [
	if (confirm/with "Really quit Red Editor ?" ["Yes" "No"]) [quit]
	
]

; compilation
redCompile: does [
	ccok: false
	clear console/text
	console/line-list: none
	show console
	change-dir to-file fPath
	if error? try [
			str: join "Compiling " fname
			fl: flash str wait 0.1
			buffer: copy ""
			cmdstr: join compilerArgs [" " sFName]
			call/show/output reduce [redExec " " cmdstr] buffer
	 		console/text: join "Script:" buffer 
			unview/only fl 
			ccok: true 
			] 
			[unview/only fl]
	
	 
	 if ccok [ append console/text "Compilation, Linking and Buiding are done :)"]
	 sl2/data: 1        
	 scroll-para console sl2
	 show [console sl2]
	 change-dir appDir
]


; execute
redRun: does [
	; compilation OK?
	change-dir to-file fPath
	either ccok [
				
				tmp: parse sFName "."
				exec: first tmp
				; with mac call open allows a new terminal
				either compilerTarget = "Darwin" [prog: join "open " exec] [prog: exec]
				if error? try [
								str: join "Loading " exec
								fl: flash str wait 0.1
								call/show reduce [prog]
								unview/only fl] 
				[unview/only fl]
	] [Alert "File not compilated!"]
	change-dir appDir
]




calculatePages: does [
	clear lcount/text
	;calculate line height
	lineHeight: fontSize + second (current/para/margin) 
	
	;calculate total number of lines
	tmp: (second (size-text current) / lineHeight) - 2
	for count 0 tmp 1 [append lcount/text join count + 1 newline]
	append lcount/text tmp + 2
	tnLines: tmp + 1
	;get number of line per page
	nLinePage: round (current/size/y / lineHeight) 
	
	;get total number of pages 
	tnPages: round tnLines / nLinePage
	tmp: remainder tnLines nLinePage
	if tmp  <> 0 [tnPages: tnPages + 1]
	tnChars: to-integer length? current/text
	tnPages: tnPages + 1
	show [Lcount]
]

updateText: does [
	buffer: copy current/text
	if (tnFiles > 0) [poke tmpFiles pIndex buffer]
]

getFileInfo: does [
	 calculatePages
	 nPage: 0
	 current/text: head current/text
	 lcount/text: head lcount/text
	 current/line-list: lcount/line-list: none
	 ; get some information about file
	 tnChars: length? current/text
	 tnWords: parse current/text none
	 tnParas: parse/all current/text "^/"
	 SBar2/text: join "Length: " tnChars
	 nLine: nChar: 0
	 if error? try [result: textinfo current line-list nLine] [result: none]
	 sbar3/text: join "Ln " [nLine + 1 ", " line-list/num-chars " chars"]
	 sbar4/text: nPage + 1
	 sbar5/text: tnPages
	 show [Lcount SBar2 Sbar3 SBar4 Sbar5 bx]
	 focus current
	 sv*/caret: head current/text
	 show [current Fliste]
	

]
updateScroller: func [lines] [
	if lines [either sl1/data = 0 [nPage 0 nline: 0] 
		[nLine: to-integer sl1/data * (tnLines) 
		nPage: to-integer sl1/data * (tnPages - 1)]
	]
	
	if error? try [line-list/num-chars: 0 result: textinfo current line-list nLine] [result: none]
	sbar3/text: join "Ln " [nLine + 1 ", " line-list/num-chars " chars"]
	sbar4/text: nPage + 1
	sbar5/text: tnPages
	
	y: round (second (current/size) - lineHeight * sl1/data) 
	limite: current/size/y - (lineHeight + 4)
	if y >= limite  [y: limite]  
	bx/offset: lcount/offset + as-pair 0 y
	
	scroll-para lcount sl1
	scroll-para current sl1
	;current/para/scroll/y: lcount/para/scroll/y
	show [ bx lcount sl1 sbar3 sbar4 sbar5 current]
	focus sl1
	 
]


getKey: func [akey]
[
	if tnChars > 0 [
	tmp: to-integer length? sv*/caret
	nChar: (tnChars - tmp) + 1
	cc: pick current/text nChar
	calculatePages
	updateText
	
			if equal? akey 'end  [sl1/data: 1 
					nLine: tnLines nChar: tmp nPage: tnPages - 1 
					updateScroller false] 
			        
				
			if equal? akey 'home  [sl1/data: 0  
					nLine: 0 nChar: 1 nPage: 0
					updateScroller false]
					
			if equal? akey 'page-down [
					either nPage >= tnPages [npage: tnPages - 1] [nPage: nPage + 1]
					nLine: nLine + nLinePage 
					if (nLine > tnLines)  [nLine: tnLines]
					sl1/data: nLine / tnLines
					updateScroller false
					]
					
			if equal? akey 'page-up [
					either nPage <= 0 [nPage: 0] [nPage: nPage - 1]
					nLine: nLine - nLinePage 
					if (nLine <= 0)  [nLine: 0]
					sl1/data: nLine / tnLines
					updateScroller false
					]
					
					
			if equal? akey 'down [ 
					nLine: nLine + 1
					if (nLine > tnLines) [nLine: tnLines]
					sl1/data: nLine / tnLines
					updateScroller false
					nLine2: mod nLine nLinePage
				    if equal? nLine2 0 [nPage: nPage + 1]
			]
				
			
			
			if equal? akey 'up [
					nLine: nLine - 1
					if nLine <= 0 [nLine: 0 nPage: 1]
					sl1/data: nLine / tnLines
					updateScroller false
					nLine2: mod nLine nLinePage
					if equal? nLine2 0 [nPage: nPage - 1]
			]
			
			if equal? akey 'right [
			 	cc: pick current/text nChar
			]
			if equal? akey 'left [
			 	cc: pick current/text nChar
			]
			
			]
]
readFile: does [
		clear current/text
		clear lcount/text
		current/line-list: lcount/line-list: none
		current/text: read to-file fname
		set [path file] split-path fname
		fPath: path
		sFname: file
		SBar1/text: to-local-file fname
		sl1/data: 0
		updateScroller false
		nLine: nChar: 1
		show [SBar1 sl1 current]
	
]
saveFile: does [
	if tnFiles > 0[
	if (confirm/with join "Save File " [fName " ?"] ["Yes" "No"]) [write to-file fname current/text ]
	]
	
]

saveAsFile: does [
	if tnFiles > 0[
		afile: request-file/file/filter/save Fname "*.red"
		if not none? afile 
			[sfname: first afile write to-file sfname current/text 
			fname: sfname
			readFile
			updateRead 
			getFileInfo
		]
	]
]


updateRead: does [	
	tnFiles: tnFiles + 1
	pIndex: tnFiles	
    buffer: copy current/text
	append/only tmpFiles buffer
	set [path file] split-path to-file afile
	append tmpList afile
	append Fliste/data file
	append clear FListe/picked file
	show [current Fliste]
]


newFile: does [
	ccok: false
	afile: to-file empty
	fname: empty
	readFile
	updateRead 
	getFileInfo
]

openFile: does [
	ccok: false
	afile: request-file/filter "*.reds"
	if not none? afile [	
		fname: first afile
		readFile
		updateRead 
		getFileInfo
		]	
]

selectFile: does [
		clear current/text
		clear lcount/text
		buffer: pick tmpFiles pIndex 
		current/text: copy buffer
		set [path file] split-path fname
		fPath: path
		sFname: file
		SBar1/text: to-local-file fname
		current/line-list: lcount/line-list: none
		sl1/data: 0
		updateScroller false
		nLine: nChar: 1
		show [SBar1 sl1 current]
		getFileInfo
		focus current
		sv*/caret: head current/text
]

closeFile: does  [
	if tnFiles > 0 [ 
	if (confirm/with join "Close file " [fname " ?"]  ["Yes" "No"]) [
	clear current/text
	clear LCount/text
	current/line-list: lcount/line-list: none
	remove at tmpList pIndex
	remove at tmpFiles pIndex
	remove at FListe/data pIndex
	tnFiles: tnFiles - 1
	either tnFiles > 0 [
	either tnFiles > 1 [pIndex: tnFiles] [ pIndex: 1]
	FName: pick tmpList pIndex selectFile
	append clear FListe/picked pick FListe/data pIndex 
	] [hide bx]
	show [current lcount FListe]]
]
]


findText: func [s /local atext] [
	
	either all [
		not atext: find next sv*/caret s
		not atext: find current/text s] 
		[Alert join s " not found" unfocus return none  ]
		[
		tmp: length? atext   
		nChar: (tnChars - tmp) + 1
		sv*/caret: atext
		sv*/highlight-start: sv*/caret
		sv*/highlight-end: skip sv*/highlight-start length? s
		
		xy: (caret-to-offset current atext) - current/para/scroll
		lcount/para/scroll/y: current/para/scroll/y: second min 0x0 current/size / 2 - xy
		
		nLine: to-integer (xy/y / (fontSize + 2)) + 1
		
		ratio: nLine / tnLines
		sl1/data: ratio
		show [current lcount sl1]
		sbar3/text: join "Ln " [nLine ", Ch " nChar]
		show SBar3
		]
]




resizeWindow: does [
	xmax: MainWin/size/x 
	ymax: MainWin/size/y
	y1: ((ymax / 3) * 2)
	y2: (ymax / 3) 
	cadre/size/x: xmax
	cadre/size/y: ymax
	ToolBar/size/x: xmax
	FListe/size/x: 190
	FListe/size/y: y1 - 30
	FListe/resize/y: y1 - 30
	FListe/offset: 5x35
	LCount/size/x: 40
	Lcount/size/y: y1 - 30
	LCount/Offset: 200x35
	Current/size/x: xmax - 256
	Current/size/y: y1 - 30
	Current/Offset: 235x35
	sl1/size/y: (y1 - 30)
	sl1/offset: as-pair (235 + Current/size/x) 35
	console/size/x: xmax - 26
	console/size/y: y2 - 50 
	Console/Offset: as-pair (5) (y1 + 10)
	sl2/size/y: y2 - 50 
	sl2/offset: as-pair (235 + Current/size/x) (y1 + 10)
	SBar1/Size/x: (xmax / 3 )
	SBar1/offset: as-pair (5) (y1 + y2 - 35) 
	SBar2/offset: as-pair (SBar1/Size/x + 5) (y1 + y2 - 35) 
	SBar3/offset: as-pair (SBar1/Size/x + 105) (y1 + y2 - 35) 
	SBar4/offset: as-pair (SBar1/Size/x + 210) (y1 + y2 - 35) 
	SBar5/offset: as-pair (SBar1/Size/x + 245) (y1 + y2 - 35)
	SBar6/offset: as-pair (SBar1/Size/x + 280 ) (y1 + y2 - 35) 
	SBar7/offset: as-pair (SBar1/Size/x + 385) (y1 + y2 - 35) 
	cx: 35
	cy: lineHeight + 4
	bxs: to-pair reduce [cx cy]
	bx/size/x: 35 bx/size/y: cy
	show [ cadre Fliste ToolBar Lcount Current sl1 console sl2 SBar1 SBar2 SBar3 SBar4 SBar5 SBar6 SBar7 bx]
	if tnFiles > 0 [show bx]
]

aboutBox: layout [
	styles windowStyles
    backcolor 101.98.95
	space 0x15
	across
	app-info 200x48 "Red Cross-Platform Code Editor" center wrap
	return
	credits: app-info center 200x60 wrap
	"Brought to the Red Language Community by ldci"
	return
 	pad 80 app-btn "OK" [hide-popup]
]



optionsBox: layout [
styles windowStyles
    backcolor 101.98.95
	space 5x15
	across
	app-info 200x24 "Red Compiler Options" center wrap
	return
	app-info 80 "Target" tgr: drop-down data targets [compilerTarget: face/text]
	return
	app-info 80 "Debugger" drop-down "No" "Yes" [debug: face/text]
	return
	app-info 80 "Verbose" drop-down "No" "Yes" [verbose: face/text]
	return
	app-info 80 "Level" sl0: app-sld 80x24 [vl/text: 1 + (sl0/data * 4)  show vl
	verbose_level: to-integer vl/text]
	vl: app-status 15x24 "1"
	
	return
	
 	pad 90 app-btn "OK" [
 	        clear compilerArgs
 	        if verbose = "Yes" [append compilerArgs join " -v " verbose_level ]
 	        if debug = "Yes" [append compilerArgs " -g"]
 	        append compilerArgs join " -t " compilerTarget
 			;compilerArgs: join " -v " [ Verbose_Level " -g -t "]
 			hide-popup] 
	
]


mainWin: layout [
 	styles windowStyles
	across
	origin 0x0
	space 5x5
	at 0x0 cadre: box as-pair xmax ymax snow frame  101.98.95
	at 0x0 ToolBar: box as-pair xmax 30
	at 5x35 FListe: text-list as-pair 190 (y1 - 30) black white  [pIndex: face/cnt FName: pick tmpList pIndex selectFile]
	at 200x35 lcount: area as-pair 40 (y1 - 30) right white white font [size: fontSize]
	at 235x35 current: area as-pair (xmax - 256) (y1 - 30)  white white wrap font [size: fontSize]
	at as-pair 235 + (xmax - 256) 35 sl1: app-sld as-pair 16 (y1 - 30) [if tnFiles > 0 [updateScroller true]]
	space 0x0
	at as-pair (5) (y1 + 10) console: area as-pair (xmax - 26) (y2 - 50) white 229.227.218
	sl2: app-sld as-pair (16) (y2 - 50) [scroll-para console sl2]
	space 5x5
	at as-pair (5) (y1 + y2 - 35) 
	SBar1: app-status as-pair (xmax / 2 ) (30)  left  "No File" font [size: 10] wrap
	SBar2: app-status 100x30 center "" font [size: 10] 
 	SBar3: app-status 100x30 center "" font [size: 10]
	SBar4: app-status 30x30 center "" font [size: 10]
	SBar5: app-status 30x30 center "" font [size: 10]
	SBar6: app-status 100x30 center mold now/date font [size: 10] 
	SBar7: app-status 100x30 center mold now/time font [size: 10] with [rate: 1]			
	at 5x5 
	b1:  app-btn 55  keycode [#"^n"] "New" [newFile]
	b2:  app-btn 55   keycode [#"^o"] "Open" [openFile]
	b3:  app-btn 55 "Close" [closeFile]
	b4:  app-btn 55 "Save" [saveFile]
	b5:  app-btn 55 "Save as" [saveAsFile]
	app-info 80 "Search for..."
	qr: app-status 100x24 "Red" [unfocus focus current sv*/caret: head current/text]
	b6:  app-btn 55 keycode [#"^f"] "Find" [if tnFiles > 0 [show current findText qr/text]]
	
	b7: app-btn 60 "Options" [if error? try [inform/title optionsBox "Compiler"] [inform optionsBox]]
	b8:  app-btn 60 keycode [#"^p"]  "Compile" [if tnFiles > 0 [redCompile]]
	b9:  app-btn 60  keycode [#"^r"] "Run" [if tnFiles > 0 [redRun]]
	
	b10:  app-btn 50 "Help" [browse/only helper]
	b11:  app-btn 50"About" [ if error? try [inform/title aboutBox "About"] [inform aboutBox]]                     
	                     
	b12:  app-btn 50  "Quit" [quitRequested]
	at 200x35 bx: box  as-pair (35) (lineHeight + 4) effect [draw lcursor] 
	;as-pair (xmax - 256) (lineHeight + 4) effect [draw lcursor] 
	do [tgr/text: compilerTarget show tgr]
] 


center-face mainWin
view/new/options mainWin [resize] 
deflag-face current tabbed; permet les tabulations dans la visualisation
hide bx 



insert-event-func [
		
		switch event/type [
			key          [getKey event/key]       	
			time         [Sbar7/text: mold now/time show SBar7 calculatePages updateText]                 	
			resize       [resizeWindow]
        	maximize 	 []
        	;restore	 []
        	;scroll-line []
        	;scroll-nPage []
        	
		]
		if all [event/type = 'alt-down] []
		either all [event/type = 'close event/face = mainWin][quitRequested] [event]
]

do-events

; keycode [#"^n"]
