#define REAL_PATH "/usr/home/clearimageonline/cgi/private/apps/livetalk/aimrelay.pl"
    main(ac, av) 
        int ac;
        char **av;
    {
        execv(REAL_PATH, av);
    }
