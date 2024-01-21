program Dungeon_Adventurer;

{
                                        
             #######                    
           ###########                  
          #############                 
         ####     #####                 
        #####      ####                 
        ######   ###   ##               
        ######  ##############          
         ##### #######   #####          
         ##### #####   ########         
          ###   #  # ### ########       
         ###    # ## ####### ###        
                ########### ###         
                ##############          
               ## #  ########           
             #######    #               
           ##############               
         ####################           
                   ###########          
                         #####          
    DUNGEON ADVENTURER        ##        
                                        
    dely + tatqoo / NG 2024             
                                        
}

// switch off ROM and get C000-CFFF and D800-FFFF free

{$DEFINE ROMOFF}
 
uses atari, crt, rmt, aplib;

type Tplayer = record
    x: byte;                // x position of hero
    y: byte;                // y
    prev_x: byte;           // previous x position
    prev_y: byte;           // y
    direction: char;        // direction of movement
    symbol: byte;           // current character representing the hero
    symbol_idx: byte;       // symbol identifier for the table (0..1)
    has_shield: boolean;    // shield equipment
    has_sword: boolean;     // sword
    has_map: boolean;       // map
end;

type Tenemy = record
    id: byte;               // identifier for entry in the HPOS register
    x: byte;                // x position of enemy
    y: byte;                // y
    start_x: byte;          // starting position at screen
    end_x: byte;            // ending
    speed: smallint;        // speed of enemy (positive values - movement to the right, negative values to the left
    frame: byte;            // current animation frame
    killed: boolean;        // if enemy was killed
    memory: word;           // position in P/MG memory
end;

var

    msx:                TRMT;               // Sound object
    msx_volume:         byte = 255;         // Sound volume
    music_is_playing:   boolean = false;    // If music has to be played
    silent_play:   boolean = false;
    restart_music:      boolean = true;     // Informs the title screen procedure that there has been a return from the instruction   

    code_match:         boolean;            // matching enterd code

    ink_color:          byte;               // Bright color, used for fade in/out

    joy_changed:        boolean;            // If joy value is other than null?

    level:              byte;               // Current level
    exit_found:         boolean;            // If hero found exit
    game_in_progress:   boolean;            // If game is in progress then update time
    game_over:          boolean = false;    // If game over screen should be displayed

    immune_timer:       byte;               // Timer for hero immunity
    shield_shown:       boolean;            // Used for shield blink
    sword_taken:        boolean = false;    // Used when you need to check if a sword has been taken on this level

    key:                char;               // Value of pressed key
    user_action:        boolean;            // If action was taken on title screen

    time:               byte;               // Time remaining to complete the level

    rtc:                byte absolute 20;   // Real time clock
    STICK0:             byte absolute $278; // Joystick in port 1
    STRIG0:             byte absolute $284; // Trigger
    ATRACT:             byte absolute $4D;  // Attraction mode

    hero:               Tplayer;
    enemy_1:            Tenemy;
    enemy_2:            Tenemy;
    enemy_3:            Tenemy;

    enemy:              ^enemy_1;

const
{$r resources.rc}
{$i pak_memory.inc}
{$i const.inc}
{$i level_tables.inc}
{$i dlist.inc}
{$i interrupts.inc}


{ Returns true if the joystick button has been pressed
  @returns joy trigger state }
function strigpressed: boolean;
begin

    if STRIG0 = 0 then Result := true else Result := false;

end;


{ Randomises the next Y position of the enemy in the range from 2 to 19
  @returns y position }
function get_random_enemy_position: byte; overload;
var
    rnd_value: byte;
begin

    Randomize;

    repeat
        rnd_value := Random(20);
    until (rnd_value > 2) and (rnd_value < 20);

    // value = rnd_value * 8 + 24;

    Result := rnd_value shl 3 + 24;

end;

{ Randomises the next Y position of the enemy in the range from 2 to 19 making sure that the value 
  is different from the one given
  @returns y position }
function get_random_enemy_position(diff: byte): byte; overload;
var
    rnd_value: byte;
begin

    Randomize;

    repeat
        rnd_value := Random(20);
    until (rnd_value > 2) and (rnd_value < 20) and (rnd_value <> diff);

    // value = rnd_value * 8 + 24;

    Result := rnd_value shl 3 + 24;

end;


{ Moves all P/MG objects out of the visible screen area }
procedure move_pmg_off_screen;
begin
    HPOSP0 := 0;
    HPOSP1 := 0;
    HPOSP2 := 0;
    HPOSP3 := 0;
    HPOSM0 := 0;
    HPOSM1 := 0;
    HPOSM2 := 0;
    HPOSM3 := 0;
    Pause;
end;


