//  CommandLineInterpreter.m
//  MobileTerminal
//
//  Created by Hugh Krogh-Freeman on 9/15/15.

#import "CommandLineInterpreter.h"
#include <stdio.h>
#include <sys/stat.h>

@implementation CommandLineInterpreter

- (id)init: (TerminalView*)t {
    self = [super init];
    if (self == nil){
        view = t;
    }
    return self;
}

- (void) dealloc {
    [super dealloc];
    if (buff != NULL) free(buff);
}

char* join_strings(char* strings[], char* separator, int count) {
    char* str = NULL;             /* Pointer to the joined strings  */
    size_t total_length = 0;      /* Total length of joined strings */
    int i = 0;                    /* Loop counter                   */
    
    /* Find total length of joined strings */
    for (i = 0; i < count; i++) total_length += strlen(strings[i]);
    total_length++;     /* For joined string terminator */
    total_length += strlen(separator) * (count - 1); // for separators
    
    str = (char*) malloc(total_length);  /* Allocate memory for joined strings */
    str[0] = '\0';                      /* Empty string we can append to      */
    
    /* Append all the strings */
    for (i = 0; i < count; i++) {
        strcat(str, strings[i]);
        if (i < (count - 1)) strcat(str, separator);
    }
    
    return str;
}

- (char*)interpretCommand:(char**)cmd_args : (const char*)cmd : (int) length {

    if (strcmp("ls", cmd_args[0]) == 0) {
        return fish_main(length, cmd_args);
    }

    if (strcmp("exit", cmd_args[0]) == 0) {
        exit(EXIT_SUCCESS);
    }

    if (strcmp("clear", cmd_args[0]) == 0) {
        [[view textView] clearScreen];
        return NULL;
    }
    
    if (strcmp("echo", cmd_args[0]) == 0) {
        buff = (char*) malloc(strlen(cmd));
        cmd += strlen(cmd_args[0]);
        sprintf(buff, "\r\n %s", cmd);
        return buff;
    }

    if (strcmp("cd", cmd_args[0]) == 0) {

        if (cmd_args[1] == NULL) {
            chdir(getenv("HOME"));
            return NULL;
            
        } else {
            if (chdir(cmd_args[1]) == -1) {
                const char* format_str = " %s: no such directory\n";
                buff = (char*) malloc(strlen(cmd_args[1]) + strlen(format_str));
                sprintf(buff, format_str, cmd_args[1]);
                return buff;
            }
        }
    }
    return "\r\n Unknown command!";
}

void changeDirectory(char* directory)
{
    if (directory == NULL) {
        chdir(getenv("HOME"));
    } else {
        if (chdir(directory) == -1) {
            printf(" %s: no such directory\n", directory);
        }
    }
}

@end
