#include <stddef.h>
#include <stdint.h>
 
#if defined(__linux__)
	#error "This code must be compiled with a cross-compiler"
#elif !defined(__i386__)
	#error "This code must be compiled with an x86-elf compiler"
#endif
 
volatile uint16_t* vga_buffer = (uint16_t*)0xB8000;
constexpr int kVgaCols = 80;
constexpr int kVgaRows = 25;
 
int term_col = 0;
int term_row = 0;
uint8_t term_color = 0x1F; // Black background, White foreground
 
// This function initiates the terminal by clearing it
void term_init()
{
	// Clear the textmode buffer
	for (int col = 0; col < kVgaCols; col ++)
	{
		for (int row = 0; row < kVgaRows; row ++)
		{
			// The VGA textmode buffer has size (kVgaCols * kVgaRows).
			// Given this, we find an index into the buffer for our character
			const size_t index = (kVgaCols * row) + col;
			// Entries in the VGA buffer take the binary form BBBBFFFFCCCCCCCC, where:
			// - B is the background color
			// - F is the foreground color
			// - C is the ASCII character
			vga_buffer[index] = ((uint16_t)term_color << 8) | ' '; // Set the character to blank (a space character)
		}
	}
}
 
// This function places a single character onto the screen
void term_putc(char c)
{
	// Remember - we don't want to display ALL characters!
	switch (c)
	{
	case '\n': // Newline characters should return the column to 0, and increment the row
		{
			term_col = 0;
			term_row ++;
			break;
		}
 
	default: // Normal characters just get displayed and then increment the column
		{
			const size_t index = (kVgaCols * term_row) + term_col; // Like before, calculate the buffer index
			vga_buffer[index] = ((uint16_t)term_color << 8) | c;
			term_col ++;
			break;
		}
	}
 
	if (term_col >= kVgaCols)
	{
		term_col = 0;
		term_row ++;
	}
 
	if (term_row >= kVgaRows)
	{
		term_col = 0;
		term_row = 0;
	}
}
 
void term_print(const char* str)
{
	for (size_t i = 0; str[i] != '\0'; i ++) // Keep placing characters until we hit the null-terminating character ('\0')
		term_putc(str[i]);
}
 
 
#if defined(__cplusplus)
extern "C" /* Use C linkage for kernel_main. */
#endif
void kernel_main()
{
	term_init();
 
	term_print(R"(Somebody once told me the world is gonna roll me
I ain't the sharpest tool in the shed
She was looking kind of dumb with her finger and her thumb
In the shape of an "L" on her forehead

Well, the years start coming and they don't stop coming
Fed to the rules and I hit the ground running
Didn't make sense not to live for fun
Your brain gets smart but your head gets dumb

So much to do, so much to see
So what's wrong with taking the back streets?
You'll never know if you don't go
You'll never shine if you don't glow

[Chorus:]
Hey, now, you're an All Star, get your game on, go play
Hey, now, you're a Rock Star, get the show on, get paid
And all that glitters is gold
Only shooting stars break the mold

It's a cool place and they say it gets colder
You're bundled up now wait 'til you get older
But the meteor men beg to differ
Judging by the hole in the satellite picture
)");
}