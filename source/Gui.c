#include <gba.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Main.h"
#include "FileHandling.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"
#include "cpu.h"
#include "GreenBeret.h"
#include "ARMZ80/Version.h"
#include "K005849/Version.h"
#include "SN76496/Version.h"

#define EMUVERSION "V0.2.1 2026-01-12"

static void scalingSet(void);
static const char *getScalingText(void);
static void controllerSet(void);
static const char *getControllerText(void);
static void swapABSet(void);
static const char *getSwapABText(void);
static void bgrLayerSet(void);
static const char *getBgrLayerText(void);
static void sprLayerSet(void);
static const char *getSprLayerText(void);
static void coinASet(void);
static const char *getCoinAText(void);
static void coinBSet(void);
static const char *getCoinBText(void);
static void difficultSet(void);
static const char *getDifficultText(void);
static void livesSet(void);
static const char *getLivesText(void);
static void bonusSet(void);
static const char *getBonusText(void);
static void cabinetSet(void);
static const char *getCabinetText(void);
static void demoSet(void);
static const char *getDemoText(void);
static void flipSet(void);
static const char *getFlipText(void);
static void uprightSet(void);
static const char *getUprightText(void);
static void serviceSet(void);
static const char *getServiceText(void);
static void brightSet(void);


const MItem dummyItems[] = {
	{"", uiDummy},
};
const MItem mainItems[] = {
	{"File->", ui2},
	{"Controller->", ui3},
	{"Display->", ui4},
	{"DipSwitches->", ui5},
	{"Settings->", ui6},
	{"Debug->", ui7},
	{"About->", ui8},
	{"Sleep", gbaSleep},
	{"Restart", resetGame},
	{"Quit Emulator", ui10},
};
const MItem fileItems[] = {
	{"Load Game->", ui9},
	{"Load State", loadState},
	{"Save State", saveState},
	{"Save Settings", saveSettings},
	{"Reset Game", resetGame},
};
const MItem ctrlItems[] = {
	{"B Autofire: ", autoBSet, getAutoBText},
	{"A Autofire: ", autoASet, getAutoAText},
	{"Controller: ", controllerSet, getControllerText},
	{"Swap A-B:   ", swapABSet, getSwapABText},
};
const MItem displayItems[] = {
	{"Display: ", scalingSet, getScalingText},
	{"Scaling: ", flickSet, getFlickText},
	{"Gamma: ", brightSet, getGammaText},
};
const MItem dipswitchItems[] = {
	{"Difficulty: ", difficultSet, getDifficultText},
	{"Coin A: ", coinASet, getCoinAText},
	{"Coin B: ", coinBSet, getCoinBText},
	{"Lives: ", livesSet, getLivesText},
	{"Bonus: ", bonusSet, getBonusText},
	{"Cabinet: ", cabinetSet, getCabinetText},
	{"Demo Sound: ", demoSet, getDemoText},
	{"Flip Screen: ", flipSet, getFlipText},
	{"Upright Controls: ", uprightSet, getUprightText},
	{"Service Mode: ", serviceSet, getServiceText},
};
const MItem setItems[] = {
	{"Speed: ", speedSet, getSpeedText},
	{"Autoload State: ", autoStateSet, getAutoStateText},
	{"Autosave Settings: ", autoSettingsSet, getAutoSettingsText},
	{"Autopause Game: ", autoPauseGameSet, getAutoPauseGameText},
	{"EWRAM Overclock: ", ewramSet, getEWRAMText},
	{"Autosleep: ", sleepSet, getSleepText},
};
const MItem debugItems[] = {
	{"Debug Output: ", debugTextSet, getDebugText},
	{"Disable Background: ", bgrLayerSet, getBgrLayerText},
	{"Disable Sprites: ", sprLayerSet, getSprLayerText},
	{"Step Frame", stepFrame},
};
const MItem fnList9[GAME_COUNT] = {
	{"Green Beret", quickSelectGame},
	{"Rush'n Attack (US)", quickSelectGame},
	{"Green Beret (bootleg)", quickSelectGame},
	{"Mr. Goemon (Japan)", quickSelectGame},
};
const MItem quitItems[] = {
	{"Yes", exitEmulator},
	{"No", backOutOfMenu},
};

