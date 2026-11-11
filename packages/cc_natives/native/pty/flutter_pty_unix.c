
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <errno.h>
#include <poll.h>
#include <pthread.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/wait.h>

#include "forkpty.h"
#include "flutter_pty.h"

#include "include/dart_api.h"
#include "include/dart_api_dl.h"
#include "include/dart_native_api.h"

// How often the reader looks up from an idle terminal to see whether its
// session is over.
#define PTY_READ_POLL_MS 50

// How long an exit waits for the last output to be handed over first.
#define PTY_EXIT_DRAIN_MS 500

typedef struct PtyHandle
{
    // The master end. -1 once the session is over and the reader closed it.
    int ptm;

    int pid;

    pthread_mutex_t mutex;

    bool ackRead;

    // Guards `ptm`: writes and resizes may still arrive after it closed.
    pthread_mutex_t io_mutex;

    // The reader and the waiter agree here on the order of the last output
    // and the exit.
    pthread_mutex_t end_mutex;

    pthread_cond_t end_cond;

    // The child was reaped.
    bool exited;

    // The reader handed over everything it will.
    bool drained;

    // The exit was posted: nobody is listening any more.
    bool reported;

    Dart_Port stdout_port;

    Dart_Port exit_port;

} PtyHandle;

char *error_message = NULL;

static void *read_loop(void *arg)
{
    PtyHandle *handle = (PtyHandle *)arg;

    char buffer[4096];

    struct pollfd watched;
    watched.fd = handle->ptm;
    watched.events = POLLIN;

    while (1)
    {
        watched.revents = 0;
        int ready = poll(&watched, 1, PTY_READ_POLL_MS);

        if (ready < 0 && errno != EINTR)
        {
            break;
        }

        // A descendant that kept the terminal open would hold the reader, and
        // the master, for as long as it lives. The session ends with the
        // child: once it is gone and the terminal is quiet, or its exit was
        // reported, reading stops.
        pthread_mutex_lock(&handle->end_mutex);
        bool reported = handle->reported;
        bool exited = handle->exited;
        pthread_mutex_unlock(&handle->end_mutex);

        if (reported)
        {
            break;
        }

        if (ready == 0 && exited)
        {
            // One more look: the child may have written and gone since the
            // last one.
            watched.revents = 0;
            ready = poll(&watched, 1, 0);

            if (ready <= 0)
            {
                break;
            }
        }

        if (ready <= 0)
        {
            continue;
        }

        if (handle->ackRead)
        {
            // if we are in ack mode then we get a mutex here that is
            // freed again once the chunk of data has been processed
            pthread_mutex_lock(&handle->mutex);
        }

        ssize_t n = read(handle->ptm, buffer, sizeof(buffer));

        if (n <= 0)
        {
            if (handle->ackRead)
            {
                pthread_mutex_unlock(&handle->mutex);
            }

            if (n < 0 && (errno == EINTR || errno == EAGAIN))
            {
                continue;
            }

            // Every writer is gone: end of file on macOS, EIO on Linux.
            break;
        }

        Dart_CObject result;
        result.type = Dart_CObject_kTypedData;
        result.value.as_typed_data.type = Dart_TypedData_kUint8;
        result.value.as_typed_data.length = n;
        result.value.as_typed_data.values = (uint8_t *)buffer;

        Dart_PostCObject_DL(handle->stdout_port, &result);
    }

    pthread_mutex_lock(&handle->end_mutex);
    handle->drained = true;
    pthread_cond_broadcast(&handle->end_cond);
    pthread_mutex_unlock(&handle->end_mutex);

    pthread_mutex_lock(&handle->io_mutex);
    close(handle->ptm);
    handle->ptm = -1;
    pthread_mutex_unlock(&handle->io_mutex);

    return NULL;
}

static void start_detached(void *(*entry)(void *), PtyHandle *handle)
{
    pthread_t thread;

    if (pthread_create(&thread, NULL, entry, handle) == 0)
    {
        pthread_detach(thread);
    }
}

