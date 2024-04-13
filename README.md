# F256_FlashCart
A simple basic program for programming the Flash part.

To use it, run the program and type the name of the file you want on the Flash cartridge.

Lines 1000-1999 are reserved for defining the behavior of the program.

Default implementation:
If your file is less than 256KB, undefined data will be written after the end of the file
until all 256KB of the cart are filled.  If you don't like this, feel free to write a proper
user interface for this program.
