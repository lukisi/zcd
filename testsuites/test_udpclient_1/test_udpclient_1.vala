/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2016 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
 *
 *  Netsukuku is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Netsukuku is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Netsukuku.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;
using TaskletSystem;
using zcd;

delegate void SimpleFuncDelegate();
class SimpleTaskletSpawner : Object, ITaskletSpawnable
{
    public SimpleTaskletSpawner(owned SimpleFuncDelegate x)
    {
        this.x = (owned) x;
    }
    private SimpleFuncDelegate x;
    public void * func()
    {
        x();
        return null;
    }
}

ITasklet real_tasklet;
FakeTaskletSystemImplementer fake_tasklet;

IChannel ch_metronome;
IChannel ch_server_sends_reply;
int status;
const string test_unicast_id = "749723";
const string test_source_id = "123456";
const string method_name = "my_app.do_stuff";
const int request_id = 276582;
void metronome()
{
    status = 0;
    print("metronome: started. now waits for a beat.\n");
    ch_metronome.recv();
    print("metronome: got the beat. In a while we'll send the request. So wait a second beat.\n");
    ch_metronome.recv();
    print("metronome: got the beat. Send the response.\n");
    string msg_response = @"{\"unicast-response\":{\"ID\":$(request_id),\"response\":{\"return-value\":null}}}";
    ch_server_sends_reply.send(msg_response);
    ch_metronome.recv();
    status = 1;
}

void main()
{
    /* This test acts as a client for a remote call in UDP.
     * A program prepares to listen to responses / KEEPALIVE / ACKs on UDP port 269.
     * Then sends a Unicast request on device 'eth0' and UDP port 269, to talk to identity 749723 from identity 123456.
     * Finally it receives the response message, and it correctly informs the delegate.
     */

    PthTaskletImplementer.init();
    real_tasklet = PthTaskletImplementer.get_tasklet_system();
    fake_tasklet = new FakeTaskletSystemImplementer(real_tasklet);
    ch_metronome = real_tasklet.get_channel();
    ch_server_sends_reply = real_tasklet.get_channel();

    ITaskletHandle h_metronome = real_tasklet.spawn(new SimpleTaskletSpawner(metronome), true);
    zcd.init_tasklet_system(fake_tasklet);

    try {
        fake_tasklet.prepare_get_client_datagram_socket(
            /* sendto func */
            (b, len) => {
                /*uint8* b, size_t len*/
                print(@"sendto: going to fake a send of $(len) bytes.\n");
                string s = string.nfill(len, ' ');
                GLib.Memory.copy(s, b, len);
                print(@" content ($(s.length) bytes): '$(s)'.\n");
                assert(method_name in s);
                assert(test_unicast_id in s);
                assert(test_source_id in s);
                print("sendto: send a beat to metronome...\n");
                ch_metronome.send(0);
                return len;
            }
        );
        fake_tasklet.prepare_get_server_datagram_socket(
            /* recvfrom func */
            (b, maxlen, out rmt_ip, out rmt_port) => {
                /*uint8* b, size_t maxlen, out string rmt_ip, out uint16 rmt_port*/
                print(@"recvfrom: going to fake a recv of max $(maxlen) bytes.\n");
                if (status == 0)
                {
                    string s = (string)ch_server_sends_reply.recv();
                    print("recvfrom: metronome provided a response. Going to fake its reception.\n");
                    ch_metronome.send(0);
                    assert(maxlen >= s.length);
                    print(@"recvfrom: copying $(s.length) bytes...\n");
                    GLib.Memory.copy(b, s, s.length);
                    print(@"recvfrom: returning size_t = $(s.length) bytes.\n");
                    rmt_ip = "169.254.0.1";
                    rmt_port = 12345;
                    return s.length; /*size_t*/
                }
                if (status == 1)
                {
                    string s = (string)ch_server_sends_reply.recv();
                    print("recvfrom: Got another response.\n");
                    error(@"not to be reached $(s)");
                }
                error("not implemented yet");
            }
        );
        var dlg_req = new MyUdpRequestMessageDelegate();
        var dlg_ser = new MyUdpServiceMessageDelegate();
        var err = new MyUdpCreateErrorHandler();
        zcd.udp_listen(dlg_req, dlg_ser, err, 269, "eth0");

        // Prepare stuff.
        string ser_my_source_id = @"{\"typename\":\"NetsukukuSourceID\",\"value\":{\"id\":$(test_source_id)}}";
        string ser_dest_unicast_id = @"{\"typename\":\"NetsukukuUnicastID\",\"value\":{\"id\":$(test_unicast_id)}}";

        // simulate a remote call.
        real_tasklet.ms_wait(10);
        print("main: first beat to metronome...\n");
        ch_metronome.send(0);
        print("main: first beat to metronome has been sent.\n");
        zcd.send_unicast_request("eth0", 269, request_id,
                                ser_dest_unicast_id,
                                method_name, new ArrayList<string>.wrap({"{\"argument\":1}", "{\"argument\":\"ab\"}"}),
                                ser_my_source_id,
                                true);

        // wait metronome for complete.
        h_metronome.join();
    }
    catch (ZCDError e)
    {
        error(@"Got a ZdcError: $(e.message)");
    }

    PthTaskletImplementer.kill();
}

class MyDispatcher : Object, IZcdDispatcher
{
    public string execute()
    {
        error("not implemented yet");
    }
}

class MyUdpRequestMessageDelegate : Object, IZcdUdpRequestMessageDelegate
{
    public IZcdDispatcher? get_dispatcher_unicast(
        int id, string unicast_id,
        string m_name, Gee.List<string> arguments,
        UdpCallerInfo caller_info)
    {
        error("not implemented yet");
    }

    public IZcdDispatcher? get_dispatcher_broadcast(
        int id, string broadcast_id,
        string m_name, Gee.List<string> arguments,
        UdpCallerInfo caller_info)
    {
        error("not implemented yet");
    }

}

class MyUdpServiceMessageDelegate : Object, IZcdUdpServiceMessageDelegate
{
    public bool is_my_own_message(int id)
    {
        error("in this scenario the client should not get there");
    }

    public void got_keep_alive(int id)
    {
        error("in this scenario the client should not get there");
    }

    public void got_response(int id, string response)
    {
        print(@"UdpServiceMessage: response to $(id): '$(response)'\n");
        assert("null" in response);
        ch_metronome.send_async(0);
    }

    public void got_ack(int id, string mac)
    {
        error("in this scenario the client should not get there");
    }

}

class MyUdpCreateErrorHandler : Object, IZcdUdpCreateErrorHandler
{
    public void error_handler(Error e)
    {
        error("error should not happen");
    }
}

