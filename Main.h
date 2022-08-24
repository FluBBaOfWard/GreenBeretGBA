#ifndef MAIN_HEADER
#define MAIN_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern bool enableExit;
extern bool pauseEmulation;
extern int powerButton;
extern int sleepTime;
extern int selectedGame;
extern u16 *menuMap;

void waitVBlank(void);
void pausVBlank(int count);
void setEmuSpeed(int speed);
void setupMenuPalette(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // MAIN_HEADER
