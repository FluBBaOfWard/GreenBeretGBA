#ifndef SOUND_HEADER
#define SOUND_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "SN76496/SN76496.h"

extern SN76496 SN76496_0;

void soundInit(void);
void soundSetFrequency(void);
void setMuteSoundGUI(void);
void vblSound2(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // SOUND_HEADER
