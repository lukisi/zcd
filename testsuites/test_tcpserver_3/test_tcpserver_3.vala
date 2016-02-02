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
IChannel ch_connection;
IChannel ch_clientmessage;
int status;
const string test_unicast_id = "749723";
const string test_source_id = "123456";
const string method_name = "my_app.do_stuff";
void metronome()
{
    status = 0;
    ch_connection.send("169.254.23.45"); // peer address
    ch_connection.send("169.254.0.1"); // my address
    ch_metronome.recv();
    // first 4 bytes of message
    // after we'll be on status 1
    status = 1;
    string msg = @"{\"method-name\":\"$(method_name)\",\"source-id\":{\"typename\":\"NetsukukuSourceID\",\"value\":{\"id\":$(test_source_id)}},\"unicast-id\":{\"typename\":\"NetsukukuUnicastID\",\"value\":{\"id\":$(test_unicast_id)}},\"wait-reply\":false,\"arguments\":[{\"argument\":1},{\"argument\":\"ab\"}]}";
    ch_clientmessage.send((uint8)0);
    ch_clientmessage.send((uint8)0);
    ch_clientmessage.send((uint8)0);
    ch_clientmessage.send((uint8)msg.length);
    ch_metronome.recv();
    // rest of message
    // after we'll be on status 2
    status = 2;
    ch_clientmessage.send(msg);
    print("test complete.\n");
}

bool check_dispatcher_returned = false;
bool check_dispatcher_executed = false;

void main()
{
    /* This test acts as a server that receives a call in TCP.
     * A server listens to TCP port 269. It receives a request and correctly reacts calling the IZcdTcpDelegate that has been passed. The request specifies to not wait for the reply. Hence the library spawns a tasklet to call the dispatcher, then goes back to receive more requests.
     */

    PthTaskletImplementer.init();
    real_tasklet = PthTaskletImplementer.get_tasklet_system();
    fake_tasklet = new FakeTaskletSystemImplementer(real_tasklet);
    ch_metronome = real_tasklet.get_channel();
    ch_connection = real_tasklet.get_channel();
    ch_clientmessage = real_tasklet.get_channel();

    ITaskletHandle h_metronome = real_tasklet.spawn(new SimpleTaskletSpawner(metronome), true);
    zcd.init_tasklet_system(fake_tasklet);

    var dlg = new MyTcpDelegate();
    var err = new MyTcpAcceptErrorHandler();
    fake_tasklet.prepare_get_server_stream_socket(
        /* accept func */
        () => {
            print(@"going to fake command accept on socket.\n");
            string peer_address = (string)ch_connection.recv();
            string my_address = (string)ch_connection.recv();
            print(@"going to fake a connection from $(peer_address) to $(my_address).\n");
            FakeConnectedStreamSocket ret = new FakeConnectedStreamSocket(
                /* recv func */
                (b, maxlen) => {
                    /*uint8* b, size_t maxlen*/
                    print(@"going to fake a recv of at most $(maxlen) bytes.\n");
                    if (status == 0)
                    {
                        ch_metronome.send(0);
                        assert(maxlen >= 4);
                        uint8 b0 = (uint8)ch_clientmessage.recv();
                        uint8 b1 = (uint8)ch_clientmessage.recv();
                        uint8 b2 = (uint8)ch_clientmessage.recv();
                        uint8 b3 = (uint8)ch_clientmessage.recv();
                        *(b+0) = b0;
                        *(b+1) = b1;
                        *(b+2) = b2;
                        *(b+3) = b3;
                        print(@"returning 4 bytes: $(*(b+0)), $(*(b+1)), $(*(b+2)), $(*(b+3)).\n");
                        return 4; /*size_t*/
                    }
                    if (status == 1)
                    {
                        ch_metronome.send(0);
                        string s = (string)ch_clientmessage.recv();
                        print(@"copying $(s.length) bytes...\n");
                        GLib.Memory.copy(b, s, s.length);
                        print(@"returning size_t = $(s.length) bytes.\n");
                        return s.length; /*size_t*/
                    }
                    if (status == 2)
                    {
                        real_tasklet.ms_wait(1000);
                        assert_not_reached();
                    }
                    error("not implemented yet");
                },
                /* send func */
                (b, len) => {
                    /*uint8* b, size_t len*/
                    print(@"going to fake a send of $(len) bytes.\n");
                    assert_not_reached();
                },
                /* close func */
                () => {
                    print(@"going to fake closing of connection.\n");
                    return;
                },
                peer_address,
                my_address
            );
            return ret;
        }
    );
    zcd.tcp_listen(dlg, err, 269);

    h_metronome.join();
    real_tasklet.ms_wait(10); // just to see that the server waits for more requests.

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
    private string unicast_id;
    public void set_unicast_id(string unicast_id)
    {
        print(@"RequestHandler: unicast_id = '$(unicast_id)'\n");
        this.unicast_id = unicast_id;
    }

    private string m_name;
    public void set_method_name(string m_name)
    {
        print(@"RequestHandler: method_name = '$(m_name)'\n");
        this.m_name = m_name;
    }

    public void add_argument(string arg)
    {
        print(@"RequestHandler: argument = '$(arg)'\n");
    }

    private TcpCallerInfo caller_info;
    public void set_caller_info(TcpCallerInfo caller_info)
    {
        print(@"RequestHandler: caller_info = '$(caller_info.source_id)'\n");
        this.caller_info = caller_info;
    }

    public IZcdDispatcher? get_dispatcher()
    {
        print(@"RequestHandler: get_dispatcher should decide to return either null or a Dispatcher for one or more identities.\n");
        assert(test_source_id in caller_info.source_id);
        assert(test_unicast_id in unicast_id);
        assert(m_name == method_name);
        check_dispatcher_returned = true;
        return new MyTcpDispatcher();
    }
}

class MyTcpDispatcher : Object, IZcdDispatcher
{
    public string execute()
    {
        check_dispatcher_executed = true;
        print("Dispatcher.execute: we fake a long job.\n");
        real_tasklet.ms_wait(1000);
        print("Dispatcher.execute: we should not get there.\n");
        return "{\"return-value\":null}";
    }
}

class MyTcpAcceptErrorHandler : Object, IZcdTcpAcceptErrorHandler
{
    public void error_handler(Error e)
    {
        error("error should not happen");
    }
}

