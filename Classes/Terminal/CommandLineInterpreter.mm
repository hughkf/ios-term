//  CommandLineInterpreter.m
//  MobileTerminal
//
//  Created by Hugh Krogh-Freeman on 9/15/15.

#import "CommandLineInterpreter.h"
//#import "ls.h"
#include <stdio.h>
#include <sys/stat.h>

#include <sys/types.h>
#include <sys/dir.h>
#include <sys/param.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

@implementation CommandLineInterpreter


extern  int alphasort(); //Inbuilt sorting function

void die(char *msg)
{
    perror(msg);
    exit(0);
}

int file_select(const struct direct *entry)
{
    if ((strcmp(entry->d_name, ".") == 0) || (strcmp(entry->d_name, "..") == 0))
        return (FALSE);
    else
        return (TRUE);
}

- (char *) ls: (char*) pathname
{
    int count,i;
    struct direct **files;

    if (pathname == NULL || strlen(pathname) == 0)
        pathname = [self string_literal: "."];
    
    else if( !getcwd(pathname, sizeof(pathname)) )
            return [self string_literal: "No such file or directory\n"];
        
    count = scandir(pathname, &files, file_select, alphasort);
    if(count <= 0) return [self string_literal : " "];

    int total_chars_to_alloc = 0;
    for (i=1; i<count+1; ++i)
        total_chars_to_alloc += strlen(files[i-1]->d_name);
    
    char* tmp;
    
    buff = (char* ) malloc( total_chars_to_alloc * sizeof(char) + count + 1 );
    for (int i = 1; i < count+1; ++i) {
        tmp = (char*) malloc(strlen(files[i-1]->d_name) + 3);
        sprintf(tmp, "\r\n%s", files[i-1]->d_name);
        strcat(buff, tmp);
    }
    printf("%s", buff);
    return buff;
}

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

- (const char*)interpretCommand:(char**)cmd_args : (const char*)cmd : (int) length {

    if (strcmp("ls", cmd_args[0]) == 0) {
        return [self ls : cmd_args[1] ];
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
    return [self string_literal: "\r\n Unknown command!"];
}

- (char*) string_literal : (const char*) str {
    /**  Workaround for 
     incessant "Conversion from string
     literal to 'char *' is deprecated" 
     formerly warning, now Error  */
    
    buff = (char*) malloc(strlen(str));
    sprintf(buff, "%s", str);
    return buff;
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
