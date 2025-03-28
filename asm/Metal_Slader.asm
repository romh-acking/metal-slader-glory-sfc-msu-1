arch snes.cpu

// For this asm patch, the game stores the song ID
// However later it stores the subtune ID
define songID 						$C5
define currentlyPlayingSong 		$950

define MSU_STATUS 					$002000
define MSU_ID      					$002002
define MSU_TRACK					$002004
define MSU_VOLUME					$002006
define MSU_CONTROL					$002007

//https://jumbocactuarx27.blogspot.com/2013/08/how-to-enhance-snes-game-with-msu-1.html

org $1d20c; base $83d20c
jsr MSUCode


// The translation uses the beginning of this slack space.
// Therefore, let's go further down.
org $1fA00; base $83fA00
MSUCode:

////////////////////////
//MSU-1 code
////////////////////////

// Set up stack for switching to the bank for the MSU
// registers and then back to the original bank.
lda #$7e
pha
lda #$00
pha
plb

clc

lda {songID}

// Blue Boy transform
cmp #$b0
beq Pass

// Silkiene's theme #1
cmp #$f9
beq Pass

// Jiff's theme
cmp #$FA
beq Pass

// Silkiene's theme #2
cmp #$fb
beq Pass

// Intro cockpit jingle
cmp #$7B
beq Pass

// If #$3a or less, it's music
cmp #$3b
bcs End

cmp {currentlyPlayingSong}
beq SilenceSnesMusic

cmp #$11
beq Ch5Exception

cmp #$29
beq Ch7Exception

//----------------------
// Main MSU logic
//----------------------

Pass:

//Check the first letter of the MSU ID (it should be 'S' which is hex 53.)
lda {MSU_ID}
cmp #$53

//If it isn't, we skip over the MSU-1 code.
bne End    

//Set the volume
lda #$d0
sta {MSU_VOLUME}

//We set the track number trackno
lda {songID}
sta {MSU_TRACK}
stz {MSU_TRACK}+1
sta {currentlyPlayingSong}

// A common usage for the status port is to lock the SNES CPU after setting an audio track or specifying a seek target on the MSU1 Data file. This is a rather important step to include if you’re aiming to support the MSU1 in hardware.
// https://helmet.kafuka.org/msu1.htm

ReadyForPlayBack:
	lda {MSU_STATUS}
	and #$40
	bne ReadyForPlayBack

//We set the MSU-1 to play the selected track on repeat.
lda #$03
sta {MSU_CONTROL}

//----------------------
// Silence SNES music
//----------------------

SilenceSnesMusic:

lda {songID}

// Some songs we don't want to write a null 
// subtune id as the game uses them to time cutscenes
// (the control code #$f7 makes the scripting language stall 
// until a song finishes)
// There's code below to silence their instruments later
// I could silence all the songs with the method below instead
// if setting the subtune to zero, but I'm lazy.

// Space ship flight song
cmp #$16
beq End

// Blue Boy transform
cmp #$b0
beq End

// Opening credits
cmp #$42
beq End

// Silence music by setting subtune to zero
lda #$00
sta {songID}

End:
plb

//We return to the hijack point. This is the end of the MSU-1 code.
jmp $d23b

//----------------------
// Some exceptions
//----------------------
// Certain tracks just skip to different parts
// of the song. Therefore, we shouldn'tay
// tell the MSU-1 chip to play a new song
Ch5Exception:
lda {currentlyPlayingSong}
cmp #$12
beq SilenceSnesMusic
jmp Pass

Ch7Exception:
lda {currentlyPlayingSong}
cmp #$28
beq SilenceSnesMusic
jmp Pass

////////////////////////
// Process fadeout A
////////////////////////

org $1ab84; base $83ab84
JMP Fadeout
nop
FadeoutReturn:

////////////////////////
// Process fadeout B
////////////////////////

org $1F800; base $83F800
Fadeout:
ldy #$00
lda [$35],y

// Check if it's the control code id for a fadeout
cmp #$B8
bne FadeoutEnd
tay

lda #$7e
pha
lda #$00
pha
plb

// Silence music
lda #$00
sta $2006
sta {currentlyPlayingSong}

plb

tya
ldy #$00

FadeoutEnd:
clc
jmp FadeoutReturn

BattleDanger:
lda #$2A
sta {songID}
jmp MSUCode


////////////////////////
// Ch 7: Battle Danger
////////////////////////
// Change hardcoded audio trigger

org $1D28B; base $83d28b; fill $5, $ea
org $1D28B; base $83d28b
jsr BattleDanger

////////////////////////
// Change songs ids for scenes
// in scripting language
////////////////////////

// Ch 1: Change Charmy scene's song id
org $117EE9
db $0A

// Ch 2: Change Jiff scene's song id
org $147D6D; base $28fd6D
db $06

// Ch 2: Yayoi shocked
org $140A98; base $288a98
db $08

// Ch 5: Death Path Intro
org $144C1d; base $28CC1D
db $08

// Ch 6: Remove fadeout
org $138460; base $278460
db $ea

// Ch 7: Level 1: Change post-battle theme (Elina)
org $1468B6; base $2768B6
db $24

// Ch 7: Level 2: Change post-battle theme (Elina)
org $1468CE; base $2768CE
db $24

// Ch 7: Level 3: Change post-battle theme (Elina)
org $1468E6; base $28E8E6
db $24

// Ch 7: Level 3: Change post-battle theme (Catty)
org $14693F; base $28e93f
db $24

// Ch 7: Level 3: Change post-battle theme (Catty)
org $146957; base $28e957
db $24

// Ch 7: Level 3: Change post-battle theme (Catty)
org $14696F; base $28e96f
db $24

// Ch 7: Level 3: Change post-battle theme (Enkai)
org $1469C8; base $28e9c8
db $24

// Ch 7: Level 3: Change post-battle theme (Enkai)
org $1469e0; base $28e9e0
db $24

// Ch 7: Level 3: Change post-battle theme (Enkai)
org $1469f8; base $28e9f8
db $24


// Ch 7: Post Fortress Appear Cutscene
org $1428E0; base $28A8E0
db $1B

// Ch 7: Post Fortress Appear Cutscene
org $13B640; base $27B640
db $1B

////////////////////////
// Silence some songs:
////////////////////////

// Add an execute breakpoint here to find the general location where to silence the instruments. (only works on a bankswitch)
// 05819c lda ($ea)     [058b52]

// I think the game assigns an instrument per channel. 17 is silence. Unused channels use this value.

// Ch 1: Opening credits
org $28892; base $058892
db $17,$17,$17,$17,$17,$17,$17,$17,$17

// Ch 2: Space ship flight song
org $28BED; base $58bed
db $17

// Ch 2: Azusa found:
org $28C94; base $58c94
db $17,$17,$17,$17,$17,$17,$17,$17
