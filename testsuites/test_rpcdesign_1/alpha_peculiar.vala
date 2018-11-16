using Gee;
using SampleRpc;
using TaskletSystem;

namespace Tester
{
    // Node alpha: pid=1234, I=eth0
    const int PID = 1234;
    const string DG_LISTEN_PATHNAME = "recv_1234_eth0";
    const string DG_PSEUDOMAC = "fe:aa:aa:aa:aa:aa";
    const string DG_SEND_PATHNAME = "send_1234_eth0";
    const string ST_LISTEN_PATHNAME = "conn_169.254.0.2";

    SrcNic beta_src_nic;
    SrcNic gamma_src_nic;

    void do_peculiar() {
        // greet soon
        int packet_id = mymsgs[mynextmsgindex++];
        var st = get_tester_datagram_system(DG_SEND_PATHNAME, packet_id, my_source_id, new EverybodyBroadcastID(), my_src_nic);
        try {
            st.comm.greet("alpha", "169.254.0.2");
        } catch (StubError e) {
            warning(@"StubError while greeting: $(e.message)");
        } catch (DeserializeError e) {
            warning(@"DeserializeError while greeting: $(e.message)");
        }
        // do something
        tasklet.ms_wait(1000);
    }

    void got_greet(string name, string ip, CallerInfo caller)
    {
        error("not implemented yet");
    }

    void got_msg(string msg, CallerInfo caller)
    {
        error("not implemented yet");
    }
}