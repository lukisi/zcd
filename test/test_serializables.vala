using SampleRpc;

public class MySourceID : Object, ISourceID
{
    public MySourceID(string id)
    {
        this.id = id;
    }
    public string id {get; set;}
}

public class MyUnicastID : Object, IUnicastID
{
    public MyUnicastID(string id)
    {
        this.id = id;
    }
    public string id {get; set;}
}

public class MyBroadcastID : Object, IBroadcastID
{
    public MyBroadcastID(Gee.List<string> id_list)
    {
        assert(! id_list.is_empty);
        id_set = "+";
        foreach (string s in id_list) id_set += @"$(s)+";
    }
    public string id_set {get; set;}

    public bool contains(string s)
    {
        if (@"+$(s)+" in id_set) return true;
        return false;
    }
}

