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

using Gee;
using AppDomain;

bool ping;

zcd.IZcdTasklet tasklet;

void main(string[] args)
{
    ping = false;
    OptionContext oc = new OptionContext("client/server <dev> <unicastid-string>");
    OptionEntry[] entries = new OptionEntry[2];
    int index = 0;
    entries[index++] = {"ping", 0, 0, OptionArg.NONE, ref ping, "Client: ping", null};
    entries[index++] = { null };
    oc.add_main_entries(entries, null);
    try {
        oc.parse(ref args);
    }
    catch (OptionError e) {
        print(@"Error parsing options: $(e.message)\n");
        return;
    }

    // Initialize tasklet system
    tasklet = MyTaskletSystem.init();

    // Initialize known serializable classes
    typeof(License).class_peek();
    typeof(UnicastID).class_peek();
    typeof(BroadcastID).class_peek();
    // Pass tasklet system to ModRpc (and ZCD)
    ModRpc.init_tasklet_system(tasklet);

    string mode = args[1];
    if (mode == "server")
    {
        server(args[2], args[3]);
        tasklet.ms_wait(10000);
    }
    else if (mode == "client")
    {
        client(args[2], args[3]);
    }
    MyTaskletSystem.kill();
}

void client(string dev, string name)
{
    print("client\n");
    UnicastID dest = new UnicastID();
    dest.my_id = name;
    BroadcastID broad = new BroadcastID();
    broad.all_but_this = name;
    try {
        if (ping)
        {
            var del = new ServerSampleDelegate("justtolistenreply");
            var err = new ServerSampleErrorHandler();
            ModRpc.udp_listen(del, err, 60296, dev);
            ModRpc.INodeManagerStub n = ModRpc.get_node_unicast(dev, 60296, dest, true);
            int id = Random.int_range(0, int.MAX);
            print("prepare ping...\n");
            assert(n.info.set_year(id));
            tasklet.ms_wait(10);
            int rtt = ModRpc.send_ping(id, dev, 60296);
            print(@"RTT is $(rtt)\n");
        }
        else
        {
            ModRpc.INodeManagerStub n = ModRpc.get_node_unicast(dev, 60296, dest, false);
            ModRpc.INodeManagerStub n2 = ModRpc.get_node_broadcast(dev, 60296, broad);
            print("calling set_name unicast...\n");
            n.info.set_name("ad uno");
            print("calling set_name broadcast...\n");
            n2.info.set_name("agli altri");
        }
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

void server(string dev, string name)
{
    print("server\n");
    var del = new ServerSampleDelegate(name);
    var err = new ServerSampleErrorHandler();
    ModRpc.udp_listen(del, err, 60296, dev);
}

class ServerSampleDelegate : Object, ModRpc.IRpcDelegate
{
    private string name;
    private ServerSampleNodeManager real_node;
    public ServerSampleDelegate(string name)
    {
        this.name = name;
        real_node = new ServerSampleNodeManager();
    }

    public ModRpc.INodeManagerSkeleton? get_node(ModRpc.CallerInfo caller)
    {
        if (caller is ModRpc.TcpCallerInfo)
        {
            error("not implemented yet");
        }
        else if (caller is ModRpc.UnicastCallerInfo)
        {
            ModRpc.UnicastCallerInfo c = (ModRpc.UnicastCallerInfo)caller;
            if (c.unicastid.my_id != name) return null;
            return real_node;
        }
        else if (caller is ModRpc.BroadcastCallerInfo)
        {
            ModRpc.BroadcastCallerInfo c = (ModRpc.BroadcastCallerInfo)caller;
            if (c.broadcastid.all_but_this == name) return null;
            return real_node;
        }
        else
        {
            error(@"Unexpected class $(caller.get_type().name())");
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
        print(@"Got command: $(name).\n");
    }

    public int get_year(ModRpc.CallerInfo? caller=null)
    {
        error("not implemented yet");
    }

    public bool set_year(int year, ModRpc.CallerInfo? caller=null)
    {
        // in fact it is prepare ping
        string dev;
        if (caller is ModRpc.TcpCallerInfo)
        {
            error("not implemented yet");
        }
        else if (caller is ModRpc.UnicastCallerInfo)
        {
            ModRpc.UnicastCallerInfo c = (ModRpc.UnicastCallerInfo)caller;
            dev = c.dev;
        }
        else if (caller is ModRpc.BroadcastCallerInfo)
        {
            error("not in broadcast");
        }
        else
        {
            error(@"Unexpected class $(caller.get_type().name())");
        }
        ModRpc.prepare_ping(year, dev, 60296);
        return true;
    }

    public License get_license(ModRpc.CallerInfo? caller=null)
    {
        error("not implemented yet");
    }
}

