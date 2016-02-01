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

void main(string[] args)
{
    if (args[1] == "1") test_client_call_tcp();
    if (args[1] == "2") test_server_receive_tcp();
}

IChannel ch_metronome_test_client_call_tcp;
IChannel ch_server_accepts_connection;
IChannel ch_client_waits_reply;
IChannel ch_server_sends_reply_len;
int state_of_test_client_call_tcp;
void metronome_test_client_call_tcp()
{
    state_of_test_client_call_tcp = 0;
    ch_metronome_test_client_call_tcp.recv();
    real_tasklet.ms_wait(10);
    ch_server_accepts_connection.send(0);
    ch_client_waits_reply.recv();
    ch_server_sends_reply_len.send(200);
}

void test_client_call_tcp()
{
    /* This test acts as a client for a remote call in TCP.
     * 
     */

    PthTaskletImplementer.init();
    real_tasklet = PthTaskletImplementer.get_tasklet_system();
    fake_tasklet = new FakeTaskletSystemImplementer(real_tasklet);
    ch_server_accepts_connection = real_tasklet.get_channel();
    ch_metronome_test_client_call_tcp = real_tasklet.get_channel();
    ch_client_waits_reply = real_tasklet.get_channel();

    real_tasklet.spawn(new SimpleTaskletSpawner(metronome_test_client_call_tcp));
    zcd.init_tasklet_system(fake_tasklet);

    try {
        fake_tasklet.prepare_get_client_stream_socket(
            /* recv func */
            (b, maxlen) => {
                /*uint8* b, size_t maxlen*/
                print(@"going to fake a recv of at most $(maxlen) bytes.\n");
                error("not implemented yet");
                // TODO
                return 0; /*size_t*/
            },
            /* send func */
            (b, len) => {
                /*uint8* b, size_t len*/
                print(@"going to fake a send of $(len) bytes.\n");
                if (len == 4) print(@" first 4 bytes are $(*(b+0)), $(*(b+1)), $(*(b+2)), $(*(b+3)).\n");
                else
                {
                    string s = (string)b;
                    print(@" content: '$(s)'.\n");
                }
                // TODO improve output?
                return;
            },
            /* close func */
            () => {
                print(@"going to fake closing of connection.\n");
                // TODO error on future trials?
                return;
            }
        );
        // Prepare a TcpClient. This does not open a connection yet.
        string ser_my_source_id = "{\"typename\":\"NetsukukuSourceID\",\"value\":{\"id\":123456}}";
        string ser_dest_unicast_id = "{\"typename\":\"NetsukukuUnicastID\",\"value\":{\"id\":749723}}";
        TcpClient tcp = zcd.tcp_client("169.254.0.1", 269, ser_my_source_id, ser_dest_unicast_id);

        // simulate a remote call.
        ch_metronome_test_client_call_tcp.send(0);
        string res = tcp.enqueue_call("a.b", new ArrayList<string>.wrap({"1", "\"ab\""}), true);

        print(@"res = $(res)\n");
        real_tasklet.ms_wait(100);
    }
    catch (ZCDError e)
    {
        error(@"Got a ZdcError: $(e.message)");
    }

    PthTaskletImplementer.kill();
}

IChannel ch_metronome_test_server_receive_tcp;
IChannel ch_server_gets_connection;
IChannel ch_server_gets_message;
int state_of_test_server_receive_tcp;
void metronome_test_server_receive_tcp()
{
    state_of_test_server_receive_tcp = 0;
    ch_server_gets_connection.send("169.254.23.45"); // peer address
    ch_server_gets_connection.send("169.254.0.1"); // my address
    ch_metronome_test_server_receive_tcp.recv();
    // first 4 bytes of message
    // after we'll be on status 1
    state_of_test_server_receive_tcp = 1;
    ch_server_gets_message.send((uint8)0);
    ch_server_gets_message.send((uint8)0);
    ch_server_gets_message.send((uint8)0);
    ch_server_gets_message.send((uint8)196);
    ch_metronome_test_server_receive_tcp.recv();
    string msg = "{\"method-name\":\"a.b\",\"source-id\":{\"typename\":\"NetsukukuSourceID\",\"value\":{\"id\":123456}},\"unicast-id\":{\"typename\":\"NetsukukuUnicastID\",\"value\":{\"id\":749723}},\"wait-reply\":true,\"arguments\":[1,\"ab\"]}";
    ch_server_gets_message.send(msg);
}

