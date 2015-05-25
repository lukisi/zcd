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

bool set_hurry;
bool unset_wait_reply;
bool throw_badargs_generic;
bool throw_badargs_null;
bool throw_auth_fail;

void main(string[] args)
{
    set_hurry = false;
    unset_wait_reply = false;
    throw_badargs_generic = false;
    throw_badargs_null = false;
    throw_auth_fail = false;
    OptionContext oc = new OptionContext("client/server server_ip name_to_set");
    OptionEntry[] entries = new OptionEntry[6];
    int index = 0;
    entries[index++] = {"hurry", 0, 0, OptionArg.NONE, ref set_hurry, "Client: calls are urgents", null};
    entries[index++] = {"dontwait", 0, 0, OptionArg.NONE, ref unset_wait_reply, "Client: don't wait for answer", null};
    entries[index++] = {"badargs", 0, 0, OptionArg.NONE, ref throw_badargs_generic, "Server: throw BadArgsError GENERIC", null};
    entries[index++] = {"null", 0, 0, OptionArg.NONE, ref throw_badargs_null, "Server: throw BadArgsError NULL_NOT_ALLOWED", null};
    entries[index++] = {"auth", 0, 0, OptionArg.NONE, ref throw_auth_fail, "Server: throw AuthError GENERIC", null};
    entries[index++] = { null };
    oc.add_main_entries(entries, null);
    try {
        oc.parse(ref args);
    }
    catch (OptionError e) {
        print(@"Error parsing options: $(e.message)\n");
        return;
    }

    assert(Tasklet.init());

    // Initialize known serializable classes
    typeof(License).class_peek();
    typeof(UnicastID).class_peek();
    typeof(BroadcastID).class_peek();
    typeof(Document).class_peek();

    string mode = args[1];
    if (mode == "server")
    {
        server();
        ms_wait(10000);
    }
    else if (mode == "client")
    {
        client(args[2], 60296, args[3]);
    }
    assert(Tasklet.kill());
}

class AppDomain.Document : Object, AppDomain.IDocument
{
}

void client(string peer_ip, uint16 peer_port, string name)
{
    print("client\n");
    ModRpc.INodeManagerStub n = ModRpc.get_node_tcp_client(peer_ip, peer_port);
    if (n is ModRpc.ITcpClientRootStub)
    {
        unowned ModRpc.ITcpClientRootStub n_tcp = (ModRpc.ITcpClientRootStub)n;
        print(@"hurry = $(n_tcp.hurry)\n");
        if (set_hurry)
        {
            n_tcp.hurry = true;
            print(@"   changed: hurry = $(n_tcp.hurry)\n");
        }
        print(@"wait_reply = $(n_tcp.wait_reply)\n");
        if (unset_wait_reply)
        {
            n_tcp.wait_reply = false;
            print(@"   changed: wait_reply = $(n_tcp.wait_reply)\n");
        }
    }
    try {
        print("calling set_name...\n");
        n.info.set_name(name);
        print("ok\n");
        print("calling get_name...\n");
        string _name = n.info.get_name();
        print(@"name is '$(_name)'\n");
        print("calling get_year...\n");
        int _year = n.info.get_year();
        print(@"year is $(_year)\n");
        print("calling set_year(1971)...\n");
        assert(n.info.set_year(1971));
        print("ok\n");
        print("calling get_year...\n");
        _year = n.info.get_year();
        print(@"year is $(_year)\n");
    } catch (AuthError e) {
        print(@"AuthError GENERIC $(e.message)\n");
    } catch (BadArgsError e) {
        if (e is BadArgsError.NULL_NOT_ALLOWED)
            print(@"BadArgsError NULL_NOT_ALLOWED $(e.message)\n");
        else
            print(@"BadArgsError GENERIC $(e.message)\n");
    } catch (ModRpc.StubError e) {
        if (e is ModRpc.StubError.DID_NOT_WAIT_REPLY)
            print(@"ModRpc.StubError DID_NOT_WAIT_REPLY $(e.message)\n");
        else
            print(@"ModRpc.StubError GENERIC $(e.message)\n");
    } catch (ModRpc.DeserializeError e) {
        print(@"ModRpc.DeserializeError GENERIC $(e.message)\n");
    }
}

void server()
{
    print("server\n");
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
    private int year=0;
    private string name="";
    public string get_name(ModRpc.CallerInfo? caller=null)
    {
        return name;
    }

    public void set_name(string name, ModRpc.CallerInfo? caller=null) throws AuthError, BadArgsError
    {
        if (throw_auth_fail) throw new AuthError.GENERIC(@"I won't let you set name to $(name)");
        if (throw_badargs_generic) throw new BadArgsError.GENERIC(@"'$(name)'? Seriously?");
        if (throw_badargs_null) throw new BadArgsError.NULL_NOT_ALLOWED(@"NULL");
        print(@"New value is $(name).\n");
        this.name = name;
    }

    public int get_year(ModRpc.CallerInfo? caller=null)
    {
        return year;
    }

    public bool set_year(int year, ModRpc.CallerInfo? caller=null)
    {
        this.year = year;
        return true;
    }

    public License get_license(ModRpc.CallerInfo? caller=null)
    {
        error("not implemented yet");
    }

}

