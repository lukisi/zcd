using Gee;
using SampleRpc;
using TaskletSystem;

const bool verbose = true;
// Node alpha: pid=1234, I=eth0
const string DG_LISTEN_PATHNAME = "recv_1234_eth0";
const string DG_PSEUDOMAC = "fe:aa:aa:aa:aa:aa";
const string DG_SEND_PATHNAME = "send_1234_eth0";
const string ST_LISTEN_PATHNAME = "conn_169.254.0.2";

namespace Tester
{
    ITasklet tasklet;
    void main()
    {
        // Initialize tasklet system
        PthTaskletImplementer.init();
        tasklet = PthTaskletImplementer.get_tasklet_system();
        // Pass tasklet system to the SampleRpc library
        init_tasklet_system(tasklet);

        // check DG_LISTEN_PATHNAME does not exist
        if (FileUtils.test(DG_LISTEN_PATHNAME, FileTest.EXISTS)) error(@"pathname $(DG_LISTEN_PATHNAME) exists.");
        // check ST_LISTEN_PATHNAME does not exist
        if (FileUtils.test(ST_LISTEN_PATHNAME, FileTest.EXISTS)) error(@"pathname $(ST_LISTEN_PATHNAME) exists.");

        // Common delegate
        IDelegate dlg = new ServerDelegate();

        // start tasklet for DG_LISTEN_PATHNAME
        IErrorHandler dg_err = new ServerErrorHandler(@"for datagram_system_listen $(DG_LISTEN_PATHNAME) $(DG_SEND_PATHNAME) $(DG_PSEUDOMAC)");
        SrcNic dg_my_src_nic = new SrcNic(DG_PSEUDOMAC);
        start_datagram_system_listen(dlg, dg_err, DG_LISTEN_PATHNAME, DG_SEND_PATHNAME, dg_my_src_nic);
        if (verbose) print(@"I am listening for datagrams on $(DG_LISTEN_PATHNAME).\n");

        // start tasklet for ST_LISTEN_PATHNAME
        IErrorHandler st_err = new ServerErrorHandler(@"for stream_system_listen $(ST_LISTEN_PATHNAME)");
        start_stream_system_listen(dlg, st_err, ST_LISTEN_PATHNAME);
        if (verbose) print(@"I am listening for streams on $(DG_LISTEN_PATHNAME).\n");

        // start tasklet for timeout error
        tasklet.spawn(new TimeoutTasklet());

        tasklet.ms_wait(50);

        stop_datagram_system_listen(DG_LISTEN_PATHNAME);
        stop_stream_system_listen(ST_LISTEN_PATHNAME);
        if (verbose) print("I ain't listening anymore.\n");
    }

    class TimeoutTasklet : Object, ITaskletSpawnable
    {
        public void * func()
        {
            tasklet.ms_wait(10000);
            if (verbose) print("Timeout expired\n");
            stop_datagram_system_listen(DG_LISTEN_PATHNAME);
            stop_stream_system_listen(ST_LISTEN_PATHNAME);
            error("Timeout expired");
        }
    }
}