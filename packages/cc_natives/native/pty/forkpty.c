#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <fcntl.h>
#include <pthread.h>
#include <signal.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>

pid_t pty_forkpty(
    int *master,
    int *slave,
    const struct termios *termp,
    const struct winsize *winp)
{
    int ptm = open("/dev/ptmx", O_RDWR | O_NOCTTY);

    if (ptm < 0)
    {
        return -1;
    }

    fcntl(ptm, F_SETFD, FD_CLOEXEC);

    if (grantpt(ptm) || unlockpt(ptm))
    {
        close(ptm);
        return -1;
    }

    char *devname;

    if ((devname = ptsname(ptm)) == NULL)
    {
        close(ptm);
        return -1;
    }

    int pts = open(devname, O_RDWR | O_NOCTTY);
    if (pts < 0)
    {
        close(ptm);
        return -1;
    }

    if (termp)
    {
        tcsetattr(pts, TCSAFLUSH, termp);
    }

    if (winp)
    {
        ioctl(pts, TIOCSWINSZ, winp);
    }

    // The child is a copy of this process until it execs, handlers included.
    // A signal that reached it in that window ran the host's own handler in
    // the child: the host was told about a signal it never got, and the child
    // lived on. So no signal is delivered across the fork; one sent meanwhile
    // stays pending and lands on the child's default handlers.
    sigset_t all_signals, previous_signals;
    sigfillset(&all_signals);
    pthread_sigmask(SIG_SETMASK, &all_signals, &previous_signals);

    pid_t pid = fork();

    if (pid < 0)
    {
        pthread_sigmask(SIG_SETMASK, &previous_signals, NULL);
        close(pts);
        close(ptm);
        return -1;
    }

    if (pid == 0)
    {
        struct sigaction default_action;
        default_action.sa_handler = SIG_DFL;
        default_action.sa_flags = 0;
        sigemptyset(&default_action.sa_mask);
        for (int signal_number = 1; signal_number < NSIG; signal_number++)
        {
            // SIGKILL and SIGSTOP refuse; nothing to do about that.
            sigaction(signal_number, &default_action, NULL);
        }
        sigset_t no_signals;
        sigemptyset(&no_signals);
        sigprocmask(SIG_SETMASK, &no_signals, NULL);

        setsid();
        if (ioctl(pts, TIOCSCTTY, (char *)NULL) == -1)
            exit(-1);

        dup2(pts, STDIN_FILENO);
        dup2(pts, STDOUT_FILENO);
        dup2(pts, STDERR_FILENO);

        if (pts > 2)
        {
            close(pts);
        }
    }
    else
    {
        pthread_sigmask(SIG_SETMASK, &previous_signals, NULL);
        *master = ptm;
        if (slave)
        {
            *slave = pts;
        }
        else
        {
            // The child holds the terminal's other end. A copy kept here would
            // never close, and the master would never read end of file.
            close(pts);
        }
    }

    return pid;
}