{ Smooth muting of music. }
procedure fade_out_music;
begin

    repeat 
    
        Inc(msx_volume, 15);
        Poke(RMT_VOLUME, msx_volume);
        Pause(FADE_DURATION);
    
    until msx_volume = 255;

    msx.stop;

end;


{ Smooth increase of the music volume }
procedure fade_in_music;
begin

    repeat 
    
        Dec(msx_volume, 15);
        Poke(RMT_VOLUME, msx_volume);
        Pause(FADE_DURATION);
    
    until msx_volume = 0;

end;

{ Fades out screen }
procedure fade_out_screen;
begin

    for ink_color := $0e downto $0 do begin

        COLOR1 := ink_color;
        PCOLR0 := ink_color;
        PCOLR1 := ink_color;
        PCOLR2 := ink_color;      

        Pause(FADE_DURATION);

    end;

end;


{ Fades in screen }
procedure fade_in_screen;
begin

    for ink_color := $0 to $0e do begin

        COLOR1 := ink_color;
        PCOLR0 := ink_color;
        PCOLR1 := ink_color;
        PCOLR2 := ink_color;

        Pause(FADE_DURATION);

    end;

end;


{ Initialises the next level of the maze. Performed at the start of the game 
  and after completing a given screen. }
procedure init_maze(level: byte);
var
    x_counter: byte;
    y_counter: byte;
begin

    game_in_progress := false;

    // turn off screen

    SDMCTL := 0;
    Pause;

    // SETUP SPRITES

    // turn off sprites

    GRACTL := 0;
    move_pmg_off_screen;

    // set sprite memory pointer

    PMBASE := hi(PMG_MEMORY);

    Fillbyte(pointer(PMG_MEMORY + $400), $3ff, 0);

    // SET priority + overlap color

    GPRIOR := 32 + 1;

    // SET sprites size

    SIZEP0 := 0;
    SIZEP1 := 0;
    SIZEP2 := 0;

    // SET sprites color

    PCOLR0 := $0E;
    PCOLR1 := $0E;
    PCOLR2 := $0E;

    // init enemy (enemies)

    enemy_1.start_x := 20;
    enemy_1.end_x := 208;
    enemy_1.x := enemy_1.start_x;
    enemy_1.id := 0;
    enemy_1.speed := 1;
    enemy_1.memory := ENEMY_1_MEMORY;
    HPOSP0 := enemy_1.x;

    if level >= LEVEL_2_ENEMIES then begin

        enemy_2.start_x := 208;
        enemy_2.end_x := 20;
        enemy_2.x := enemy_2.start_x;
        enemy_2.id := 1;
        enemy_2.speed := -1;
        enemy_2.memory := ENEMY_2_MEMORY;
        HPOSP1 := enemy_2.x;

    end;

    if level >= LEVEL_3_ENEMIES then begin

        enemy_3.start_x := 20;
        enemy_3.end_x := 208;
        enemy_3.x := enemy_3.start_x;
        enemy_3.id := 2;
        enemy_3.speed := 1;
        enemy_3.memory := ENEMY_3_MEMORY;
        HPOSP2 := enemy_3.x;

    end;

    // get random enemy y position

    enemy_1.y := get_random_enemy_position;
    enemy_1.killed := false;

    if level >= LEVEL_2_ENEMIES then begin

        enemy_2.y := get_random_enemy_position;
        enemy_2.killed := false;

    end;    

    if level >= LEVEL_3_ENEMIES then begin

        enemy_3.y := get_random_enemy_position(byte((enemy_1.y - 24) / 8));
        enemy_3.killed := false;

    end;    

    // depack level font

    unapl(pointer(PAK_LEVEL_FONT), pointer(LEVEL_FONT));

    // depack level data

    unapl(pointer(LEVELS[level]), pointer(LEVEL_DATA));
    FillByte(pointer(LEVEL_SCREEN), 40*21, 0);

    unapl(pointer(PAK_PANEL), pointer(PANEL));
    unapl(pointer(PAK_PANEL), pointer(PANEL_SRC));

    // set display list and charset

    move(@display_list_game, pointer(DISPLAY_LIST_SAFE), sizeOf(display_list_game));
    Pause;

    SDLSTL := DISPLAY_LIST_SAFE;
    CHBAS  := hi(LEVEL_FONT);

    // copy first few walls

    Poke(LEVEL_SCREEN,     Peek(LEVEL_DATA));
    Poke(LEVEL_SCREEN + 1, Peek(LEVEL_DATA + 1));
    Poke(LEVEL_SCREEN + 2, Peek(LEVEL_DATA + 2));

    Poke(LEVEL_SCREEN + 1 * 40,     Peek(LEVEL_DATA + 1 * 40 + 0));
    Poke(LEVEL_SCREEN + 1 * 40 + 1, Peek(LEVEL_DATA + 1 * 40 + 1));
    Poke(LEVEL_SCREEN + 1 * 40 + 2, Peek(LEVEL_DATA + 1 * 40 + 2));

    Poke(LEVEL_SCREEN + 2 * 40,     Peek(LEVEL_DATA + 2 * 40 + 0));
    Poke(LEVEL_SCREEN + 2 * 40 + 1, Peek(LEVEL_DATA + 2 * 40 + 1));
    Poke(LEVEL_SCREEN + 2 * 40 + 2, Peek(LEVEL_DATA + 2 * 40 + 2));

    // copy borders into all levels but last

    if level < MAX_LEVEL - 1 then begin

        // top and bottom
        for x_counter := 0 to 37 do begin
        
            Poke(LEVEL_SCREEN + x_counter, WALL_SYMBOLS[level]);
            Poke(LEVEL_SCREEN + x_counter + 20*40, WALL_SYMBOLS[level]);
        
        end;

        // left and right
        for y_counter := 0 to 20 do begin
        
            Poke(LEVEL_SCREEN + y_counter * 40, WALL_SYMBOLS[level]);
            Poke(LEVEL_SCREEN + y_counter * 40 + 38, WALL_SYMBOLS[level]);
        
        end;

        // reveal enter

        Poke(LEVEL_SCREEN, 0);
        Poke(LEVEL_SCREEN + 1, 0);
        Poke(LEVEL_SCREEN + 40, 0);
        Poke(LEVEL_SCREEN + 40 + 1, 0);

    end;

    // copy exit symbol

    Poke(LEVEL_SCREEN + 20*40 + 37, EXIT_SYMBOL);

    // copy items into playfield

    Poke(LEVEL_SCREEN + MAP_LOCATION_Y[level] * 40 + MAP_LOCATION_X[level], MAP_SYMBOL);
    Poke(LEVEL_SCREEN + SHIELD_LOCATION_Y[level] * 40 + SHIELD_LOCATION_X[level], SHIELD_SYMBOL);
    Poke(LEVEL_SCREEN + SWORD_LOCATION_Y[level] * 40 + SWORD_LOCATION_X[level], SWORD_SYMBOL);
    Poke(LEVEL_SCREEN + TIMER_LOCATION_Y[level] * 40 + TIMER_LOCATION_X[level], TIMER_SYMBOL);

    // init player

    hero.x := 0;
    hero.y := 0;

    // draw player

    hero.symbol := PLAYER_DN_SYMBOL;
    Poke(LEVEL_SCREEN, PLAYER_DN_SYMBOL);

    // reset items

    hero.has_map := false;
    hero.has_shield := false;
    hero.has_sword := false;
    sword_taken := false;

    // turn on sprites and missiles

    GRACTL := 3;

    // disable DLI interrupts

    NMIEN := $40;
    Pause;

    // turn on screen

    SDMCTL := 62;

    fade_in_screen;

    // set time

    time := 35;

    // start counting time

    game_in_progress := true;

