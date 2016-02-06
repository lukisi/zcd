using Gee;
using SampleRpc;
using TaskletSystem;

ITasklet tasklet;

void main(string[] args)
{
    assert(args.length > 3);
    string dev = args[1];
    string ip = args[2];
    ArrayList<string> ids = new ArrayList<string>();
    ids.add(args[3]);
    for (int i = 4; i < args.length; i++) ids.add(args[i]);

    PthTaskletImplementer.init();
    tasklet = PthTaskletImplementer.get_tasklet_system();
    init_tasklet_system(tasklet);
    typeof(MySourceID).class_peek();
    typeof(MyUnicastID).class_peek();
    typeof(MyBroadcastID).class_peek();

    map_operators = new HashMap<string, MyOperatoreSkeleton>();
    foreach (string id in ids) map_operators[id] = new MyOperatoreSkeleton(id);
    var dlg = new MyRpcDelegate();
    var err = new MyRpcErrorHandler();
    tcp_listen(dlg, err, 269, ip);
    udp_listen(dlg, err, 269, dev);

    while (true) tasklet.ms_wait(10000);
}

HashMap<string, MyOperatoreSkeleton> map_operators;

class MyRpcDelegate : Object, IRpcDelegate
{
    public Gee.List<IOperatoreSkeleton> get_op_set(CallerInfo caller)
    {
        Gee.List<IOperatoreSkeleton> ret = new ArrayList<IOperatoreSkeleton>();
        if (caller is TcpclientCallerInfo)
        {
            TcpclientCallerInfo _caller = (TcpclientCallerInfo)caller;
            if (_caller.unicastid is MyUnicastID)
            {
                MyUnicastID unicastid = (MyUnicastID)_caller.unicastid;
                if (map_operators.has_key(unicastid.id)) ret.add(map_operators[unicastid.id]);
            }
        }
        else if (caller is UnicastCallerInfo)
        {
            UnicastCallerInfo _caller = (UnicastCallerInfo)caller;
            if (_caller.unicastid is MyUnicastID)
            {
                MyUnicastID unicastid = (MyUnicastID)_caller.unicastid;
                if (map_operators.has_key(unicastid.id)) ret.add(map_operators[unicastid.id]);
            }
        }
        else if (caller is BroadcastCallerInfo)
        {
            BroadcastCallerInfo _caller = (BroadcastCallerInfo)caller;
            if (_caller.broadcastid is MyBroadcastID)
            {
                MyBroadcastID broadcastid = (MyBroadcastID)_caller.broadcastid;
                foreach (string id in map_operators.keys)
                {
                    if (broadcastid.contains(id)) ret.add(map_operators[id]);
                }
            }
        }
        else
        {
            error("unknown class caller");
        }
        return ret;
    }
}

class MyRpcErrorHandler : Object, IRpcErrorHandler
{
    public void error_handler(Error e)
    {
        error(e.message);
    }
}

class MyOperatoreSkeleton : Object, IOperatoreSkeleton
{
    public MyOperatoreSkeleton(string id)
    {
        note = new MyNotificatoreSkeleton(id);
        res = new MyRisponditoreSkeleton(id);
    }
    private MyNotificatoreSkeleton note;
    private MyRisponditoreSkeleton res;

    protected unowned INotificatoreSkeleton note_getter()
    {
        return note;
    }

    protected unowned IRisponditoreSkeleton res_getter()
    {
        return res;
    }
}

string get_caller_id(CallerInfo caller)
{
    MySourceID src;
    if (caller is TcpclientCallerInfo)
    {
        TcpclientCallerInfo _caller = (TcpclientCallerInfo)caller;
        if (_caller.sourceid is MySourceID) src = (MySourceID)_caller.sourceid;
        else error("unknown class for sourceid");
    }
    else if (caller is UnicastCallerInfo)
    {
        UnicastCallerInfo _caller = (UnicastCallerInfo)caller;
        if (_caller.sourceid is MySourceID) src = (MySourceID)_caller.sourceid;
        else error("unknown class for sourceid");
    }
    else if (caller is BroadcastCallerInfo)
    {
        BroadcastCallerInfo _caller = (BroadcastCallerInfo)caller;
        if (_caller.sourceid is MySourceID) src = (MySourceID)_caller.sourceid;
        else error("unknown class for sourceid");
    }
    else
    {
        error("unknown class for caller");
    }
    return src.id;
}

class MyNotificatoreSkeleton : Object, INotificatoreSkeleton
{
    public MyNotificatoreSkeleton(string id)
    {
        this.id = id;
    }
    private string id;

    public void scrivi(string msg, CallerInfo? caller = null)
    {
        string caller_id = "null";
        if (caller != null) caller_id = get_caller_id(caller);
        print(@"operatore $(id): messaggio da operatore $(caller_id): $(msg)\n");
    }
}

class MyRisponditoreSkeleton : Object, IRisponditoreSkeleton
{
    public MyRisponditoreSkeleton(string id)
    {
        this.id = id;
    }
    private string id;

    public string salutami(CallerInfo? caller = null)
    {
        tasklet.ms_wait(200);
        string caller_id = "null";
        if (caller != null) caller_id = get_caller_id(caller);
        print(@"operatore $(id): saluto da operatore $(caller_id), contraccambio.\n");
        return @"ciao $(caller_id) da $(id).";
    }
}

