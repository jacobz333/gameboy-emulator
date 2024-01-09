### Gameboy without audio
-Jacob Z

To run this project, generate the bitstream for all design_source files. Next export to Vitis, build the software/hardware xsa, and program. Be sure to set the switches to their desired game to avoid corruption.

The Gameboy contains 8 buttons, which were mapped to different keys on the keyboard:
| Button | Key |
| :----: | :----: |
| START | Enter |
| SELECT | S |
| A | A |
| B | Z |
| UP | Up |
| DOWN | Down |
| LEFT | Left |
| RIGHT | Right |


Currently, 3 games are loaded as specified in `cartridge.sv`. The switches S1 and S0 specify the game selected: (0=off, 1=on)
| {S1,S0} | Game |
| :--: | ------ |
| 00 | No game; running this will lock the program counter at 0x00E8 and nothing will happen. |
| 01 | Tetris (32kB) |
| 10 | Super Mario Land (64kB) |
| 11 | Galaga (128kB) |

Switching the game loaded during gameplay will most likely lock up the system and display garbage.

It is possible to load in more games by changing the code in `cartridge.sv` and resynthesizing. This Gameboy implementation supports 32kB, 64kB, and 128kB ROMs. Replacing the corresponding size rom will load another game. For example, to load Dr. Mario (32kB), replace `"tetris_rom"` with `"dr_mario_rom"` in `cartridge.sv`; This BRAM IP for this already a part of the project files.
To load your own game, run the function `file_to_coe` in `hex_to_sv.py` to convert the `.gb` file into a `.coe` file. Then create a BRAM/Distributed Memory IP initialized to said COE file.


The hex displays are primarily for debugging:
| Displays | Meaning |
| :--: | ------ |
| 1-4 | `PC` = Program Counter |
| 5-6 | `LCDC` = LCD control |
| 7-8 | `keycode[7:0]`; to check that the keyboard keycodes are received |


BTN0 is the reset button and can be use to reset the system. This can be used to load a different game, but this is not reliable and may corrupt the memory.


All other buttons, LEDs, and switches do not mean anything.
