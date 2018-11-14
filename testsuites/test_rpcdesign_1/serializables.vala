using SampleRpc;
using Gee;

namespace Tester
{
    public class UnicastID : Object, IUnicastID
    {
        public UnicastID(int id)
        {
            this.id = id;
        }

        public int id {get; set;}
    }

    public class SourceID : Object, ISourceID
    {
        public SourceID(int id)
        {
            this.id = id;
        }

        public int id {get; set;}
    }

    public class SrcNic : Object, ISrcNic
    {
        public SrcNic(string mac)
        {
            this.mac = mac;
        }

        public string mac {get; set;}
    }

    public class EverybodyBroadcastID : Object, IBroadcastID
    {
    }

    public class Fields : Object, IFields
    {
        public string zero {get; set;}
        public string one {get; set;}
        public string two {get; set;}
    }

    public class BroadcastID : Object, Json.Serializable, IBroadcastID
    {
        public BroadcastID(Gee.List<int> id_set)
        {
            this.id_set = new ArrayList<int>();
            this.id_set.add_all(id_set);
        }
        public Gee.List<int> id_set {get; set;}

        public bool deserialize_property
        (string property_name,
         out GLib.Value @value,
         GLib.ParamSpec pspec,
         Json.Node property_node)
        {
            @value = 0;
            switch (property_name) {
            case "id_set":
            case "id-set":
                try {
                    @value = deserialize_list_int(property_node);
                } catch (HelperDeserializeError e) {
                    return false;
                }
                break;
            default:
                return false;
            }
            return true;
        }

        public unowned GLib.ParamSpec? find_property
        (string name)
        {
            return get_class().find_property(name);
        }

        public Json.Node serialize_property
        (string property_name,
         GLib.Value @value,
         GLib.ParamSpec pspec)
        {
            switch (property_name) {
            case "id_set":
            case "id-set":
                return serialize_list_int((Gee.List<int>)@value);
            default:
                error(@"wrong param $(property_name)");
            }
        }
    }

    internal errordomain HelperDeserializeError {
        GENERIC
    }

    internal Gee.List<int> deserialize_list_int(Json.Node property_node)
    throws HelperDeserializeError
    {
        ArrayList<int> ret = new ArrayList<int>();
        Json.Reader r = new Json.Reader(property_node.copy());
        if (r.get_null_value())
            throw new HelperDeserializeError.GENERIC("element is not nullable");
        if (!r.is_array())
            throw new HelperDeserializeError.GENERIC("element must be an array");
        int l = r.count_elements();
        for (int j = 0; j < l; j++)
        {
            r.read_element(j);
            if (r.get_null_value())
                throw new HelperDeserializeError.GENERIC("element is not nullable");
            if (!r.is_value())
                throw new HelperDeserializeError.GENERIC("element must be a int");
            if (r.get_value().get_value_type() != typeof(int64))
                throw new HelperDeserializeError.GENERIC("element must be a int");
            int64 val = r.get_int_value();
            if (val > int.MAX || val < int.MIN)
                throw new HelperDeserializeError.GENERIC("element overflows size of int");
            ret.add((int)val);
            r.end_element();
        }
        return ret;
    }

    internal Json.Node serialize_list_int(Gee.List<int> lst)
    {
        Json.Builder b = new Json.Builder();
        b.begin_array();
        foreach (int i in lst)
        {
            b.add_int_value(i);
        }
        b.end_array();
        return b.get_root();
    }
}