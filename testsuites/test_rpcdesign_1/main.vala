using Gee;
using SampleRpc;
using TaskletSystem;

namespace Tester
{
    void main()
    {
        // Initialize tasklet system
        PthTaskletImplementer.init();
        ITasklet tasklet = PthTaskletImplementer.get_tasklet_system();
        // Pass tasklet system to the SampleRpc library
        init_tasklet_system(tasklet);

        // check LISTEN_PATHNAME does not exist
        if (FileUtils.test(LISTEN_PATHNAME, FileTest.EXISTS)) error(@"pathname $(LISTEN_PATHNAME) exists.");
        // IDs for my own messages:
        mymsgs = new ArrayList<int>();
        for (int i = 1; i < 10; i++) mymsgs.add(PID*1000+i);
        mynextmsgindex = 0;

        // start tasklet for LISTEN_PATHNAME
        datagram_dlg = new ServerDatagramDelegate();
        IErrorHandler error_handler = new ServerErrorHandler(@"for datagram_system_listen $(LISTEN_PATHNAME) $(SEND_PATHNAME) $(PSEUDOMAC)");
        my_src_nic = @"{\"mac\":\"$(PSEUDOMAC)\"}";
        listen_s = datagram_system_listen(LISTEN_PATHNAME, SEND_PATHNAME, my_src_nic, datagram_dlg, error_handler);
        if (verbose) print("I am listening.\n");
        events = "";

        // start tasklet for timeout error
        tasklet.spawn(new TimeoutTasklet());

        // Behaviour peculiar node.
        do_peculiar();

        tasklet.ms_wait(50);
        listen_s.kill();
        if (verbose) print("I ain't listening anymore.\n");

        // Behaviour peculiar node.
        if (verbose) print(@"events:\n$(events)---------------\n");
        do_peculiar_check();

        return 0;
    }
}