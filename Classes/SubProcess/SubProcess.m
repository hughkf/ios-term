// SubProcess.m
// MobileTerminal

#import "SubProcess.h"

#include <util.h>
#include <sys/ttycom.h>
#include <unistd.h>

// These are simply used to initialize the terminal and are probably thrown
// away immediately after startup.
static const int kDefaultWidth = 80;
static const int kDefaultHeight = 25;

// Default username if we can't tell from the environment
//static const char kDefaultUsername[] = "mobile";

static int start_process(const char *path,
                         char *const args[],
                         char *const env[])
{
    return 0;
  fprintf(stdout, "begin start_process():\n");
    NSString* pathString = [NSString stringWithCString:path];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:pathString]) {
    fprintf(stderr, "%s: File does not exist\n", path);
    return -1;
  }
  // Notably, we don't test group or other bits so this still might not always
  // notice if the binary is not executable by us.
  if (![fileManager isExecutableFileAtPath:pathString]) {
    fprintf(stderr, "%s: File does not exist\n", path);
    return -1;
  }
  
  fprintf(stdout, "start_process: about to call execve\n");
  if (execve(path, args, env) == -1) {
    perror("execlp:");
    return -1;
  }
  // execve never returns if successful
  return 0;
}

@implementation SubProcess

- (id) init
{
  self = [super init];
  if (self != nil) {
    child_pid = 0;
    fd = 0;
    slave = 0;
    fileHandle = nil;
  }
  return self;
}

- (void) dealloc
{
  if (child_pid != 0) {
    [NSException raise:@"IllegalStateException"
                format:@"SubProcess was deallocated while running"];
  }
  [super dealloc];
}

int my_forkpty(amaster, name, termp, winp)
    int *amaster;
    char *name;
    struct termios *termp;
    struct winsize *winp;
{
    int master, slave;
    
    if (openpty(&master, &slave, name, termp, winp) == -1)
        return (-1);
    *amaster = master;
    return 0;
}

- (void)start
{
    if (fileHandle != nil){
        return;
    }
    
  if (child_pid != 0) {
    [NSException raise:@"IllegalStateException"
                format:@"SubProcess was already started"];
    return;
  }  
   struct winsize window_size;
   window_size.ws_col = kDefaultWidth;
   window_size.ws_row = kDefaultHeight;

    if (my_forkpty(&fd, NULL, NULL, NULL, &window_size) != 0) {
        fprintf(STDERR_FILENO, "my_forkpty: error!");
    }
    
    fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
    start_process("main", NULL, NULL);
    return;
  } 

- (void)stop
{
  if (child_pid == 0) {
    [NSException raise:@"IllegalStateException"
                format:@"SubProcess was never started"];
    return;
  }
  
  kill(child_pid, SIGKILL);
  int stat;
  waitpid(child_pid, &stat, WUNTRACED);

  fd = 0;
  child_pid = 0;
  [fileHandle release];
}

- (NSFileHandle*)fileHandle {
  return fileHandle;
}

@end
