// SubProcess.m
#import "SubProcess.h"

#include <stdlib.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <util.h>
#include <sys/ioctl.h>
#import "Settings.h"

@implementation SubProcess

//static void signal_handler(int signal) {
//  NSLog(@"Caught signal: %d", signal);
//  [instance dealloc];
//  instance = nil;
//  exit(1);
//}

int start_process(const char* path, char* const args[], char* const env[]) {
  struct stat st;
  if (stat(path, &st) != 0) {
    fprintf(stderr, "%s: File does not exist\n", path);
    return -1;
  }
  if ((st.st_mode & S_IXUSR) == 0) {
    fprintf(stderr, "%s: Permission denied\n", path);
    return -1;
  }
  if (execve(path, args, env) == -1) {
    perror("execlp:");
    return -1;
  }
  // execve never returns if successful
  return 0;
}

- (id)initWithDelegate:(id)inputDelegate identifier:(int) tid
{
  self = [super init];
  fd = 0;
  delegate = inputDelegate;
  termid = tid;
  closed = 0;

  // Clean up when ^C is pressed during debugging from a console
//  signal(SIGINT, &signal_handler);

  Settings* settings = [Settings sharedInstance];

  struct winsize win;
  win.ws_col = [settings width];
  win.ws_row = [settings height];

  pid = forkpty(&fd, NULL, NULL, &win);
  if (pid == -1) {
    perror("forkpty");
    [self failure:@"[Failed to fork child process]"];
    exit(0);
  } else if (pid == 0) {
    // First try to use /bin/login since its a little nicer.  Fall back to
    // /bin/sh  if that is available.
    char* login_args[] = { "login", "-f", "root", (char*)0, };
    char* sh_args[] = { "sh", (char*)0, };
    char* env[] = { "TERM=vt100", (char*)0 };
    // NOTE: These should never return if successful
    start_process("/usr/bin/login", login_args, env);
    start_process("/bin/login", login_args, env);
    start_process("/bin/sh", sh_args, env);
    exit(0);
  }
  NSLog(@"Child process id: %d\n", pid);
  [NSThread detachNewThreadSelector:@selector(startIOThread:)
                           toTarget:self
                         withObject:delegate];
  return self;
}

- (void)dealloc
{
  [self close];
  [super dealloc];
}

- (void)closeSession { // this is invoked when the user closes that terminal session
	closed = 1;
	kill(pid, SIGHUP);
	int stat;
	waitpid(pid, &stat, WUNTRACED);
	[self close];
}

- (void)close
{
  if (fd != 0) {
    close(fd);
    fd = 0;
  }
}

- (BOOL)isRunning
{
  return (fd != 0) ? YES : NO;
}

- (int)write:(const char*)data length:(unsigned int)length
{
  return write(fd, data, length);
}

- (void)startIOThread:(id)inputDelegate
{
  [[NSAutoreleasePool alloc] init];

  const int kBufSize = 1024;
  char buf[kBufSize];
  ssize_t nread;
  while (1) {
    // Blocks until a character is ready
    nread = read(fd, buf, kBufSize);
    // On error, give a tribute to OS X terminal
    if (nread == -1) {
      perror("read");
			[self close];
			if(!closed)
				[self failure:@"[Process completed]"];
      return;
    } else if (nread == 0) {
			[self close];
			if(!closed)
				[self failure:@"[Process completed]"];
      return;
    }
    [inputDelegate handleStreamOutput:buf length:nread identifier:termid];
  }
}

- (void)failure:(NSString*)message;
{
  // HACK: Just pretend the message came from the child
  [delegate handleStreamOutput:[message cString] length:[message length] identifier:termid];
}

- (void)setWidth:(int)width height:(int)height
{
  struct winsize winsize;

  if (fd == 0)
    return;

  ioctl(fd, TIOCGWINSZ, &winsize);
  if (winsize.ws_col != width || winsize.ws_row != height) {
    winsize.ws_col = width;
    winsize.ws_row = height;
    ioctl(fd, TIOCSWINSZ, &winsize);
  }
}

- (void)setIdentifier:(int)tid
{
	termid = tid;
}

@end
