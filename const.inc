DISPLAY_LIST_SAFE   = $0600;    // Location of the display list, the current display list will be copied to this address

LEVEL_SCREEN        = $9400;    // Location of the currently visible (exposed by the player) labyrinth
LEVEL_DATA          = $9800;    // Location of revealed maze 

TITLE_PIC_FONT      = $9000;    // Title picture font data
TITLE_PIC           = $A400;    // Title picture screen data

LEVEL_FONT          = $9000;    // Rocks, items font data

LEVEL_CODES         : array[0..19] of string[5] = ('0000', 'ciye', 'hcvw', 'jqcv', 'ests', 'uwzu', 'cdoe', 'tcri', 'bimy', 'gaza', 'zhiu', 'tsir', 'nyjc', 'went', 'izyq', 'jmoh', 'qtun', 'athp', 'gtir', 'fsif');

CODE_FONT           = $9000;
CODE_DATA           = $9400;
CODE_STRING         = '            ENTER LEVEL CODE            '~;
CODE_DISPLAY        = '     SKIP CODE TO THIS LEVEL:           '~;

GAME_OVER_PIC_FONT  = $9000;    // Game over picture font data
GAME_OVER_PIC_DATA  = $9800;    // Game over picture screen data
GAME_OVER_TEXT_FONT = $9C00;

HELP_TEXT_FONT      = $9000;    // Manual font data
HELP_TEXT_DATA      = $9400;    // Manual screen data

END_PIC_FONT        = $9000;    // Outro picture font data
END_PIC_DATA        = $9800;    // Outro picture screen data
END_TEXT_FONT       = $a000;    // Outro text font data
END_TEXT_DATA       = $99E0;    // Outro text screen data

PANEL               = $9c00;    // Bottom panel data
PANEL_SRC           = $9d00;    // Bottom panel copy

PMG_MEMORY          = $A000;                    // P/MG memory area
ENEMY_1_MEMORY      = PMG_MEMORY + $400;
ENEMY_2_MEMORY      = ENEMY_1_MEMORY + $100;
ENEMY_3_MEMORY      = ENEMY_2_MEMORY + $100;

LEVEL_2_ENEMIES     = 7;                        // From which level (levels are numbered 0..MAX_LEVEL-1) two enemies are displayed.
LEVEL_3_ENEMIES     = 15;                       // From which level (levels are numbered 0..MAX_LEVEL-1) three enemies are displayed.

PANEL_MAP           = PANEL + 40 + 35;  // Location of map symbol on the panel
PANEL_SHIELD        = PANEL + 40 + 36;  // Location of shield symbol on the panel
PANEL_SWORD         = PANEL + 40 + 37;  // Location of sword symbol on the panel

PANEL_SRC_MAP       = PANEL_SRC + 40 + 35;  // Location of map symbol on the copy of panel
PANEL_SRC_SHIELD    = PANEL_SRC + 40 + 36;  // Location of shield symbol on the copy of panel
PANEL_SRC_SWORD     = PANEL_SRC + 40 + 37;  // Location of sword symbol on the copy of panel

RMT_PLAYER_ADR      = $AC00;                    // Address of RMT player - WARNING: player occupies ADR-$3c0 to ADR+$734
RMT_MODUL_ADR       = $B000;                    // Address of music data

RMT_VOLUME          = $AD03;

MUSIC_TITLE         = $00;      // Number of pattern with title music;
MUSIC_INGAME        = $0E;      // ingame music;
MUSIC_DIE           = $13;      // death sfx;
MUSIC_GAMEOVER      = $16;      // game over music;
MUSIC_WIN           = $23;      // win sfx;
MUSIC_ENDPART       = $26;      // outro music;
MUSIC_EMPTY         = $2e;      // silence

SFX_INSTRUMENT      = $6;
SFX_CHANNEL         = $3;
SFX_NOTE            = 14;

MAX_LEVEL           = 20;       // Number of levels and pointers to compressed data with level definitions
LEVELS: array[0..MAX_LEVEL-1] of word = (LEVEL_01, LEVEL_02, LEVEL_03, LEVEL_04, LEVEL_05, LEVEL_06, LEVEL_07, LEVEL_08, LEVEL_09, LEVEL_10, LEVEL_11, LEVEL_12, LEVEL_13, LEVEL_14, LEVEL_15, LEVEL_16, LEVEL_17, LEVEL_18, LEVEL_19, LEVEL_20);

// Animation frames of enemy
BAT_FRAMES_0: array [0..$09] of byte = ($00, $24, $18, $18, $7e, $ff, $99, $24, $24, $00);
BAT_FRAMES_1: array [0..$09] of byte = ($00, $24, $18, $ff, $7e, $18, $24, $00, $00, $00);
BAT_FRAMES_2: array [0..$09] of byte = ($00, $00, $24, $99, $ff, $7e, $18, $24, $24, $00);
BAT_FRAMES_3: array [0..$09] of byte = ($00, $00, $24, $18, $7e, $ff, $18, $24, $24, $00);
BAT_FRAMES: array[0..3] of pointer = (@BAT_FRAMES_0, @BAT_FRAMES_1, @BAT_FRAMES_2, @BAT_FRAMES_3);

// Array of HPOS
HPOS: array[0..3] of word = ($D000, $D001, $D002, $D003);

// Symbol locations in level font
WALL_SYMBOLS: array [0..MAX_LEVEL-1] of byte = ($21, $22, $23, $24, $21, $22, $23, $24, $21, $22, $21, $22, $23, $24, $21, $22, $23, $24, $21, $22);
MAP_SYMBOL  = $6d;
SHIELD_SYMBOL = $73;
SWORD_SYMBOL = $77;
TIME_SYMBOL = $54;
TIMER_SYMBOL = $55;
EXIT_SYMBOL = $65;

PLAYER_LT_SYMBOL = $61;
PLAYER_RT_SYMBOL = $62;
PLAYER_DN_SYMBOL = $41;
PLAYER_UP_SYMBOL = $42;

// Animation data for hero
PLAYER_FRAMES_X: array [0..1] of byte = (PLAYER_LT_SYMBOL, PLAYER_RT_SYMBOL);
PLAYER_FRAMES_Y: array [0..1] of byte = (PLAYER_UP_SYMBOL, PLAYER_DN_SYMBOL);

// How long the map is to be displayed
MAP_SHOW_DURATION = 120;

// Time between color changes (in frames);
FADE_DURATION = 3;

// Joystick directions
JOY_UP = 14;
JOY_DN = 13;
JOY_LT = 11;
JOY_RT = 7;


