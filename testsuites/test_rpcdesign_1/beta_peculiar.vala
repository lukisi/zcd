using Gee;
using SampleRpc;
using TaskletSystem;

namespace Tester
{
    // Node beta: pid=567, I=eth0
    const int PID = 567;
    const string DG_LISTEN_PATHNAME = "recv_567_eth0";
    const string DG_PSEUDOMAC = "fe:bb:bb:bb:bb:bb";
    const string DG_SEND_PATHNAME = "send_567_eth0";
    const string ST_LISTEN_PATHNAME = "conn_169.254.0.1";

    SrcNic alpha_src_nic;
    SrcNic gamma_src_nic;

/*
	public static SampleRpc.ITesterStub get_tester_datagram_system (string send_pathname, int packet_id, SampleRpc.ISourceID source_id, SampleRpc.IBroadcastID broadcast_id, SampleRpc.ISrcNic src_nic, SampleRpc.IAckCommunicator? notify_ack = null);
	public static SampleRpc.ITesterStub get_tester_stream_system (string send_pathname, SampleRpc.ISourceID source_id, SampleRpc.IUnicastID unicast_id, SampleRpc.ISrcNic src_nic, bool wait_reply);
*/

    void do_peculiar() {
        // greet soon
        int packet_id = mymsgs[mynextmsgindex++];
        var st = get_tester_datagram_system(DG_SEND_PATHNAME, packet_id, my_source_id, new EverybodyBroadcastID(), my_src_nic);
        try {
            st.comm.greet("beta", "169.254.0.1");
        } catch (StubError e) {
            warning(@"StubError while greeting: $(e.message)");
        } catch (DeserializeError e) {
            warning(@"DeserializeError while greeting: $(e.message)");
        }
        // do something
        tasklet.ms_wait(100);
    }
}