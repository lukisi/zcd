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

internal class FakeTaskletSystemImplementer : Object, ITasklet
{
    private ITasklet real_tasklet;
    public FakeTaskletSystemImplementer(ITasklet real_tasklet)
    {
        this.real_tasklet = real_tasklet;
    }

    private ServerStreamSocketAccept accept_func;
    public void prepare_get_server_stream_socket(owned ServerStreamSocketAccept accept_func)
    {
        this.accept_func = (owned) accept_func;
    }

    private ConnectedStreamSocketRecv client_recv_func;
    private ConnectedStreamSocketSend client_send_func;
    private ConnectedStreamSocketClose client_close_func;
    public void prepare_get_client_stream_socket
    (owned ConnectedStreamSocketRecv client_recv_func,
     owned ConnectedStreamSocketSend client_send_func,
     owned ConnectedStreamSocketClose client_close_func)
    {
        this.client_recv_func = (owned) client_recv_func;
        this.client_send_func = (owned) client_send_func;
        this.client_close_func = (owned) client_close_func;
    }

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
        print(@"going to fake creation of socket for listening on port $(port).\n");
        assert(accept_func != null);
        FakeServerStreamSocket ret = new FakeServerStreamSocket((owned) accept_func);
        accept_func = null;
        return ret;
    }

    public IConnectedStreamSocket get_client_stream_socket(string dest_addr, uint16 dest_port, string? my_addr=null) throws Error
    {
        print(@"going to fake creation of socket for connecting to $(dest_addr) on port $(dest_port).\n");
        string client_my_addr = "ANY";
        if (my_addr != null) client_my_addr = my_addr;
        print(@"  and my_addr is $(client_my_addr).\n");
        assert(client_recv_func != null);
        assert(client_send_func != null);
        assert(client_close_func != null);
        FakeConnectedStreamSocket ret = new FakeConnectedStreamSocket
                                        ((owned) client_recv_func,
                                         (owned) client_send_func,
                                         (owned) client_close_func,
                                         dest_addr, client_my_addr);
        client_recv_func = null;
        client_send_func = null;
        client_close_func = null;
        return ret;
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
}

internal delegate FakeConnectedStreamSocket ServerStreamSocketAccept();
internal class FakeServerStreamSocket : Object, IServerStreamSocket
{
    private ServerStreamSocketAccept accept_func;
    public FakeServerStreamSocket(owned ServerStreamSocketAccept accept_func)
    {
        this.accept_func = (owned) accept_func;
    }

    public IConnectedStreamSocket accept() throws Error
    {
        return accept_func();
    }

    public void close() throws Error
    {
        error("not implemented yet");
    }
}

internal delegate size_t ConnectedStreamSocketRecv(uint8* b, size_t maxlen);
internal delegate void ConnectedStreamSocketSend(uint8* b, size_t len);
internal delegate void ConnectedStreamSocketClose();
internal class FakeConnectedStreamSocket : Object, IConnectedStreamSocket
{
    private ConnectedStreamSocketRecv recv_func;
    private ConnectedStreamSocketSend send_func;
    private ConnectedStreamSocketClose close_func;
    private string peer_address;
    private string my_address;
    public FakeConnectedStreamSocket
    (owned ConnectedStreamSocketRecv recv_func,
     owned ConnectedStreamSocketSend send_func,
     owned ConnectedStreamSocketClose close_func,
     string peer_address,
     string my_address)
    {
        this.recv_func = (owned) recv_func;
        this.send_func = (owned) send_func;
        this.close_func = (owned) close_func;
        this.peer_address = peer_address;
        this.my_address = my_address;
    }

    public unowned string _peer_address_getter() {return peer_address;}
    public unowned string _my_address_getter() {return my_address;}

    public size_t recv(uint8* b, size_t maxlen) throws Error
    {
        return recv_func(b, maxlen);
    }

    public void send(uint8* b, size_t len) throws Error
    {
        send_func(b, len);
    }

    public void close() throws Error
    {
        close_func();
    }
}

