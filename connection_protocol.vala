/*
 *  This file is part of Netsukuku.
 *  (c) Copyright 2018 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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
using TaskletSystem;

namespace zcd
{
    internal errordomain RecvMessageError {
        TOO_BIG,
        FAIL_ALLOC,
        GENERIC
    }

    internal errordomain SendMessageError {
        GENERIC
    }

    internal void send_one_message(IConnectedStreamSocket c, string msg) throws SendMessageError
    {
        size_t len = msg.length;
        assert(len <= uint32.MAX);
        uint8 buf_numbytes[4];
        buf_numbytes[3] = (uint8)(len % 256);
        len -= buf_numbytes[3];
        len /= 256;
        buf_numbytes[2] = (uint8)(len % 256);
        len -= buf_numbytes[2];
        len /= 256;
        buf_numbytes[1] = (uint8)(len % 256);
        len -= buf_numbytes[1];
        len /= 256;
        buf_numbytes[0] = (uint8)(len % 256);
        try {
            c.send(buf_numbytes, 4);
            c.send(msg.data, msg.length);
        } catch (Error e) {
            throw new SendMessageError.GENERIC(@"$(e.message)");
        }
    }

    internal size_t max_msg_size = 10000000;

    /*
    ** If the connection was closed from peer, we return false and m=null.
    ** If an RecvMessageError is reported, m=null.
    ** If m!= null, the caller can safely use something like that:
                unowned uint8[] buf;
                buf = (uint8[])m;
                buf.length = (int)s;
                unowned string msg = (string)buf;
    ** After using msg, the caller has to free m.
    **/
    internal bool get_one_message(IConnectedStreamSocket c, out void * m, out size_t s) throws RecvMessageError
    {
        // Get one message
        m = null;
        s = 0;
        unowned uint8[] buf;

        uint8 buf_numbytes[4];
        size_t maxlen = 4;
        uint8* b = buf_numbytes;
        bool no_bytes_read = true;
        while (maxlen > 0)
        {
            try {
                size_t len = c.recv(b, maxlen);
                if (len == 0)
                {
                    if (no_bytes_read)
                    {
                        // normal closing from client, abnormal if from server.
                        return false;
                    }
                    throw new RecvMessageError.GENERIC("4-bytes length is missing");
                }
                no_bytes_read = false;
                maxlen -= len;
                b += len;
            } catch (Error e) {
                throw new RecvMessageError.GENERIC(e.message);
            }
        }
        size_t msglen = buf_numbytes[0];
        msglen *= 256;
        msglen += buf_numbytes[1];
        msglen *= 256;
        msglen += buf_numbytes[2];
        msglen *= 256;
        msglen += buf_numbytes[3];
        if (msglen > max_msg_size)
        {
            throw new RecvMessageError.TOO_BIG(@"Refusing to receive a message too big ($(msglen) bytes)");
        }

        s = msglen + 1;
        m = try_malloc(s);
        if (m == null)
        {
            throw new RecvMessageError.FAIL_ALLOC(@"Could not allocate memory ($(s) bytes)");
        }
        buf = (uint8[])m;
        buf.length = (int)s;
        maxlen = msglen;
        b = buf;
        while (maxlen > 0)
        {
            try {
                size_t len = c.recv(b, maxlen);
                if (len == 0)
                {
                    throw new RecvMessageError.GENERIC(@"More bytes (len=$(msglen)) were expected.");
                }
                maxlen -= len;
                b += len;
            } catch (Error e) {
                free(m);
                m = null;
                s = 0;
                throw new RecvMessageError.GENERIC(e.message);
            }
        }
        buf[msglen] = (uint8)0;
        return true;
    }
}