/*
interfaces.rpcidl
==========================================
Operatore op
 Notificatore note
  void scrivi(string msg)
 Risponditore res
  string salutami()

==========================================
 */

using Gee;
using zcd;

namespace SampleRpc
{
    public interface ISourceID : Object
    {
    }

    public interface IUnicastID : Object
    {
    }

    public interface IBroadcastID : Object
    {
    }
}
