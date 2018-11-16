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