    
display_list_game: array[0..33] of byte = (

    $70, $70, $70,
    $42, lo(level_screen), hi(level_screen),
    $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2,

    $42, lo(PANEL), hi(PANEL), $2, $2,

    $41, lo($0600), hi($0600)
);

display_list_title: array[0..30] of byte = (

    $70 + $80,
    $42, lo(TITLE_PIC), hi(TITLE_PIC),
    $2, $2, $2, $2 + $80, $2, $2, $2, $2, $2 + $80, $2, $2, $2, $2, $2, $2, $2 + $80, $2, $2, $2, $2, $2, $2 + $80, $2, $2,

    $41, lo($0600), hi($0600)
);

display_list_game_over: array[0..31] of byte = (

    $70, $70, $70 + $80,
    $42, lo(GAME_OVER_PIC_DATA), hi(GAME_OVER_PIC_DATA),
    $2, $2, $2, $2, $2, $2, $2 + $80, $2, $2, $2, $2, $2 + $80, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2,

    $41, lo($0600), hi($0600)
);

display_list_help: array[0..31] of byte = (

    $70, $70, $70,
    $42, lo(HELP_TEXT_DATA), hi(HELP_TEXT_DATA),
    $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $0, $2, $0, $2, $0, $2, $2, $0, $2, $2, $70, $2,

    $41, lo($0600), hi($0600)
);

display_list_help_page_2: array[0..28] of byte = (

    $70, $70, $70,
    $42, lo(HELP_TEXT_DATA), hi(HELP_TEXT_DATA),
    $2, $2, $2, $2, $2, $2, $2, $70, $70, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, $2, 

    $41, lo($0600), hi($0600)
);

display_list_congrats: array[0..35] of byte = (

    $70, $70 + $80,
    $42, lo(END_PIC_DATA), hi(END_PIC_DATA),
    $2, $2, $2, $2, $2, $2, $2, $2 + $80, $2, $2, $2 + $80, $70, 
    $42 + $20, lo(END_TEXT_DATA), hi(END_TEXT_DATA),
    $2 + $20, $2 + $20, $2 + $20, $2 + $20, $2 + $20, $2 + $20, $2 + $20, $2 + $20, $2 + $20, $2 + $20, $2 + $20, $2 + $20, $2,

    $41, lo($0600), hi($0600)
);


