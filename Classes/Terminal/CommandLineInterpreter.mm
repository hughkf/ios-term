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

// Stores the trimmed input string into the given output buffer, which must be
// large enough to store the result.  If it is too small, the output is
// truncated.
size_t trimwhitespace(char *out, size_t len, const char *str)
{
    if(len == 0)
        return 0;
    
    const char *end;
    size_t out_size;
    
    // Trim leading space
    while(isspace(*str)) str++;
    
    if(*str == 0)  // All spaces?
    {
        *out = 0;
        return 1;
    }
    
    // Trim trailing space
    end = str + strlen(str) - 1;
    while(end > str && isspace(*end)) end--;
    end++;
    
    // Set output size to minimum of trimmed string length and buffer size minus 1
    out_size = (end - str) < len-1 ? (end - str) : len-1;
    
    // Copy trimmed string and add null terminator
    memcpy(out, str, out_size);
    out[out_size] = 0;
    
    return out_size;
}

// Note: This function returns a pointer to a substring of the original string.
// If the given string was allocated dynamically, the caller must not overwrite
// that pointer with the returned value, since the original pointer must be
// deallocated using the same allocator with which it was allocated.  The return
// value must NOT be deallocated using free() etc.
char *trimwhitespace(char *str)
{
    char *end;
    
    // Trim leading space
    while(isspace(*str)) str++;
    
    if(*str == 0)  // All spaces?
        return str;
    
    // Trim trailing space
    end = str + strlen(str) - 1;
    while(end > str && isspace(*end)) end--;
    
    // Write new null terminator
    *(end+1) = 0;
    
    return str;
}

- (char *) ls: (char*) pathname
{
    int count,i;
    struct direct **files;
    char *path;
    
    if (pathname == NULL || strlen(pathname) == 0
        || trimwhitespace(NULL, strlen(pathname), pathname) == 0) {
        path = [self string_literal: "."];
    }
    else if( !getcwd(pathname, sizeof(pathname)) ) {
        return [self string_literal: "No such file or directory\n"];
    } else {
        path = strdup(pathname);
    }
    
    count = scandir(path, &files, file_select, alphasort);
    if(count == 0)
        return [self string_literal : " "];
    
    int total_chars_to_alloc = 0;
    for (i=1; i<count+1; ++i)
        total_chars_to_alloc += strlen(files[i-1]->d_name);
    
    //if (buff != NULL) free(buff);
    //tmp = NULL;
    assert(total_chars_to_alloc > 0);
    char* tmp = (char* ) malloc( total_chars_to_alloc + count*strlen("\r\n") + count );
    
    for (i = 1; i < count+1; ++i) {
        if (strlen(files[i-1]->d_name) > 0 && total_chars_to_alloc > 0) {
            strncat(tmp, files[i-1]->d_name, strlen(files[i-1]->d_name));
            strncat(tmp, "\r\n", strlen("\r\n"));
            fprintf(stderr, "tmp:\"%s\"", tmp);
            total_chars_to_alloc -= (strlen("\r\n") + strlen(files[i-1]->d_name));
        }
    }
    return tmp;
}


- (char *) ls_old: (char*) pathname
{
    int count,i;
    struct direct **files;
    char* path;
    
    if (pathname == NULL || strlen(pathname) == 0
    || trimwhitespace(NULL, strlen(pathname), pathname) == 0) {
        path = [self string_literal: "."];
    }
    else if( !getcwd(pathname, sizeof(pathname)) ) {
            return [self string_literal: "No such file or directory\n"];
    } else {
        path = strdup(pathname);
    }
    
    count = scandir(path, &files, file_select, alphasort);
    if(count <= 0) return [self string_literal : " "];

    int total_chars_to_alloc = 0;
    for (i=1; i<count+1; ++i)
        total_chars_to_alloc += strlen(files[i-1]->d_name);
    
    //char* tmp;
    //fprintf(stderr, "%s", buff);
    if (buff != NULL) free(buff);
    buff = NULL;
    
    buff = (char* ) malloc( total_chars_to_alloc * sizeof(char) );
    //memset((void*)buff, (char)' ', strlen(buff));

    for (i = 1; i < count+1; ++i) {
        if (strlen(files[i-1]->d_name) > 0) {
            //tmp = (char*) malloc(strlen(files[i-1]->d_name) + 3);
            //sprintf(tmp, "\r\n%s", files[i-1]->d_name);
            strcat(buff, files[i-1]->d_name);
            strcat(buff, "\r\n");
        }
    }
    //if (tmp != NULL) free(tmp);
    //tmp = NULL;
    printf("%s", buff);
    return buff;
}

- (id)init: (TerminalView*)t {
    self = [super init];
    if (self == nil){
        view = t;
        buff = NULL;
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

char buffer[1024];

- (const char*)interpretCommand:(char**)cmd_args : (const char*)cmd : (int) length {

    fprintf(stderr, "length: \"%d\"", length);
    
    if (cmd_args == NULL || strlen(cmd_args[0]) == 0)
        return "";
    
    else if (strcmp("pwd", cmd_args[0]) == 0) {
        buff = (char*) malloc(1024 * sizeof(char) );
        getcwd(buff, strlen(buff));
        sprintf(buffer, "\r\n%s", buff);
        if (buff != NULL) free(buff);
        buff = NULL;
        return buffer;
    }

    else if (strcmp("ls", cmd_args[0]) == 0 && length < 2) {
        return [self ls : NULL ];
    }

    else if (strcmp("ls", cmd_args[0]) == 0 && length >= 2) {
        return [self ls : cmd_args[1]];
    }

    else if (strcmp("exit", cmd_args[0]) == 0) {
        exit(EXIT_SUCCESS);
    }

    else if (strcmp("clear", cmd_args[0]) == 0) {
        [[view textView] clearScreen];
        return NULL;
    }
    
    else if (strcmp("echo", cmd_args[0]) == 0) {
        buff = (char*) malloc(strlen(cmd));
        cmd += strlen(cmd_args[0]);
        sprintf(buff, "\r\n %s", cmd);
        return buff;
    }

    else if (strcmp("cd", cmd_args[0]) == 0) {

        if (cmd_args[1] == NULL) {
            chdir(getenv("HOME"));
            
        } else if (chdir(cmd_args[1]) == -1) {
                const char* format_str = " %s: no such directory\n";
                buff = (char*) malloc(strlen(cmd_args[1]) + strlen(format_str));
                sprintf(buff, format_str, cmd_args[1]);
                return buff;
        }
        return "";
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
