using Gee;
using SampleRpc;
using TaskletSystem;

namespace Tester
{
    // Node alpha: pid=1234, I=eth0
    const string DG_LISTEN_PATHNAME = "recv_1234_eth0";
    const string DG_PSEUDOMAC = "fe:aa:aa:aa:aa:aa";
    const string DG_SEND_PATHNAME = "send_1234_eth0";
    const string ST_LISTEN_PATHNAME = "conn_169.254.0.2";

    SrcNic beta_src_nic;
    SrcNic gamma_src_nic;

    void do_peculiar() {
        // do something
        tasklet.ms_wait(100);
    }
}