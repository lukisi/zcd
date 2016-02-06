using Gee;
using SampleRpc;
using TaskletSystem;

void main(string[] args)
{
    assert(args.length == 4);
    string dev = args[1];
    string sourceid = args[2];
    string destid = args[3];

    PthTaskletImplementer.init();
    ITasklet tasklet = PthTaskletImplementer.get_tasklet_system();
    init_tasklet_system(tasklet);
    //typeof(MySourceID).class_peek();
    //typeof(MyUnicastID).class_peek();
    //typeof(MyBroadcastID).class_peek();

    // add udp_listen for receiveing response
    var dlg = new NullRpcDelegate();
    var err = new MyRpcErrorHandler();
    udp_listen(dlg, err, 269, dev);

    MySourceID mysourceid = new MySourceID(sourceid);
    MyUnicastID unicastid = new MyUnicastID(destid);
    try
    {
        IOperatoreStub op = get_op_unicast(dev, 269, mysourceid, unicastid, true);
        string res = op.res.salutami();
        print(@"$(res)\n");
    }
    catch (StubError e)
    {
        print(@"StubError: $(e.message)\n");
    }
    catch (DeserializeError e)
    {
        print(@"DeserializeError: $(e.message)\n");
    }
}

class NullRpcDelegate : Object, IRpcDelegate
{
    public Gee.List<IOperatoreSkeleton> get_op_set(CallerInfo caller)
    {
        error("should not get there");
    }
}

class MyRpcErrorHandler : Object, IRpcErrorHandler
{
    public void error_handler(Error e)
    {
        error(e.message);
    }
}

