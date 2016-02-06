using Gee;
using SampleRpc;
using TaskletSystem;

void main(string[] args)
{
    assert(args.length == 4);
    string dest_ip = args[1];
    string sourceid = args[2];
    string destid = args[3];

    PthTaskletImplementer.init();
    ITasklet tasklet = PthTaskletImplementer.get_tasklet_system();
    init_tasklet_system(tasklet);
    //typeof(MySourceID).class_peek();
    //typeof(MyUnicastID).class_peek();
    //typeof(MyBroadcastID).class_peek();

    MySourceID mysourceid = new MySourceID(sourceid);
    MyUnicastID unicastid = new MyUnicastID(destid);
    try
    {
        IOperatoreStub op = get_op_tcp_client(dest_ip, 269, mysourceid, unicastid);
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

