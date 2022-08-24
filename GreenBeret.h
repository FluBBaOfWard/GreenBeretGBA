#ifndef GREENBERET_HEADER
#define GREENBERET_HEADER

#ifdef __cplusplus
extern "C" {
#endif

/// This runs all save state functions for each chip.
int packState(void *statePtr);
/// This runs all load state functions for each chip.
void unpackState(const void *statePtr);
/// Gets the total state size in bytes.
int getStateSize(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // GREENBERET_HEADER