const Menu menu0 = MENU_M("", uiNullNormal, dummyItems);
Menu menu1 = MENU_M("Main Menu", uiAuto, mainItems);
const Menu menu2 = MENU_M("File Handling", uiAuto, fileItems);
const Menu menu3 = MENU_M("Controller Settings", uiAuto, ctrlItems);
const Menu menu4 = MENU_M("Display Settings", uiAuto, displayItems);
const Menu menu5 = MENU_M("Dipswitch Settings", uiDipswitches, dipswitchItems);
const Menu menu6 = MENU_M("Other Settings", uiAuto, setItems);
const Menu menu7 = MENU_M("Debug", uiAuto, debugItems);
const Menu menu8 = MENU_M("About", uiAbout, dummyItems);
const Menu menu9 = MENU_M("Load game", uiAuto, fnList9);
const Menu menu10 = MENU_M("Quit Emulator?", uiAuto, quitItems);

const Menu *const menus[] = {&menu0, &menu1, &menu2, &menu3, &menu4, &menu5, &menu6, &menu7, &menu8, &menu9, &menu10 };

char *const ctrlTxt[]   = {"1P","2P"};
char *const dispTxt[]   = {"Unscaled","Scaled"};

char *const coinTxt[]   = {
	"1 Coin 1 Credit",  "1 Coin 2 Credits", "1 Coin 3 Credits", "1 Coin 4 Credits",
	"1 Coin 5 Credits", "1 Coin 6 Credits", "1 Coin 7 Credits", "2 Coins 1 Credit",
	"2 Coins 3 Credits","2 Coins 5 Credits","3 Coins 1 Credit", "3 Coins 2 Credits",
	"3 Coins 4 Credits","4 Coins 1 Credit", "4 Coins 3 Credits","Free Play"
};
char *const diffTxt[]   = {"Easy","Normal","Hard","Very Hard"};
char *const livesTxt[]  = {"2","3","5","7"};
char *const bonusTxt[]  = {"30K 70K 70K+","40K 80K 80K+","50K 100K 100K+","50K 200K 200K+"};
char *const cabTxt[]    = {"Cocktail","Upright"};
char *const singleTxt[] = {"Single","Dual"};


/// This is called at the start of the emulator
void setupGUI() {
	emuSettings = AUTOPAUSE_EMULATION;
//	keysSetRepeat(25, 4);	// Delay, repeat.
	menu1.itemCount = ARRSIZE(mainItems) - (enableExit?0:1);
	closeMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
}

/// This is called going from ui to emu.
void exitGUI() {
}

void quickSelectGame(void) {
	while (loadGame()) {
		redrawUI();
		return;
	}
	closeMenu();
}

void uiNullNormal() {
	uiNullDefault();
}

void uiAbout() {
	setupSubMenuText();
	drawText("Select: Insert coin",3);
	drawText("Start:  Start button",4);
	drawText("DPad:   Move character",5);
	drawText("Up:     Jump/Climb",6);
	drawText("Down:   Crouch",7);
	drawText("B:      Knife attack",8);
	drawText("A:      Special attack",9);

	drawText("GreenBeretGBA " EMUVERSION, 16);
	drawText("ARMZ80        " ARMZ80VERSION, 17);
	drawText("K005849       " K005849VERSION, 18);
	drawText("ARMSN76496    " ARMSN76496VERSION, 19);
}

void uiDipswitches() {
	char s[10];
	uiAuto();

	setMenuItemRow(15);
	int2Str(coinCounter0, s);
	drawSubItem("CoinCounter1:       ", s);
	int2Str(coinCounter1, s);
	drawSubItem("CoinCounter2:       ", s);
}

