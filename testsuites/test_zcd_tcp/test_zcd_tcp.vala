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
IChannel ch_server_gets_connection;

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
    fake_tasklet = new FakeTaskletSystemImplementer();
    ch_server_accepts_connection = real_tasklet.get_channel();
    ch_metronome_test_client_call_tcp = real_tasklet.get_channel();

    real_tasklet.spawn(new SimpleTaskletSpawner(metronome_test_client_call_tcp));
    zcd.init_tasklet_system(fake_tasklet);

    // Prepare a TcpClient. This does not open a connection yet.
    string ser_my_peer_id = "{\"typename\":\"NetsukukuPeerID\",\"value\":{\"id\":123456}}";
    string ser_dest_unicast_id = "{\"typename\":\"NetsukukuUnicastID\",\"value\":{\"id\":749723}}";
    TcpClient tcp = zcd.tcp_client("169.254.0.1", 269, ser_my_peer_id, ser_dest_unicast_id);

    // simulate a remote call.
    ch_metronome_test_client_call_tcp.send(0);
    string res = tcp.enqueue_call("a.b", new ArrayList<string>.wrap({"1", "\"ab\""}), true);

    print(@"res = $(res)\n");
    real_tasklet.ms_wait(100);

    PthTaskletImplementer.kill();
}

void metronome_a()
{
    print("metronome_a started.\n");
}

void test_server_receive_tcp()
{
    /* This test acts as a server that receives a call in TCP.
     * 
     */

    PthTaskletImplementer.init();
    real_tasklet = PthTaskletImplementer.get_tasklet_system();
    fake_tasklet = new FakeTaskletSystemImplementer();
    ch_server_gets_connection = real_tasklet.get_channel();

    real_tasklet.spawn(new SimpleTaskletSpawner(metronome_a));
    zcd.init_tasklet_system(fake_tasklet);

    var dlg = new MyTcpDelegate();
    var err = new MyTcpAcceptErrorHandler();
    zcd.tcp_listen(dlg, err, 269);

    real_tasklet.ms_wait(100);
    ch_server_gets_connection.send(0);

    real_tasklet.ms_wait(100);

    PthTaskletImplementer.kill();
}

class MyTcpDelegate : Object, IZcdTcpDelegate
{
    public IZcdTcpRequestHandler get_new_handler()
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

internal class FakeTaskletSystemImplementer : Object, ITasklet
{
    public void schedule()
    {
        real_tasklet.schedule();
    }

    public void ms_wait(int msec)
    {
        real_tasklet.ms_wait(msec);
    }

    [NoReturn]
    public void exit_tasklet(void * ret)
    {
        real_tasklet.exit_tasklet(ret);
    }

    public ITaskletHandle spawn(ITaskletSpawnable sp, bool joinable=false)
    {
        return real_tasklet.spawn(sp, joinable);
    }

    public TaskletCommandResult exec_command(string cmdline) throws Error
    {
        return real_tasklet.exec_command(cmdline);
    }

    public IServerStreamSocket get_server_stream_socket(uint16 port, string? my_addr=null) throws Error
    {
        return new FakeServerStreamSocket(port, my_addr);
    }

    public IConnectedStreamSocket get_client_stream_socket(string dest_addr, uint16 dest_port, string? my_addr=null) throws Error
    {
        print(@"It's been asked a connection to $(dest_addr):$(dest_port)\n");
        if (my_addr == null) print("  and my_addr is null.\n");
        else print(@"  and my_addr is $(my_addr).\n");
        ch_server_accepts_connection.recv();
        print(@"We fake the connection accepted.\n");
        return new FakeConnectedStreamSocket(dest_addr, dest_port, my_addr);
    }

    public IServerDatagramSocket get_server_datagram_socket(uint16 port, string dev) throws Error
    {
        return real_tasklet.get_server_datagram_socket(port, dev);
    }

    public IClientDatagramSocket get_client_datagram_socket(uint16 port, string dev) throws Error
    {
        return real_tasklet.get_client_datagram_socket(port, dev);
    }

    public IChannel get_channel()
    {
        return real_tasklet.get_channel();
    }

    private class FakeServerStreamSocket : Object, IServerStreamSocket
    {
        public FakeServerStreamSocket(uint16 port, string? my_addr)
        {
            print(@"going to fake creation of socket for listening on port $(port).\n");
        }

        public IConnectedStreamSocket accept() throws Error
        {
            print(@"going to fake command accept on socket.\n");
            ch_server_gets_connection.recv();
            print(@"going to fake a connection.\n");
            error("not implemented yet");
        }

        public void close() throws Error
        {
            error("not implemented yet");
        }
    }

    private class FakeConnectedStreamSocket : Object, IConnectedStreamSocket
    {
        public FakeConnectedStreamSocket(string dest_addr, uint16 dest_port, string? my_addr)
        {
        }

        public unowned string _peer_address_getter() {error("not implemented yet");}
        public unowned string _my_address_getter() {error("not implemented yet");}

        public size_t recv(uint8* b, size_t maxlen) throws Error
        {
            print(@"going to fake a recv of at most $(maxlen) bytes.\n");
            ch_client_waits_reply.send(0);
            error("not implemented yet");
        }

        public void send(uint8* b, size_t len) throws Error
        {
            print(@"going to fake a send of $(len) bytes.\n");
            if (len == 4) print(@" first 4 bytes are $(*(b+0)), $(*(b+1)), $(*(b+2)), $(*(b+3)).\n");
            else
            {
                string s = (string)b;
                print(@" content: '$(s)'.\n");
            }
        }

        public void close() throws Error
        {
            error("not implemented yet");
        }
    }
}

