using Gee;
using SampleRpc;
using TaskletSystem;

namespace Tester
{
    // Node gamma: pid=890, I=eth0
    const int PID = 890;
    const string DG_LISTEN_PATHNAME = "recv_890_eth0";
    const string DG_PSEUDOMAC = "fe:cc:cc:cc:cc:cc";
    const string DG_SEND_PATHNAME = "send_890_eth0";
    const string ST_LISTEN_PATHNAME = "conn_169.254.0.3";

    void do_peculiar() {
        // greet soon
        var st = get_tester_datagram_system(DG_SEND_PATHNAME, my_source_id, new EverybodyBroadcastID(), my_src_nic);
        try {
            st.comm.greet("gamma", "169.254.0.3");
        } catch (StubError e) {
            warning(@"StubError while greeting: $(e.message)");
        } catch (DeserializeError e) {
            warning(@"DeserializeError while greeting: $(e.message)");
        }
        tasklet.ms_wait(3500);
    }

    void got_greet(string name, string ip, CallerInfo caller)
    {
        error("not implemented yet");
    }

    void got_message(string msg, CallerInfo caller)
    {
        if (verbose) print(@"Got msg: $(msg)\n");
    }
}