using Gee;
using SampleRpc;
using TaskletSystem;

void main(string[] args)
{
    assert(args.length > 4);
    string dev = args[1];
    string sourceid = args[2];
    string msg = args[3];
    ArrayList<string> ids = new ArrayList<string>();
    ids.add(args[4]);
    for (int i = 5; i < args.length; i++) ids.add(args[i]);

    PthTaskletImplementer.init();
    ITasklet tasklet = PthTaskletImplementer.get_tasklet_system();
    init_tasklet_system(tasklet);
    //typeof(MySourceID).class_peek();
    //typeof(MyUnicastID).class_peek();
    //typeof(MyBroadcastID).class_peek();

    // add udp_listen for receiveing ACKs
    var dlg = new NullRpcDelegate();
    var err = new MyRpcErrorHandler();
    udp_listen(dlg, err, 269, dev);

    Gee.Collection<string> devs = new ArrayList<string>.wrap({dev});
    MySourceID mysourceid = new MySourceID(sourceid);
    MyBroadcastID mybroadcastid = new MyBroadcastID(ids);
    IAckCommunicator ack_comm = new MyAckCommunicator();
    try
    {
        IOperatoreStub op = get_op_broadcast(devs, 269, mysourceid, mybroadcastid, ack_comm);
        op.note.scrivi(msg);
    }
    catch (StubError e)
    {
        print(@"StubError: $(e.message)\n");
    }
    catch (DeserializeError e)
    {
        print(@"DeserializeError: $(e.message)\n");
    }

    tasklet.ms_wait(5000);
}

class MyAckCommunicator : Object, IAckCommunicator
{
    public void process_macs_list(Gee.List<string> macs_list)
    {
        print("Macs:---\n");
        foreach (string mac in macs_list) print(@" $(mac)\n");
        print("--------\n");
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