void nullUINormal(int key) {
}

void nullUIDebug(int key) {
}

void resetGame() {
	loadCart(0,0);
}


//---------------------------------------------------------------------------------
/// Switch between Player 1 & Player 2 controls
void controllerSet() {				// See io.s: refreshEMUjoypads
	joyCfg ^= 0x20000000;
}
const char *getControllerText() {
	return ctrlTxt[(joyCfg>>29)&1];
}

/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}
const char *getSwapABText() {
	return autoTxt[(joyCfg>>10)&1];
}

/// Turn on/off scaling
void scalingSet(){
	gScaling ^= 0x01;
	refreshGfx();
}
const char *getScalingText() {
	return dispTxt[gScaling];
}

/// Change gamma (brightness)
void brightSet() {
	gammaSet();
	paletteInit(gGammaValue);
	paletteTxAll();					// Make new palette visible
	setupMenuPalette();
}

/// Turn on/off rendering of background
void bgrLayerSet(){
	gGfxMask ^= 0x03;
}
const char *getBgrLayerText() {
	return autoTxt[(gGfxMask>>1)&1];
}
/// Turn on/off rendering of sprites
void sprLayerSet(){
	gGfxMask ^= 0x10;
}
const char *getSprLayerText() {
	return autoTxt[(gGfxMask>>4)&1];
}


/// Number of coins for credits
void coinASet() {
	int i = (g_dipSwitch0+1) & 0xF;
	g_dipSwitch0 = (g_dipSwitch0 & ~0xF) | i;
}
const char *getCoinAText() {
	return coinTxt[g_dipSwitch0 & 0xF];
}
/// Number of coins for credits
void coinBSet() {
	int i = (g_dipSwitch0+0x10) & 0xF0;
	g_dipSwitch0 = (g_dipSwitch0 & ~0xF0) | i;
}
const char *getCoinBText() {
	return coinTxt[(g_dipSwitch0>>4) & 0xF];
}
/// Number of lifes to start with
void livesSet() {
	int i = (g_dipSwitch1+1) & 3;
	g_dipSwitch1 = (g_dipSwitch1 & ~3) | i;
}
const char *getLivesText() {
	return livesTxt[g_dipSwitch1 & 3];
}
/// At which score you get bonus lifes
void bonusSet() {
	int i = (g_dipSwitch1+8) & 0x18;
	g_dipSwitch1 = (g_dipSwitch1 & ~0x18) | i;
}
const char *getBonusText() {
	return bonusTxt[(g_dipSwitch1>>3)&3];
}
/// Game difficulty
void difficultSet() {
	int i = (g_dipSwitch1+0x20) & 0x60;
	g_dipSwitch1 = (g_dipSwitch1 & ~0x60) | i;
}
const char *getDifficultText() {
	return diffTxt[(g_dipSwitch1>>5)&3];
}
/// Cocktail/upright
void cabinetSet() {
	g_dipSwitch1 ^= 0x04;
}
const char *getCabinetText() {
	return cabTxt[(g_dipSwitch1>>2)&1];
}
/// Demo sound on/off
void demoSet() {
	g_dipSwitch1 ^= 0x80;
}
const char *getDemoText() {
	return autoTxt[(g_dipSwitch1>>7)&1];
}
/// Flip screen
void flipSet() {
	g_dipSwitch2 ^= 0x01;
}
const char *getFlipText() {
	return autoTxt[g_dipSwitch2&1];
}
/// Dual or single controlls for upright set
void uprightSet() {
	g_dipSwitch2 ^= 0x02;
}
const char *getUprightText() {
	return singleTxt[(g_dipSwitch2>>1)&1];
}
/// Test/Service mode
void serviceSet() {
	g_dipSwitch2 ^= 0x04;
}
const char *getServiceText() {
	return autoTxt[(g_dipSwitch2>>2)&1];
}
