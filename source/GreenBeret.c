#include <gba.h>

#include "GreenBeret.h"
#include "Gfx.h"
#include "Sound.h"
#include "ARMZ80/ARMZ80.h"
#include "SN76496/SN76496.h"
#include "K005849/K005849.h"


int packState(void *statePtr) {
	int size = k005849SaveState(statePtr, &k005849_0);
	size += sn76496SaveState(statePtr+size, &SN76496_0);
	size += Z80SaveState(statePtr+size, &Z80OpTable);
	return size;
}

void unpackState(const void *statePtr) {
	int size = k005849LoadState(&k005849_0, statePtr);
	size += sn76496LoadState(&SN76496_0, statePtr+size);
	Z80LoadState(&Z80OpTable, statePtr+size);
}

int getStateSize() {
	int size = k005849GetStateSize();
	size += sn76496GetStateSize();
	size += Z80GetStateSize();
	return size;
}
