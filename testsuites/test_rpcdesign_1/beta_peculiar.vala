using Gee;
using SampleRpc;
using TaskletSystem;

namespace Tester
{
    // Node beta: pid=567, I=eth0
    const string DG_LISTEN_PATHNAME = "recv_567_eth0";
    const string DG_PSEUDOMAC = "fe:bb:bb:bb:bb:bb";
    const string DG_SEND_PATHNAME = "send_567_eth0";
    const string ST_LISTEN_PATHNAME = "conn_169.254.0.1";

    SrcNic alpha_src_nic;
    SrcNic gamma_src_nic;

    void do_peculiar() {
        // do something
        tasklet.ms_wait(100);
    }
}