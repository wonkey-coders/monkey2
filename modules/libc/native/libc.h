
//Libc fudge, mainly for windows.

#ifndef BB_LIB_C_H
#define BB_LIB_C_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <dirent.h>

#if _WIN32
#include <direct.h>
#else
#include <unistd.h>
#endif

typedef struct stat stat_t;

int system_( const char *command );
void setenv_( const char *name,const char *value,int overwrite );
int mkdir_( const char *path,int mode );

#endif
