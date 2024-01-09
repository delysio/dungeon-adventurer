procedure dli_title_00; assembler; interrupt;
asm {
    pha
    lda >TITLE_PIC_FONT
    sta WSYNC
    sta CHBASE

    mwa #dli_title_01 VDSLST
    pla
};
end;

procedure dli_title_01; assembler; interrupt;
asm {
    pha
    lda >TITLE_PIC_FONT + 1 * 1024
    sta WSYNC
    sta CHBASE

    mwa #dli_title_02 VDSLST
    pla
};
end;


procedure dli_title_02; assembler; interrupt;
asm {
    pha
    lda >TITLE_PIC_FONT + 2 * 1024
    sta WSYNC
    sta CHBASE

    mwa #dli_title_03 VDSLST
    pla
};
end;


procedure dli_title_03; assembler; interrupt;
asm {
    pha
    lda >TITLE_PIC_FONT + 3 * 1024
    sta WSYNC
    sta CHBASE

    mwa #dli_title_04 VDSLST
    pla
};
end;


procedure dli_title_04; assembler; interrupt;
asm {
    pha
    lda >TITLE_PIC_FONT + 4 * 1024
    sta WSYNC
    sta CHBASE

    mwa #dli_title_00 VDSLST
    pla
};
end;


procedure dli_game_over_00; assembler; interrupt;
asm {
    pha
    lda >GAME_OVER_PIC_FONT
    sta WSYNC
    sta CHBASE

    mwa #dli_game_over_01 VDSLST
    pla
};
end;


procedure dli_game_over_01; assembler; interrupt;
asm {
    pha
    lda >GAME_OVER_PIC_FONT + 1024
    sta WSYNC
    sta CHBASE

    mwa #dli_game_over_02 VDSLST
    pla
};
end;


procedure dli_game_over_02; assembler; interrupt;
asm {
    pha
    lda >GAME_OVER_TEXT_FONT
    sta WSYNC
    sta CHBASE

    mwa #dli_game_over_00 VDSLST
    pla
};
end;


procedure dli_end_00; assembler; interrupt;
asm {
    pha
    lda >END_PIC_FONT
    sta WSYNC
    sta CHBASE

    mwa #dli_end_01 VDSLST
    pla
};
end;


procedure dli_end_01; assembler; interrupt;
asm {
    pha
    lda >END_PIC_FONT + 1024
    sta WSYNC
    sta CHBASE

    mwa #dli_end_02 VDSLST
    pla
};
end;


procedure dli_end_02; assembler; interrupt;
asm {
    pha
    lda >END_TEXT_FONT
    sta WSYNC
    sta CHBASE

    mwa #dli_end_00 VDSLST
    pla
};
end;

