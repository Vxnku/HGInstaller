using System;
using System.IO;
using System.Text;

public class NbtServerWriter
{
    public static byte[] CreateServersDat(string serverName, string serverIp)
    {
        using (MemoryStream ms = new MemoryStream())
        using (BinaryWriter bw = new BinaryWriter(ms))
        {
            // Root Compound Tag (0x0A) with empty name
            bw.Write((byte)10); // TAG_Compound
            WriteString(bw, ""); // empty name

            // Tag "servers" (TAG_List = 0x09)
            bw.Write((byte)9); // TAG_List
            WriteString(bw, "servers");
            bw.Write((byte)10); // Element Type = TAG_Compound
            bw.Write(SwapBytes((int)1)); // List length = 1 (big-endian)

            // --- Server 1 Compound ---
            // TAG_String "ip"
            bw.Write((byte)8);
            WriteString(bw, "ip");
            WriteString(bw, serverIp);

            // TAG_String "name"
            bw.Write((byte)8);
            WriteString(bw, "name");
            WriteString(bw, serverName);

            // TAG_Byte "acceptTextures" = 1 (Prompt/Enabled)
            bw.Write((byte)1);
            WriteString(bw, "acceptTextures");
            bw.Write((byte)1);

            // TAG_Byte "hidden" = 0
            bw.Write((byte)1);
            WriteString(bw, "hidden");
            bw.Write((byte)0);

            // TAG_End for Server Compound (0x00)
            bw.Write((byte)0);

            // TAG_End for Root Compound (0x00)
            bw.Write((byte)0);

            return ms.ToArray();
        }
    }

    private static void WriteString(BinaryWriter bw, string str)
    {
        byte[] bytes = Encoding.UTF8.GetBytes(str);
        bw.Write(SwapBytes((short)bytes.Length)); // big-endian short
        bw.Write(bytes);
    }

    private static short SwapBytes(short val)
    {
        return (short)(((val & 0xFF) << 8) | ((val >> 8) & 0xFF));
    }

    private static int SwapBytes(int val)
    {
        return (int)(((val & 0x000000FF) << 24) |
                     ((val & 0x0000FF00) << 8) |
                     ((val & 0x00FF0000) >> 8) |
                     ((val >> 24) & 0x000000FF));
    }
}
