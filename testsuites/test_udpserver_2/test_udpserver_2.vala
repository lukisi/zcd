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
IChannel ch_server_gets_request;
IChannel ch_server_sends_reply;
int status;
const string test_broadcast_id = "749723+635244";
const string test_source_id = "123456";
const string method_name = "my_app.do_stuff";
const int request_id = 276582;
void metronome()
{
    status = 0;
    print("metronome: started. now waits for a beat.\n");
    ch_metronome.recv();
    print("metronome: got the beat. Now a request comes in.\n");
    string msg_request = @"{\"broadcast-request\":{\"ID\":$(request_id),\"request\":{\"broadcast-id\":{\"typename\":\"NetsukukuBroadcastID\",\"value\":{\"id-list\":\"$(test_broadcast_id)\"}},\"source-id\":{\"typename\":\"NetsukukuSourceID\",\"value\":{\"id\":$(test_source_id)}},\"send-ack\":true,\"method-name\":\"my_app.do_stuff\",\"arguments\":[{\"argument\":1},{\"argument\":\"ab\"}]}}}";
    ch_server_gets_request.send(msg_request);
    ch_metronome.recv();
    status = 1;
    print("metronome: the message has been received. Just wait a little then the test is completed.\n");
    real_tasklet.ms_wait(100);
}

bool check_dispatcher_returned = false;
bool check_dispatcher_executed = false;

void main()
{
    /* This test acts as a server for a remote call in UDP.
     * A program prepares to listen to requests on UDP port 269. It receives a broadcast request and correctly reacts calling the IZcdUdpRequestMessageDelegate that has been passed. Then, it correctly sends back the ACK.
     */

    PthTaskletImplementer.init();
    real_tasklet = PthTaskletImplementer.get_tasklet_system();
    fake_tasklet = new FakeTaskletSystemImplementer(real_tasklet);
    ch_metronome = real_tasklet.get_channel();
    ch_server_gets_request = real_tasklet.get_channel();
    ch_server_sends_reply = real_tasklet.get_channel();

    ITaskletHandle h_metronome = real_tasklet.spawn(new SimpleTaskletSpawner(metronome), true);
    zcd.init_tasklet_system(fake_tasklet);

    fake_tasklet.prepare_get_client_datagram_socket(
        /* sendto func */
        (b, len) => {
            /*uint8* b, size_t len*/
            print(@"sendto: going to fake a send of $(len) bytes.\n");
            string s = string.nfill(len, ' ');
            GLib.Memory.copy(s, b, len);
            print(@" content ($(s.length) bytes): '$(s)'.\n");
            if ("unicast-response" in s)
            {
                assert("null" in s);
                ch_server_sends_reply.send_async(0);
            }
            return len;
        }
    );
    fake_tasklet.prepare_get_server_datagram_socket(
        /* recvfrom func */
        (b, maxlen, out rmt_ip, out rmt_port) => {
            /*uint8* b, size_t maxlen, out string rmt_ip, out uint16 rmt_port*/
            print(@"going to fake a recv of max $(maxlen) bytes.\n");
            if (status == 0)
            {
                string s = (string)ch_server_gets_request.recv();
                print("recvfrom: Got first request. Send a beat to the metronome to change status.\n");
                ch_metronome.send(0);
                assert(maxlen >= s.length);
                print(@"recvfrom: copying $(s.length) bytes...\n");
                GLib.Memory.copy(b, s, s.length);
                print(@"recvfrom: returning size_t = $(s.length) bytes.\n");
                rmt_ip = "169.254.23.45";
                rmt_port = 12345;
                return s.length; /*size_t*/
            }
            if (status == 1)
            {
                string s = (string)ch_server_gets_request.recv();
                print("recvfrom: Got second message. Send a beat to the metronome to change status.\n");
                ch_metronome.send(0);
                error(@"not to be reached $(s)");
            }
            error("not implemented yet");
        }
    );

    var dlg_req = new MyUdpRequestMessageDelegate();
    var dlg_ser = new MyUdpServiceMessageDelegate();
    var err = new MyUdpCreateErrorHandler();
    // go to listen
    zcd.udp_listen(dlg_req, dlg_ser, err, 269, "eth0");
    real_tasklet.ms_wait(10);

    // start metronome.
    print("main: send first beat to metronome...\n");
    ch_metronome.send(0);

    // wait metronome for complete.
    h_metronome.join();

    PthTaskletImplementer.kill();
}

class MyDispatcher : Object, IZcdDispatcher
{
    public string execute()
    {
        check_dispatcher_executed = true;
        print("Dispatcher.execute: we fake a correctly completed 'void' remote call.\n");
        return "{\"return-value\":null}";
    }
}

class MyUdpRequestMessageDelegate : Object, IZcdUdpRequestMessageDelegate
{
    public IZcdDispatcher? get_dispatcher_unicast(
        int id, string unicast_id,
        string m_name, Gee.List<string> arguments,
        UdpCallerInfo caller_info)
    {
        error("in this scenario the server should not get there");
    }

    public IZcdDispatcher? get_dispatcher_broadcast(
        int id, string broadcast_id,
        string m_name, Gee.List<string> arguments,
        UdpCallerInfo caller_info)
    {
        print(@"get_dispatcher_broadcast($(id)):\n");
        print(@" broadcast_id: '$(broadcast_id)'\n");
        print(@" m_name: '$(m_name)'\n");
        assert(arguments.size == 2);
        print(@" arg0: '$(arguments[0])'\n");
        print(@" arg1: '$(arguments[1])'\n");
        print(@" source_id: '$(caller_info.source_id)'\n");
        assert(test_source_id in caller_info.source_id);
        assert(test_broadcast_id in broadcast_id);
        assert(m_name == method_name);
        check_dispatcher_returned = true;
        return new MyDispatcher();
    }

}

class MyUdpServiceMessageDelegate : Object, IZcdUdpServiceMessageDelegate
{
    public bool is_my_own_message(int id)
    {
        print(@"is_my_own_message($(id)): returns false.\n");
        return false;
    }

    public void got_keep_alive(int id)
    {
        error("in this scenario the server should not get there");
    }

    public void got_response(int id, string response)
    {
        error("in this scenario the server should not get there");
    }

    public void got_ack(int id, string mac)
    {
        error("in this scenario the server should not get there");
    }

}

class MyUdpCreateErrorHandler : Object, IZcdUdpCreateErrorHandler
{
    public void error_handler(Error e)
    {
        error("error should not happen");
    }
}

