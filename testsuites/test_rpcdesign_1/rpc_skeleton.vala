using Gee;
using SampleRpc;
using TaskletSystem;

namespace Tester
{
    HashMap<string,IListenerHandle> handles_by_listen_pathname;

    void start_stream_system_listen(SampleRpc.IDelegate dlg, SampleRpc.IErrorHandler err, string listen_pathname)
    {
        if (handles_by_listen_pathname == null) handles_by_listen_pathname = new HashMap<string,IListenerHandle>();
        handles_by_listen_pathname[listen_pathname] = stream_system_listen(dlg, err, listen_pathname);
    }
    void stop_stream_system_listen(string listen_pathname)
    {
        assert(handles_by_listen_pathname != null);
        assert(handles_by_listen_pathname.has_key(listen_pathname));
        IListenerHandle lh = handles_by_listen_pathname[listen_pathname];
        lh.kill();
        handles_by_listen_pathname.unset(listen_pathname);
    }

    void start_datagram_system_listen(SampleRpc.IDelegate dlg, SampleRpc.IErrorHandler err, string listen_pathname, string send_pathname, SrcNic src_nic)
    {
        if (handles_by_listen_pathname == null) handles_by_listen_pathname = new HashMap<string,IListenerHandle>();
        handles_by_listen_pathname[listen_pathname] = datagram_system_listen(dlg, err, listen_pathname, send_pathname, src_nic);
    }
    void stop_datagram_system_listen(string listen_pathname)
    {
        assert(handles_by_listen_pathname != null);
        assert(handles_by_listen_pathname.has_key(listen_pathname));
        IListenerHandle lh = handles_by_listen_pathname[listen_pathname];
        lh.kill();
        handles_by_listen_pathname.unset(listen_pathname);
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

    TesterSkeleton skeleton;
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
            assert(unicast_id is UnicastID);
            UnicastID _unicast_id = (UnicastID)unicast_id;
            assert(_unicast_id.id == PID);
            return skeleton;
        }

        private Gee.List<ITesterSkeleton> get_dispatcher_set(IBroadcastID broadcast_id)
        {
            // Might have many identities in this node
            if (broadcast_id is EverybodyBroadcastID)
            {
                return new ArrayList<ITesterSkeleton>.wrap({skeleton});
            }
            else
            {
                error("not implemented yet");
            }
        }
    }

    class CommSkeleton : Object, ICommSkeleton
    {
        public void greet(string name, string ip, CallerInfo? caller = null)
        {
            assert(caller != null);
            got_greet(name, ip, caller);
        }

        public void message(string msg, CallerInfo? caller = null)
        {
            assert(caller != null);
            got_msg(msg, caller);
        }
    }

    class TesterSkeleton : Object, ITesterSkeleton
    {
        public TesterSkeleton()
        {
            comm = new CommSkeleton();
        }

        public unowned IAnotherSkeleton another_getter()
        {
            error("not implemented yet");
        }

        CommSkeleton comm;
        public unowned ICommSkeleton comm_getter()
        {
            return comm;
        }

        public unowned IModuleSkeleton module_getter()
        {
            error("not implemented yet");
        }
    }
}