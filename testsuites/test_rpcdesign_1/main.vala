using Gee;
using SampleRpc;
using TaskletSystem;

const bool verbose = true;
// Node alpha: pid=1234, I=wlan0
const string LISTEN_PATHNAME = "recv_1234_wlan0";
const string PSEUDOMAC = "fe:aa:aa:aa:aa:aa";
const string SEND_PATHNAME = "send_1234_wlan0";

namespace Tester
{
    ITasklet tasklet;
    void main()
    {
        // Initialize tasklet system
        PthTaskletImplementer.init();
        ITasklet tasklet = PthTaskletImplementer.get_tasklet_system();
        // Pass tasklet system to the SampleRpc library
        init_tasklet_system(tasklet);

        // check LISTEN_PATHNAME does not exist
        if (FileUtils.test(LISTEN_PATHNAME, FileTest.EXISTS)) error(@"pathname $(LISTEN_PATHNAME) exists.");

        // start tasklet for LISTEN_PATHNAME
        IDelegate dlg = new ServerDelegate();
        IErrorHandler err = new ServerErrorHandler(@"for datagram_system_listen $(LISTEN_PATHNAME) $(SEND_PATHNAME) $(PSEUDOMAC)");
        SrcNic my_src_nic = new SrcNic(PSEUDOMAC);
        start_datagram_system_listen(dlg, err, LISTEN_PATHNAME, SEND_PATHNAME, my_src_nic);
        
        if (verbose) print("I am listening.\n");

        // start tasklet for timeout error
        tasklet.spawn(new TimeoutTasklet());

        tasklet.ms_wait(50);
        stop_datagram_system_listen(LISTEN_PATHNAME);
        if (verbose) print("I ain't listening anymore.\n");
    }

    class ServerErrorHandler : Object, IErrorHandler
    {
        private string name;
        public ServerErrorHandler(string name)
        {
            this.name = name;
        }

        public void error_handler(Error e)
        {
            error(@"ServerErrorHandler '$(name)': $(e.message)");
        }
    }

    class ServerDelegate : Object, IDelegate
    {
        public Gee.List<ITesterSkeleton> get_tester_set(CallerInfo caller_info)
        {
            if (caller_info is StreamCallerInfo)
            {
                StreamCallerInfo c = (StreamCallerInfo)caller_info;
                var ret = new ArrayList<ITesterSkeleton>();
                ITesterSkeleton? d = get_dispatcher(c.unicast_id);
                if (d != null) ret.add(d);
                return ret;
            }
            else if (caller_info is DatagramCallerInfo)
            {
                DatagramCallerInfo c = (DatagramCallerInfo)caller_info;
                return get_dispatcher_set(c.broadcast_id);
            }
            else
            {
                error(@"Unexpected class $(caller_info.get_type().name())");
            }
        }

        private ITesterSkeleton? get_dispatcher(IUnicastID unicast_id)
        {
            error("not implemented yet");
        }

        private Gee.List<ITesterSkeleton> get_dispatcher_set(IBroadcastID broadcast_id)
        {
            // Might have many identities in this node
            error("not implemented yet");
        }
    }

    class TimeoutTasklet : Object, ITaskletSpawnable
    {
        public void * func()
        {
            tasklet.ms_wait(10000);
            stop_datagram_system_listen(LISTEN_PATHNAME);
            error("Timeout expired");
        }
    }
}