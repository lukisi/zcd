/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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

using Tasklets;
using Gee;
using AppDomain;

void main(string[] args)
{
    assert(Tasklet.init());
    string prgname = args[0];
    if (prgname.has_suffix("server"))
    {
        server();
        ms_wait(10000);
    }
    else if (prgname.has_suffix("client"))
    {
        client(args[1], 60296, args[2]);
    }
    else if (prgname.has_suffix("both"))
    {}
    assert(Tasklet.kill());
}

void client(string peer_ip, uint16 peer_port, string name)
{
    ModRpc.INodeManagerStub n = ModRpc.get_node_tcp_client(peer_ip, peer_port);
    try {
        if (n is ModRpc.ITcpClientRootStub)
        {
            unowned ModRpc.ITcpClientRootStub n_tcp = (ModRpc.ITcpClientRootStub)n;
            print(@"hurry = $(n_tcp.hurry)\n");
            print(@"wait_reply = $(n_tcp.wait_reply)\n");
        }
        n.info.set_name(name);
        print("ok\n");
    } catch (AuthError e) {
        print(@"AuthError GENERIC $(e.message)\n");
    } catch (BadArgsError e) {
        if (e is BadArgsError.GENERIC)
            print(@"BadArgsError GENERIC $(e.message)\n");
        else
            print(@"BadArgsError NULL_NOT_ALLOWED $(e.message)\n");
    } catch (ModRpc.StubError e) {
        print(@"ModRpc.StubError GENERIC $(e.message)\n");
    } catch (ModRpc.DeserializeError e) {
        print(@"ModRpc.DeserializeError GENERIC $(e.message)\n");
    }
}

void server()
{
    var del = new ServerSampleDelegate();
    var err = new ServerSampleErrorHandler();
    ModRpc.tcp_listen(del, err, 60296);
}

class ServerSampleDelegate : Object, ModRpc.IRpcDelegate
{
    private ServerSampleNodeManager real_node;
    public ServerSampleDelegate()
    {
        real_node = new ServerSampleNodeManager();
    }

    public ModRpc.INodeManagerSkeleton? get_node(ModRpc.CallerInfo caller)
    {
        if (caller is ModRpc.TcpCallerInfo)
        {
            ModRpc.TcpCallerInfo c = (ModRpc.TcpCallerInfo)caller;
            print(@"request for 'node' from $(c.peer_address) to $(c.my_address)\n");
            return real_node;
        }
        else
        {
            error("not implemented yet");
        }
    }

    public ModRpc.IStatisticsSkeleton? get_stats(ModRpc.CallerInfo caller)
    {
        error("not implemented yet");
    }
}

class ServerSampleErrorHandler : Object, ModRpc.IRpcErrorHandler
{
    public void error_handler(Error e)
    {
        error("not implemented yet");
    }
}

class ServerSampleNodeManager : Object, ModRpc.INodeManagerSkeleton
{
    private ServerSampleInfoManager real_info;
    public ServerSampleNodeManager()
    {
        real_info = new ServerSampleInfoManager();
    }

    protected unowned ModRpc.IInfoManagerSkeleton info_getter()
    {
        return real_info;
    }

    protected unowned ModRpc.ICalculatorSkeleton calc_getter()
    {
        error("not implemented yet");
    }
}

class ServerSampleInfoManager : Object, ModRpc.IInfoManagerSkeleton
{
    public string get_name(ModRpc.CallerInfo? caller=null)
    {
        error("not implemented yet");
    }

    public void set_name(string name, ModRpc.CallerInfo? caller=null) throws AuthError, BadArgsError
    {
        // TODO
    }

    public int get_year(ModRpc.CallerInfo? caller=null)
    {
        error("not implemented yet");
    }

    public bool set_year(int year, ModRpc.CallerInfo? caller=null)
    {
        error("not implemented yet");
    }

    public License get_license(ModRpc.CallerInfo? caller=null)
    {
        error("not implemented yet");
    }

}

