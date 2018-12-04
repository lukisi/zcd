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
        var st = get_tester_datagram_system(DG_SEND_PATHNAME, my_source_id, new EverybodyBroadcastID(), my_src_nic);
        try {
            st.comm.greet("alpha", "169.254.0.2");
        } catch (StubError e) {
            warning(@"StubError while greeting: $(e.message)");
        } catch (DeserializeError e) {
            warning(@"DeserializeError while greeting: $(e.message)");
        }
        tasklet.ms_wait(3900);
        // See ack_timeout_msec=3000 in common_skeleton.vala of libtesterrpc
    }

    void got_greet(string name, string ip, CallerInfo caller)
    {
        if (name == "beta")
        {
            assert (caller is StreamCallerInfo);
            StreamCallerInfo _caller = (StreamCallerInfo)caller;
            assert(_caller.src_nic is SrcNic);
            beta_src_nic = (SrcNic)_caller.src_nic;
            assert(_caller.source_id is SourceID);
            SourceID beta_source_id = (SourceID)_caller.source_id;
            if (verbose) print(@"beta ($(beta_source_id.id)) has IP $(ip)\n");
        }
        else if (name == "gamma")
        {
            assert (caller is DatagramCallerInfo);
            DatagramCallerInfo _caller = (DatagramCallerInfo)caller;
            assert(_caller.src_nic is SrcNic);
            gamma_src_nic = (SrcNic)_caller.src_nic;
            assert(_caller.source_id is SourceID);
            SourceID gamma_source_id = (SourceID)_caller.source_id;
            if (verbose) print(@"gamma ($(gamma_source_id.id)) has IP $(ip)\n");
            // wait a bit, then send msg
            tasklet.ms_wait(200);
            var st = get_tester_datagram_system(DG_SEND_PATHNAME, my_source_id, new EverybodyBroadcastID(), my_src_nic, new AckCommunicator());
            try {
                st.comm.message("pippo");
            } catch (StubError e) {
                warning(@"StubError while greeting: $(e.message)");
            } catch (DeserializeError e) {
                warning(@"DeserializeError while greeting: $(e.message)");
            }
        }
        else error("not implemented yet");
    }

    void got_message(string msg, CallerInfo caller)
    {
        if (verbose) print(@"Got msg: $(msg)\n");
    }

    class AckCommunicator : Object, IAckCommunicator
    {
        public void process_src_nics_list(Gee.List<ISrcNic> src_nics_list)
        {
            if (verbose) print("Got ACK list.\n");
            bool beta_check = false;
            bool gamma_check = false;
            foreach (ISrcNic _src_nic in src_nics_list)
            {
                assert(_src_nic is SrcNic);
                SrcNic src_nic = (SrcNic)_src_nic;
                if (src_nic.mac == gamma_src_nic.mac)
                {
                    gamma_check = true;
                    if (verbose) print("Got ACK from gamma.\n");
                }
                else if (src_nic.mac == beta_src_nic.mac)
                {
                    beta_check = true;
                    if (verbose) print("Got ACK from beta.\n");
                }
                else error("Unknown mac $(src_nic.mac)");
            }
            assert(beta_check && gamma_check);
        }
    }
}