void test_server_receive_tcp()
{
    /* This test acts as a server that receives a call in TCP.
     * 
     */

    PthTaskletImplementer.init();
    real_tasklet = PthTaskletImplementer.get_tasklet_system();
    fake_tasklet = new FakeTaskletSystemImplementer(real_tasklet);
    ch_metronome_test_server_receive_tcp = real_tasklet.get_channel();
    ch_server_gets_connection = real_tasklet.get_channel();
    ch_server_gets_message = real_tasklet.get_channel();

    real_tasklet.spawn(new SimpleTaskletSpawner(metronome_test_server_receive_tcp));
    zcd.init_tasklet_system(fake_tasklet);

    var dlg = new MyTcpDelegate();
    var err = new MyTcpAcceptErrorHandler();
    fake_tasklet.prepare_get_server_stream_socket(
        /* accept func */
        () => {
            print(@"going to fake command accept on socket.\n");
            string peer_address = (string)ch_server_gets_connection.recv();
            string my_address = (string)ch_server_gets_connection.recv();
            print(@"going to fake a connection from $(peer_address) to $(my_address).\n");
            FakeConnectedStreamSocket ret = new FakeConnectedStreamSocket(
                /* recv func */
                (b, maxlen) => {
                    /*uint8* b, size_t maxlen*/
                    print(@"going to fake a recv of at most $(maxlen) bytes.\n");
                    if (state_of_test_server_receive_tcp == 0)
                    {
                        ch_metronome_test_server_receive_tcp.send(0);
                        assert(maxlen >= 4);
                        uint8 b0 = (uint8)ch_server_gets_message.recv();
                        uint8 b1 = (uint8)ch_server_gets_message.recv();
                        uint8 b2 = (uint8)ch_server_gets_message.recv();
                        uint8 b3 = (uint8)ch_server_gets_message.recv();
                        *(b+0) = b0;
                        *(b+1) = b1;
                        *(b+2) = b2;
                        *(b+3) = b3;
                        print(@"returning 4 bytes: $(*(b+0)), $(*(b+1)), $(*(b+2)), $(*(b+3)).\n");
                        return 4; /*size_t*/
                    }
                    if (state_of_test_server_receive_tcp == 1)
                    {
                        ch_metronome_test_server_receive_tcp.send(0);
                        string s = (string)ch_server_gets_message.recv();
                        print(@"copying $(s.length) bytes...\n");
                        GLib.Memory.copy(b, s, s.length);
                        print(@"returning size_t = $(s.length) bytes.\n");
                        return s.length; /*size_t*/
                    }
                    error("not implemented yet");
                    // TODO
                    return 0; /*size_t*/
                },
                /* send func */
                (b, len) => {
                    /*uint8* b, size_t len*/
                    print(@"going to fake a send of $(len) bytes.\n");
                    if (len == 4) print(@" first 4 bytes are $(*(b+0)), $(*(b+1)), $(*(b+2)), $(*(b+3)).\n");
                    else
                    {
                        string s = (string)b;
                        print(@" content: '$(s)'.\n");
                    }
                    // TODO improve output?
                    return;
                },
                /* close func */
                () => {
                    print(@"going to fake closing of connection.\n");
                    // TODO error on future trials?
                    return;
                },
                peer_address,
                my_address
            );
            return ret;
        }
    );
    zcd.tcp_listen(dlg, err, 269);

    real_tasklet.ms_wait(100);
    // simulate a remote call.
    //

    real_tasklet.ms_wait(1000);

    PthTaskletImplementer.kill();
}

class MyTcpDelegate : Object, IZcdTcpDelegate
{
    public IZcdTcpRequestHandler get_new_handler()
    {
        return new MyTcpRequestHandler();
    }
}

class MyTcpRequestHandler : Object, IZcdTcpRequestHandler
{
    public void set_unicast_id(string unicast_id)
    {
        error("not implemented yet");
    }

    public void set_method_name(string m_name)
    {
        error("not implemented yet");
    }

    public void add_argument(string arg)
    {
        error("not implemented yet");
    }

    public void set_caller_info(TcpCallerInfo caller_info)
    {
        error("not implemented yet");
    }

    public IZcdDispatcher? get_dispatcher()
    {
        return new MyTcpDispatcher();
    }
}

class MyTcpDispatcher : Object, IZcdDispatcher
{
    public string execute()
    {
        error("not implemented yet");
    }
}

class MyTcpAcceptErrorHandler : Object, IZcdTcpAcceptErrorHandler
{
    public void error_handler(Error e)
    {
        error("error should not happen");
    }
}