end;


{ Updates the player's position on the screen, handles character animation. }
procedure update_player_position;
begin

    if joy_changed then begin

        hero.symbol_idx := hero.symbol_idx + 1;

        if hero.symbol_idx = 2 then hero.symbol_idx := 0;
        
        if hero.direction = 'X' then hero.symbol := PLAYER_FRAMES_X[hero.symbol_idx];
        if hero.direction = 'Y' then hero.symbol := PLAYER_FRAMES_Y[hero.symbol_idx];

    end;

    Poke(LEVEL_SCREEN + (hero.y * 40 + hero.x), hero.symbol);

end;


{ Checks the position of the joystick and updates the variables responsible 
  for the player's position, checks if the character wants to use the map, checks 
  if the player has found an object.}
procedure check_joy;
var 
    joy_state: byte;
    terrain_element: byte;
    display_list_lms: word;
    wall_symbol: byte;
begin

    joy_state := STICK0;

    joy_changed := false;

    wall_symbol := WALL_SYMBOLS[level];

    case joy_state of
        JOY_DN: begin 
                if hero.y < 20 then begin
                    terrain_element := Peek(LEVEL_SCREEN + (hero.y * 40) + 40 + hero.x);
                    if terrain_element <> wall_symbol then begin
                        hero.prev_y := hero.y;  hero.prev_x := hero.x; hero.y := hero.y + 1; 
                        hero.direction := 'Y'; joy_changed := true;
                    end;
                end;
            end; // down
        JOY_UP: begin
                if hero.y > 1 then begin
                    terrain_element := Peek(LEVEL_SCREEN + (hero.y * 40) - 40 + hero.x);
                    if terrain_element <> wall_symbol then begin
                        hero.prev_y := hero.y;  hero.prev_x := hero.x; hero.y := hero.y - 1; 
                        hero.direction := 'Y'; joy_changed := true;
                    end;
                end;
            end; // up
        JOY_LT: begin 
                if hero.x <> 0 then begin
                    terrain_element := Peek(LEVEL_SCREEN + (hero.y * 40) + hero.x - 1);
                    if terrain_element <> wall_symbol then begin
                        hero.prev_y := hero.y;  hero.prev_x := hero.x; hero.x := hero.x - 1;
                        hero.direction := 'X'; joy_changed := true;
                    end;
                end;
            end; // left
        JOY_RT:  begin 
                if hero.x < 37 then begin
                    terrain_element := Peek(LEVEL_SCREEN + (hero.y * 40) + hero.x + 1);
                    if terrain_element <> wall_symbol then begin
                        hero.prev_y := hero.y;  hero.prev_x := hero.x; hero.x := hero.x + 1;
                        hero.direction := 'X'; joy_changed := true;
                    end;
                end;
            end; // right
    end;

    // check for exit

    if (hero.x = 37) and (hero.y = 20) then exit_found := true;

    // check for map

    if (hero.x = MAP_LOCATION_X[level]) and (hero.y = MAP_LOCATION_Y[level]) and (hero.has_map = false) then begin

        hero.has_map := true;

        Poke(PANEL_MAP, MAP_SYMBOL);
        Poke(PANEL_SRC_MAP, MAP_SYMBOL);

        msx.Sfx(SFX_INSTRUMENT, SFX_CHANNEL, SFX_NOTE);

    end;

    // check if player want to use map

    if strigpressed and hero.has_map then begin

        // update inventory

        hero.has_map := false;

        // switch screen to map

        display_list_lms := $0600 + 4;
        Pause;
        DPoke(display_list_lms, LEVEL_DATA);
        
        // update panel

        Poke(PANEL_MAP, 0);
        Poke(PANEL_SRC_MAP, 0);

        // let the player see map

        Pause(MAP_SHOW_DURATION);

        // switch screen to game

        DPoke(display_list_lms, LEVEL_SCREEN);

    end;

    // check for shield

    if (hero.x = SHIELD_LOCATION_X[level]) and (hero.y = SHIELD_LOCATION_Y[level]) and (hero.has_shield = false) then begin

        hero.has_shield := true;

        Poke(PANEL_SHIELD, SHIELD_SYMBOL);
        Poke(PANEL_SRC_SHIELD, SHIELD_SYMBOL);

        msx.Sfx(SFX_INSTRUMENT, SFX_CHANNEL, SFX_NOTE);

    end;

    // check for sword

    if (hero.x = SWORD_LOCATION_X[level]) and (hero.y = SWORD_LOCATION_Y[level]) and (hero.has_sword = false) and (sword_taken = false) then begin

        hero.has_sword := true;

        Poke(PANEL_SWORD, SWORD_SYMBOL);
        Poke(PANEL_SRC_SWORD, SWORD_SYMBOL);

        msx.Sfx(SFX_INSTRUMENT, SFX_CHANNEL, SFX_NOTE);

        // sword is unique, delete from map

        Poke(LEVEL_SCREEN + SWORD_LOCATION_Y[level] * 40 + SWORD_LOCATION_X[level], 0);
        Poke(LEVEL_DATA   + SWORD_LOCATION_Y[level] * 40 + SWORD_LOCATION_X[level], 0);

        sword_taken := true;

    end;

    // check for timer

    if (hero.x = TIMER_LOCATION_X[level]) and (hero.y = TIMER_LOCATION_Y[level]) then begin

        // update time bar

        FillByte(pointer(PANEL) + 40 + 5, 29, TIME_SYMBOL);

        // check if time is not full, if not - play sound (prevents from fx loop)

        if time < 35 then msx.Sfx(SFX_INSTRUMENT, SFX_CHANNEL, SFX_NOTE);

        time := 35;

    end;

end;


{ Animates selected enemy }
procedure process_animation;
begin

    // animate enemy

    enemy.frame := enemy.frame + 1;
    if enemy.frame > 3 then enemy.frame := 0;

    // copy to pmg memory
    
    Move(BAT_FRAMES[enemy.frame], pointer(enemy.memory + enemy.y), sizeof(BAT_FRAMES_0));

    Inc(enemy.x, enemy.speed);

    // enemy off screen?

    if enemy.x = enemy.end_x then begin

        // reset x position

        enemy.x := enemy.start_x;

        // delete old data

        FillByte(pointer(enemy.memory + enemy.y), 255, 0);

        // set new y position

        enemy.y := get_random_enemy_position;

    end;

    Poke(HPOS[enemy.id], enemy.x);

end;


{ Werifies whether the enemy is on the board and, if so, triggers the animation procedure. }
procedure animate_enemies;
begin

    if not enemy_1.killed then begin

        enemy := @enemy_1;
        process_animation;

    end;

    if (level >= LEVEL_2_ENEMIES) and (not enemy_2.killed) then begin

        enemy := @enemy_2;
        process_animation;

    end;

    if (level >= LEVEL_3_ENEMIES) and (not enemy_3.killed) then begin

        enemy := @enemy_3;
        process_animation;

    end;

end;


{ Processing collision, decides what to do based on the hero's possessed items }
procedure process_collision(calc_x, calc_y: word);
begin

    if (calc_x > enemy.x) and (calc_x < enemy.x + 8) then begin 

        // if player has no weapons then end game
        
        if (not hero.has_shield) and (not hero.has_sword) then begin
        
            game_over := true; 
            msx.Sfx(SFX_INSTRUMENT, SFX_CHANNEL, SFX_NOTE);

        end;

        // if he has shield, then immune player for 40 game ticks
        
        if hero.has_shield then begin

            hero.has_shield := false;

            // delete shield symbol from panel

            Poke(PANEL_SHIELD, 0);

            immune_timer := 40;
            shield_shown := false;

        end;

        // if player has sword, then kill enemy

        if hero.has_sword then begin

            hero.has_sword := false;
            
            Poke(PANEL_SWORD, 0);
            Poke(PANEL_SRC_SWORD, 0);
            
            enemy.killed := true;
            enemy.x := 0;
            enemy.y := 0;

            Poke(HPOS[enemy.id], 0);

            msx.Sfx(SFX_INSTRUMENT, SFX_CHANNEL, SFX_NOTE);

        end;

    end;

end;


{ Checks the collision of enemies with the hero, also handles the hero's 
  temporary invulnerability and resets attaction flag. }
procedure check_collision;
var
    calc_x:         word;
    calc_y:         word;
begin

    // check if player is immuned - shield was taken

    if immune_timer = 0 then begin

        // recalculate enemy (sprite) position to char coordinates

        calc_y := hero.y * 8 + 32;
        calc_x := hero.x * 4 + 48 + 3;

        // check y position

        if calc_y = enemy_1.y then begin

            enemy := @enemy_1;
            process_collision(calc_x, calc_y);

        end;

        if calc_y = enemy_2.y then begin

            enemy := @enemy_2;
            process_collision(calc_x, calc_y);

        end;

        if calc_y = enemy_3.y then begin

            enemy := @enemy_3;
            process_collision(calc_x, calc_y);

        end;

    end;

    // if immune timer ticks, then flash with shield symbol
    
    if immune_timer > 0 then begin

        Dec(immune_timer);

        if rtc and 3 = 0 then begin

            if shield_shown then begin

                shield_shown := false;
                Poke(PANEL_SHIELD, 0);

            end else begin

                shield_shown := true;
                Poke(PANEL_SHIELD, SHIELD_SYMBOL);

            end;

        end;

    end;

    // reset attraction flag

    ATRACT := 0;

end;


{ Draws the nearest dungeon walls }
procedure reveal_walls;
var
    c: word;
    d: word;
    e: word;
begin

    // calculate common values
    
    c := hero.y * 40;
    d := LEVEL_SCREEN + c;
    e := LEVEL_DATA + c;

    // REVEAL

    // line above player

    Poke (d - 40 + hero.x - 1, Peek(e - 40 + hero.x - 1));
    Poke (d - 40 + hero.x + 0, Peek(e - 40 + hero.x + 0));
    Poke (d - 40 + hero.x + 1, Peek(e - 40 + hero.x + 1));

    // inline with player

    Poke (d      + hero.x - 1, Peek(e      + hero.x - 1));
    Poke (d      + hero.x + 0, Peek(e      + hero.x + 0));
    Poke (d      + hero.x + 1, Peek(e      + hero.x + 1));

    // line below player

    Poke (d + 40 + hero.x - 1, Peek(e + 40 + hero.x - 1));
    Poke (d + 40 + hero.x + 0, Peek(e + 40 + hero.x + 0));
    Poke (d + 40 + hero.x + 1, Peek(e + 40 + hero.x + 1));

    // Last level is completely dark

    if level = MAX_LEVEL - 1 then begin

        // HIDE

        // two lines above

        Poke (d - 80 + hero.x - 1, 0);
        Poke (d - 80 + hero.x + 0, 0);
        Poke (d - 80 + hero.x + 1, 0);

        // two lines below

        Poke (d + 80 + hero.x - 1, 0);
        Poke (d + 80 + hero.x + 0, 0);
        Poke (d + 80 + hero.x + 1, 0);

        // column on left

        Poke (d - 40 + hero.x - 2, 0);
        Poke (d      + hero.x - 2, 0);
        if hero.x > 0 then Poke (d + 40 + hero.x - 2, 0);

        // column on right

        Poke (d - 40 + hero.x + 2, 0);
        Poke (d      + hero.x + 2, 0);
        Poke (d + 40 + hero.x + 2, 0);

        // restore items into playfield

        Poke(LEVEL_SCREEN + MAP_LOCATION_Y[level] * 40 + MAP_LOCATION_X[level], MAP_SYMBOL);
        Poke(LEVEL_SCREEN + SHIELD_LOCATION_Y[level] * 40 + SHIELD_LOCATION_X[level], SHIELD_SYMBOL);
        Poke(LEVEL_SCREEN + TIMER_LOCATION_Y[level] * 40 + TIMER_LOCATION_X[level], TIMER_SYMBOL);

        if not sword_taken then Poke(LEVEL_SCREEN + SWORD_LOCATION_Y[level] * 40 + SWORD_LOCATION_X[level], SWORD_SYMBOL);

        // restore exit

        Poke(LEVEL_SCREEN + 20*40 + 37, EXIT_SYMBOL);

    end;

end;


{ Draws panel below playfield }
procedure init_panel;
begin

    move(pointer(PANEL_SRC), pointer(PANEL), 3 * 40);

end;


{ Reduces the available amount of time and updates it in the panel on the screen }
procedure update_time;
begin

    if rtc and %00111111 = 0 then begin

        Dec(time);
        Poke(PANEL + 40 + time, 0);

    end;

end;


{ Displays the end of the game }
procedure congratulations;
var
    vsc_counter: byte;
    line_counter: byte;
    scroll_address: word;
const
    display_list_lms_end: word = $0600 + 18;
begin

    Pause(5*60);

    // turn off screen

    SDMCTL := 0;
    move_pmg_off_screen;
    Pause;

    // set display list

    move(@display_list_congrats, pointer(DISPLAY_LIST_SAFE), sizeOf(display_list_congrats));
    Pause;

    SDLSTL := DISPLAY_LIST_SAFE;

    // depack data files

    unapl(pointer(PAK_TEXT_FONT), pointer(END_TEXT_FONT));
    unapl(pointer(PAK_END_FONT), pointer(END_PIC_FONT));
    unapl(pointer(PAK_END_DATA), pointer(END_PIC_DATA));
    unapl(pointer(PAK_END_STORY), pointer(END_TEXT_DATA));

    // set display list interrupts

    Pause;
    SetIntVec(iDLI, @dli_end_00);
    Pause;

    // turn on interrupts

    NMIEN := $c0;
    Pause;

    // play endpart music

    msx_volume := 0;
    Poke(RMT_VOLUME, msx_volume);
    Pause;

    // enable endpart music

    msx.Init(MUSIC_ENDPART);
    Pause;
    music_is_playing := true;

    // Init scroll 

    scroll_address := END_TEXT_DATA;
    VSCROL := 0;
    line_counter := 0;

    // turn on screen

    SDMCTL := 62;

    fade_in_screen;

    // wait 5 seconds until scroll 

    Pause(5*60);

    // scroll story

    repeat

        for vsc_counter := 0 to 7 do begin

            Pause(10);
            DPoke(display_list_lms_end, scroll_address);
            VSCROL := vsc_counter;

        end;

        scroll_address := scroll_address + 40;
        line_counter := line_counter + 1;

    until line_counter = 20;

    // clear key presses

    CH := $ff;

    // wait for key

    repeat 
    
        // reset attraction flag

        ATRACT := 0;
    
    until keypressed or strigpressed;

    fade_out_screen;

    fade_out_music;

    restart_music := true;

end;


{ Displays a screen informing of the hero's death }
procedure game_over_screen;
begin

    fade_out_screen;

    // mute ingame music

    fade_out_music;
    music_is_playing := false;

    // clear key presses

    CH := $ff;

    // turn off screen

    SDMCTL := 0;
    move_pmg_off_screen;
    Pause;

    // set display list

    move(@display_list_game_over, pointer(DISPLAY_LIST_SAFE), sizeOf(display_list_game_over));
    Pause;

    SDLSTL := DISPLAY_LIST_SAFE;

    // depack data files

    unapl(pointer(PAK_DEATH_FONT), pointer(GAME_OVER_PIC_FONT));
    unapl(pointer(PAK_DEATH_DATA), pointer(GAME_OVER_PIC_DATA));
    unapl(pointer(PAK_TEXT_FONT), pointer(GAME_OVER_TEXT_FONT));
    unapl(pointer(PAK_GAME_OVER_TEXT), pointer(GAME_OVER_PIC_DATA + 13 * 40));

    // if level > 1 then display skip code

    if level > 0 then begin

        move(@CODE_DISPLAY[1], pointer(GAME_OVER_PIC_DATA + 13 * 40 + 7 * 40), 40);
        move(@LEVEL_CODES[level], pointer(GAME_OVER_PIC_DATA + 13 * 40 + 7 * 40 + 29), 5);

        // hide size char

        Poke(GAME_OVER_PIC_DATA + 13 * 40 + 7 * 40 + 29, 0);

    end;

    // turn on screen and wait for key

    // set display list interrupts

    Pause;
    SetIntVec(iDLI, @dli_game_over_00);
    Pause;

    NMIEN := $c0;
    Pause;

    // turn on screen

    SDMCTL := 62;

    // play game over music

    msx_volume := 0;
    Poke(RMT_VOLUME, msx_volume);
    Pause;

    // enable game over music 

    msx.Init(MUSIC_GAMEOVER);
    Pause;
    music_is_playing := true;

    fade_in_screen;

    repeat 
    
        // reset attraction flag

        ATRACT := 0;
    
    until keypressed or strigpressed;

    fade_out_screen;

    fade_out_music;

    restart_music := true;

    level := 0;

end;


{ Allows game levels to be skipped and time to be reset }
procedure cheat;
begin

    if keypressed then begin

        key := ReadKey;

        // cheat: level skipping

        if (key = 'q') or (key = 'Q') then exit_found := true;

        // cheat: reset time

        if (key = 'w') or (key = 'W') then begin

            time := 35;
            FillByte(pointer(PANEL + 40 + 5), 29, TIME_SYMBOL);

        end;

        // check if player want to mute music

        if key = 'm' then begin

            if silent_play then begin 

                msx.Init(MUSIC_INGAME); 
                silent_play := false;
                msx.Play();
                
            end else begin

                msx.Init(MUSIC_EMPTY); 
                silent_play := true;
                msx.Play();

            end; 

        end;

    end;

end;


{ Main game loop }
procedure game;
var 
    game_completed: boolean;

begin

    // set game state to not completed

    game_completed := false;

    // fade out title screen

    fade_out_screen;

    // fade out title music

    fade_out_music;
    music_is_playing := false;
    Pause;

    // silent game is off by default

    silent_play := false;

    // set volume to max

    msx_volume := 0;
    Poke(RMT_VOLUME, msx_volume);

    // init ingame music

    msx.Init(MUSIC_INGAME);

    // enable ingame music

    music_is_playing := true;

    game_over := false;

    repeat

        init_panel;
        init_maze(level);

        exit_found := false;

        repeat

            Pause(3);

            check_joy;

            // cheat;

            reveal_walls;

            update_player_position;

            animate_enemies;
            
            check_collision;

        until (time = 5) or exit_found or game_over;

        if exit_found then begin

            fade_out_screen;

            Pause;

            game_over := false;
            Inc(level);

            If level = MAX_LEVEL then game_completed := true;

        end else begin

            game_over := true;

        end;

    until game_over or game_completed;

    if game_completed then begin

        // set win sfx effect

        msx.Init(MUSIC_WIN);

        // enable ingame music

        music_is_playing := true;

        // stop counting time

        game_in_progress := false;

        // show congratulations screen

        congratulations;

    end;

    if game_over then begin

        // set die sfx effect

        msx.Init(MUSIC_DIE);

        // enable ingame music

        music_is_playing := true;
    
        // stop counting time

        game_in_progress := false;

        // show end screen

        game_over_screen;

    end;

end;


{ Exits program to DOS }
procedure dos_exit;
begin

    fade_out_screen;
    asm 
        JMP $000A 
    end;

end;


{ Displays the hero's story and the manual }
procedure display_help;
begin
    
    fade_out_screen;

    // clear key presses

    CH := $ff;

    // turn off screen

    SDMCTL := 0;
    move_pmg_off_screen;
    Pause;

    // set display list

    move(@display_list_help, pointer(DISPLAY_LIST_SAFE), sizeOf(display_list_help));
    Pause;

    SDLSTL := DISPLAY_LIST_SAFE;

    // depack data files

    unapl(pointer(PAK_TEXT_FONT), pointer(HELP_TEXT_FONT));

    unapl(pointer(PAK_INSTRUCTION_TEXT_PAGE_1), pointer(HELP_TEXT_DATA));

    // set font

    CHBAS := hi(HELP_TEXT_FONT);

    // turn on screen and wait for key

    Pause;

    NMIEN := $40;
    Pause;

    SDMCTL := 62;

    fade_in_screen;

    repeat 
    
        // reset attraction flag

        ATRACT := 0;
    
    until keypressed or strigpressed;

    // clear key presses

    CH := $ff;

    fade_out_screen;

    // turn off screen

    SDMCTL := 0;
    Pause;

    // set display list

    move(@display_list_help_page_2, pointer(DISPLAY_LIST_SAFE), sizeOf(display_list_help_page_2));
    Pause;

    SDLSTL := DISPLAY_LIST_SAFE;

    unapl(pointer(PAK_INSTRUCTION_TEXT_PAGE_2), pointer(HELP_TEXT_DATA));

    Pause;
    SDMCTL := 62;

    fade_in_screen;

    repeat 
    
        // reset attraction flag

        ATRACT := 0;
    
    until keypressed or strigpressed;

    fade_out_screen;

    restart_music := false;

end;


procedure vbl; interrupt;
begin
    if music_is_playing then msx.Play;
    if game_in_progress then update_time;
    asm {
        jmp $E462
        };
end;


{ Displays the title screen }
procedure title_screen;   
begin

    CH := $ff;

    COLOR1 := $00;
    COLOR2 := $00;

    // turn off screen

    SDMCTL := 0;
    move_pmg_off_screen;
    Pause;

    // depack title data files

    unapl(pointer(PAK_TITLE_FONT), pointer(TITLE_PIC_FONT));
    unapl(pointer(PAK_TITLE_DATA), pointer(TITLE_PIC));

    // set display list

    move(@display_list_title, pointer(DISPLAY_LIST_SAFE), sizeOf(display_list_title));
    Pause;

    SDLSTL := DISPLAY_LIST_SAFE;

    // set display list interrupts

    Pause;
    SetIntVec(iDLI, @dli_title_00);
    Pause;

    // turn on interrupts    

    NMIEN := $c0;
    Pause;

    // turn on screen

    SDMCTL := 62;

    fade_in_screen;

end;


{ Handles the entry of a code that allows the game to start from a specific level}
procedure enter_code;
var
    i: byte;
    j: byte;
    k: byte;
    code_compare: string[5];
    skip_code_screen_memory: word = CODE_DATA + 40 + 17; // Screen memory location from which to display the code to be entered
begin

    fade_out_screen;

    // turn off screen

    SDMCTL := 0;
    Pause;

    // set display list

    move(@display_list_code, pointer(DISPLAY_LIST_SAFE), sizeOf(display_list_help));
    Pause;

    SDLSTL := DISPLAY_LIST_SAFE;

    // unpack font

    unapl(pointer(PAK_TEXT_FONT), pointer(CODE_FONT));

    // clear RAM

    FillByte(pointer(CODE_DATA), 2*40, 0);

    // print text

    move(@CODE_STRING[1], pointer(CODE_DATA), 40);

    // set font

    CHBAS := hi(HELP_TEXT_FONT);

    // turn on screen and wait for code

    Pause;

    NMIEN := $40;
    Pause;

    SDMCTL := 62;

    fade_in_screen;

    // reset character register

    CH := $ff;

    // start counting from 1, 0 - length of string

    i := 1;

    // screen counter

    k := 0;

    code_match := false;

    repeat

        // wait for key

        repeat until keypressed;

        // read key

        key := ReadKey();

        // Only lower case letters are allowed (a..z)

        case key of

            #97..#122: begin

                // save to comparison array

                code_compare[i] := key;

                // print to screen

                Poke(skip_code_screen_memory + k, Ord(key));

                // increase index

                Inc(i);

                // print every second column

                Inc(k, 2);

            end;

        end;

    until i = 5;

    SetLength(code_compare,4);

    // Compare the entered codes with the code patterns

    for j := 1 to 19 do begin

        if code_compare = LEVEL_CODES[j] then begin

            code_match := true;
            level := j;
            break;

        end;

    end;

    restart_music := false;

end;


{ Main program loop }
begin

    SDMCTL := 0;

    // Init music

    // set volume to mute

    music_is_playing := false;
    msx_volume := 255;
    Poke(RMT_VOLUME, msx_volume);

    // Init sound player

    msx.player := pointer(RMT_PLAYER_ADR);
    msx.modul  := pointer(RMT_MODUL_ADR);

    // Set VBLANK procedure 

    SetIntVec(iVBL, @vbl);
    Pause; 

    repeat

        if restart_music then begin 

            msx.Init(MUSIC_TITLE);
            msx_volume := 0;
            Poke(RMT_VOLUME, msx_volume);
            music_is_playing := true;
            restart_music := true;

        end;

        // clear key presses

        CH := $ff;
        Pause;

        // set first level

        level := 0;

        // show title screen

        title_screen;

        // title screen loop

        repeat
            
            user_action := false;

            // reset attraction flag

            ATRACT := 0;

            // if something was pressed

            if keypressed then begin

                key := ReadKey();

                // it was a key?

                case key of 

                    'h', 'H': begin display_help; user_action := true; end;
                    'd', 'D': begin dos_exit; user_action := true; end;
                    'e', 'E': begin 
                        enter_code; 
                        user_action := true; 
                        if code_match then game;
                    end;

                end;

            end else begin

                // joystick button pressed?

                if strigpressed then begin

                    user_action := true;
                    game;

                end;

            end;

        until user_action = true;

    until 1 = 0;

end.
