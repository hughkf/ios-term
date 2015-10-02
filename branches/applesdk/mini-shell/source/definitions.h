
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <signal.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <termios.h>
#define TRUE 1
#define FALSE 0



#define BUFFER_MAX_LENGTH 50
static char* currentDirectory;
static char userInput = '\0';
static char buffer[BUFFER_MAX_LENGTH];
static int bufferChars = 0;

static char *commandArgv[5];
static int commandArgc = 0;


#define FOREGROUND 'F'
#define BACKGROUND 'B'
#define SUSPENDED 'S'
#define WAITING_INPUT 'W'


#define STDIN 1
#define STDOUT 2


#define BY_PROCESS_ID 1
#define BY_JOB_ID 2
#define BY_JOB_STATUS 3

static int numActiveJobs = 0;

typedef struct job {
        int id;
        char *name;
        pid_t pid;
        pid_t pgid;
        int status;
        char *descriptor;
        struct job *next;
} t_job;

static t_job* jobsList = NULL;



static pid_t MSH_PID;
static pid_t MSH_PGID;
static int MSH_TERMINAL, MSH_IS_INTERACTIVE;
static struct termios MSH_TMODES;

void pipelining(int);
void getTextLine();

void populateCommand();

void destroyCommand();

t_job * insertJob(pid_t pid, pid_t pgid, char* name, char* descriptor,
                  int status);

t_job* delJob(t_job* job);

t_job* getJob(int searchValue, int searchParameter);

void printJobs();

void welcomeScreen();

void shellPrompt();
void handleUserCommand();

int checkBuiltInCommands();

void executeCommand(char *command[], char *file, int newDescriptor,
                    int executionMode);

void launchJob(char *command[], char *file, int newDescriptor,
               int executionMode);

void putJobForeground(t_job* job, int continueJob);

void putJobBackground(t_job* job, int continueJob);

void waitJob(t_job* job);

void killJob(int jobId);

void changeDirectory();

void init();

void signalHandler_child(int p);
