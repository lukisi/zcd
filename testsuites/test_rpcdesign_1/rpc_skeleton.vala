using Gee;
using SampleRpc;
using TaskletSystem;

namespace Tester
{
/*
	public static void init_tasklet_system (TaskletSystem.ITasklet _tasklet);

	public static SampleRpc.IListenerHandle stream_system_listen (SampleRpc.IDelegate dlg, SampleRpc.IErrorHandler err, string listen_pathname);
	public static SampleRpc.IListenerHandle datagram_system_listen (SampleRpc.IDelegate dlg, SampleRpc.IErrorHandler err, string listen_pathname, string send_pathname, SampleRpc.ISrcNic src_nic);

	public static SampleRpc.ITesterStub get_tester_stream_system (string send_pathname, SampleRpc.ISourceID source_id, SampleRpc.IUnicastID unicast_id, SampleRpc.ISrcNic src_nic, bool wait_reply);
	public static SampleRpc.ITesterStub get_tester_datagram_system (string send_pathname, int packet_id, SampleRpc.ISourceID source_id, SampleRpc.IBroadcastID broadcast_id, SampleRpc.ISrcNic src_nic, SampleRpc.IAckCommunicator? notify_ack = null);
*/

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
}