static void *wait_exit_thread(void *arg)
{
    PtyHandle *handle = (PtyHandle *)arg;

    int status = 0;
    pid_t reaped;

    do
    {
        reaped = waitpid(handle->pid, &status, 0);
    } while (reaped < 0 && errno == EINTR);

    // What the child wrote last is still on its way through the reader. It
    // goes out before the exit, so nobody learns that the process ended before
    // they can read why.
    struct timespec deadline;
    clock_gettime(CLOCK_REALTIME, &deadline);
    deadline.tv_nsec += (PTY_EXIT_DRAIN_MS % 1000) * 1000000L;
    deadline.tv_sec += PTY_EXIT_DRAIN_MS / 1000 + deadline.tv_nsec / 1000000000L;
    deadline.tv_nsec %= 1000000000L;

    pthread_mutex_lock(&handle->end_mutex);
    handle->exited = true;
    while (!handle->drained)
    {
        if (pthread_cond_timedwait(&handle->end_cond, &handle->end_mutex, &deadline) != 0)
        {
            break;
        }
    }
    handle->reported = true;
    pthread_mutex_unlock(&handle->end_mutex);

    if (reaped < 0)
    {
        // Someone else reaped it: there is no status to report, and saying
        // nothing would leave the session waiting for ever.
        Dart_PostInteger_DL(handle->exit_port, -1);
    }
    else if (WIFSIGNALED(status))
    {
        Dart_PostInteger_DL(handle->exit_port, -WTERMSIG(status));
    }
    else
    {
        Dart_PostInteger_DL(handle->exit_port, WEXITSTATUS(status));
    }

    return NULL;
}

static void set_environment(char **environment)
{
    if (environment == NULL)
    {
        return;
    }

    while (*environment != NULL)
    {
        putenv(*environment);
        environment++;
    }
}

FFI_PLUGIN_EXPORT PtyHandle *pty_create(PtyOptions *options)
{
    struct winsize ws;

    ws.ws_row = options->rows;
    ws.ws_col = options->cols;
    ws.ws_xpixel = 0;
    ws.ws_ypixel = 0;

    int ptm;

    int pid = pty_forkpty(&ptm, NULL, NULL, &ws);

    if (pid < 0)
    {
        error_message = "pty_forkpty failed";
        perror("pty_forkpty");
        return NULL;
    }

    if (pid == 0)
    {
        // This is a copy of the host until it execs. Whatever fails here ends
        // the copy: returning would run the host's own code a second time.
        set_environment(options->environment);

        if (options->working_directory != NULL && strlen(options->working_directory) > 0)
        {
            if (chdir(options->working_directory) != 0)
            {
                perror(options->working_directory);
                _exit(126);
            }
        }

        execvp(options->executable, options->arguments);

        perror(options->executable);
        _exit(127);
    }

    PtyHandle *handle = (PtyHandle *)malloc(sizeof(PtyHandle));

    handle->ptm = ptm;
    handle->pid = pid;
    pthread_mutex_init(&handle->mutex, NULL);
    handle->ackRead = options->ackRead;
    pthread_mutex_init(&handle->io_mutex, NULL);
    pthread_mutex_init(&handle->end_mutex, NULL);
    pthread_cond_init(&handle->end_cond, NULL);
    handle->exited = false;
    handle->drained = false;
    handle->reported = false;
    handle->stdout_port = options->stdout_port;
    handle->exit_port = options->exit_port;

    start_detached(&read_loop, handle);

    start_detached(&wait_exit_thread, handle);

    return handle;
}

FFI_PLUGIN_EXPORT void pty_write(PtyHandle *handle, char *buffer, int length)
{
    pthread_mutex_lock(&handle->io_mutex);

    // A terminal takes input in pieces when its buffer is full.
    while (handle->ptm >= 0 && length > 0)
    {
        ssize_t written = write(handle->ptm, buffer, length);

        if (written < 0)
        {
            if (errno == EINTR)
            {
                continue;
            }
            break;
        }

        buffer += written;
        length -= written;
    }

    pthread_mutex_unlock(&handle->io_mutex);
}

FFI_PLUGIN_EXPORT void pty_ack_read(PtyHandle *handle)
{
    if (handle->ackRead)
    {
        // frees the mutex so that the next chunk of data can be read
        pthread_mutex_unlock(&handle->mutex);
    }
}

FFI_PLUGIN_EXPORT int pty_resize(PtyHandle *handle, int rows, int cols)
{
    struct winsize ws;

    ws.ws_row = rows;
    ws.ws_col = cols;
    ws.ws_xpixel = 0;
    ws.ws_ypixel = 0;

    pthread_mutex_lock(&handle->io_mutex);
    int result = handle->ptm < 0 ? -1 : ioctl(handle->ptm, TIOCSWINSZ, &ws);
    pthread_mutex_unlock(&handle->io_mutex);

    return result;
}

FFI_PLUGIN_EXPORT int pty_getpid(PtyHandle *handle)
{
    return handle->pid;
}

FFI_PLUGIN_EXPORT char *pty_error(void)
{
    return NULL;
}
