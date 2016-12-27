#ifndef IMPORTS_H
#define IMPORTS_H

#include <3ds.h>
#include "../../build/constants.h"

#define LINEAR_BUFFER ((u8*)0x31000000)
#define PAINT_APPMEMTYPE_PTR 0x1FF80030
#define PAINT_MAX_CODEBIN_SIZE 0xE5000

static Handle* const fsHandle = (Handle*)PAINT_FSUSER_HANDLE;
static Handle* const dspHandle = (Handle*)PAINT_DSP_HANDLE;
static Handle* const gspHandle = (Handle*)PAINT_GSPGPU_HANDLE;

static u32** const sharedGspCmdBuf = (u32**)(PAINT_GSPGPU_INTERRUPT_RECEIVER_STRUCT + 0x58);

static Result (* const _GSPGPU_FlushDataCache)(Handle* handle, Handle kProcess, u32* addr, u32 size) = (void*)PAINT_GSPGPU_FLUSHDATACACHE;
static Result (* const _GSPGPU_GxTryEnqueue)(u32** sharedGspCmdBuf, u32* cmdAddr) = (void*)PAINT_GXTRYENQUEUE;
static Result (* const _DSP_UnloadComponent)(Handle* handle) = (void*)PAINT_DSP_UNLOADCOMPONENT;
static Result (* const _DSP_RegisterInterruptEvents)(Handle* handle, Handle event, u32 type, u32 port) = (void*)PAINT_DSP_REGISTERINTERRUPTEVENTS;

#endif
