/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'SerialLogplayMsg'
 * message type.
 */

package log;

public class SerialLogplayMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 28;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 23;

    /** Create a new SerialLogplayMsg of size 28. */
    public SerialLogplayMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new SerialLogplayMsg of the given data_length. */
    public SerialLogplayMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialLogplayMsg with the given data_length
     * and base offset.
     */
    public SerialLogplayMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialLogplayMsg using the given byte array
     * as backing store.
     */
    public SerialLogplayMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialLogplayMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public SerialLogplayMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialLogplayMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public SerialLogplayMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialLogplayMsg embedded in the given message
     * at the given base offset.
     */
    public SerialLogplayMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new SerialLogplayMsg embedded in the given message
     * at the given base offset and length.
     */
    public SerialLogplayMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <SerialLogplayMsg> \n";
      try {
        s += "  [header.timestamp=0x"+Long.toHexString(get_header_timestamp())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [header.fragment=0x"+Long.toHexString(get_header_fragment())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [header.fragment_total=0x"+Long.toHexString(get_header_fragment_total())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [header.id=0x"+Long.toHexString(get_header_id())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [header.length=0x"+Long.toHexString(get_header_length())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [data=";
        for (int i = 0; i < 23; i++) {
          s += "0x"+Long.toHexString(getElement_data(i) & 0xff)+" ";
        }
        s += "]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: header.timestamp
    //   Field type: int, unsigned
    //   Offset (bits): 0
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'header.timestamp' is signed (false).
     */
    public static boolean isSigned_header_timestamp() {
        return false;
    }

    /**
     * Return whether the field 'header.timestamp' is an array (false).
     */
    public static boolean isArray_header_timestamp() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'header.timestamp'
     */
    public static int offset_header_timestamp() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'header.timestamp'
     */
    public static int offsetBits_header_timestamp() {
        return 0;
    }

    /**
     * Return the value (as a int) of the field 'header.timestamp'
     */
    public int get_header_timestamp() {
        return (int)getUIntBEElement(offsetBits_header_timestamp(), 16);
    }

    /**
     * Set the value of the field 'header.timestamp'
     */
    public void set_header_timestamp(int value) {
        setUIntBEElement(offsetBits_header_timestamp(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'header.timestamp'
     */
    public static int size_header_timestamp() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'header.timestamp'
     */
    public static int sizeBits_header_timestamp() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: header.fragment
    //   Field type: byte, unsigned
    //   Offset (bits): 16
    //   Size (bits): 4
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'header.fragment' is signed (false).
     */
    public static boolean isSigned_header_fragment() {
        return false;
    }

    /**
     * Return whether the field 'header.fragment' is an array (false).
     */
    public static boolean isArray_header_fragment() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'header.fragment'
     */
    public static int offset_header_fragment() {
        return (16 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'header.fragment'
     */
    public static int offsetBits_header_fragment() {
        return 16;
    }

    /**
     * Return the value (as a byte) of the field 'header.fragment'
     */
    public byte get_header_fragment() {
        return (byte)getUIntBEElement(offsetBits_header_fragment(), 4);
    }

    /**
     * Set the value of the field 'header.fragment'
     */
    public void set_header_fragment(byte value) {
        setUIntBEElement(offsetBits_header_fragment(), 4, value);
    }

    /**
     * Return the size, in bytes, of the field 'header.fragment'
     * WARNING: This field is not an even-sized number of bytes (4 bits).
     */
    public static int size_header_fragment() {
        return (4 / 8) + 1;
    }

    /**
     * Return the size, in bits, of the field 'header.fragment'
     */
    public static int sizeBits_header_fragment() {
        return 4;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: header.fragment_total
    //   Field type: byte, unsigned
    //   Offset (bits): 20
    //   Size (bits): 4
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'header.fragment_total' is signed (false).
     */
    public static boolean isSigned_header_fragment_total() {
        return false;
    }

    /**
     * Return whether the field 'header.fragment_total' is an array (false).
     */
    public static boolean isArray_header_fragment_total() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'header.fragment_total'
     * WARNING: This field is not byte-aligned (bit offset 20).
     */
    public static int offset_header_fragment_total() {
        return (20 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'header.fragment_total'
     */
    public static int offsetBits_header_fragment_total() {
        return 20;
    }

    /**
     * Return the value (as a byte) of the field 'header.fragment_total'
     */
    public byte get_header_fragment_total() {
        return (byte)getUIntBEElement(offsetBits_header_fragment_total(), 4);
    }

    /**
     * Set the value of the field 'header.fragment_total'
     */
    public void set_header_fragment_total(byte value) {
        setUIntBEElement(offsetBits_header_fragment_total(), 4, value);
    }

    /**
     * Return the size, in bytes, of the field 'header.fragment_total'
     * WARNING: This field is not an even-sized number of bytes (4 bits).
     */
    public static int size_header_fragment_total() {
        return (4 / 8) + 1;
    }

    /**
     * Return the size, in bits, of the field 'header.fragment_total'
     */
    public static int sizeBits_header_fragment_total() {
        return 4;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: header.id
    //   Field type: short, unsigned
    //   Offset (bits): 24
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'header.id' is signed (false).
     */
    public static boolean isSigned_header_id() {
        return false;
    }

    /**
     * Return whether the field 'header.id' is an array (false).
     */
    public static boolean isArray_header_id() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'header.id'
     */
    public static int offset_header_id() {
        return (24 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'header.id'
     */
    public static int offsetBits_header_id() {
        return 24;
    }

    /**
     * Return the value (as a short) of the field 'header.id'
     */
    public short get_header_id() {
        return (short)getUIntBEElement(offsetBits_header_id(), 8);
    }

    /**
     * Set the value of the field 'header.id'
     */
    public void set_header_id(short value) {
        setUIntBEElement(offsetBits_header_id(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'header.id'
     */
    public static int size_header_id() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'header.id'
     */
    public static int sizeBits_header_id() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: header.length
    //   Field type: short, unsigned
    //   Offset (bits): 32
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'header.length' is signed (false).
     */
    public static boolean isSigned_header_length() {
        return false;
    }

    /**
     * Return whether the field 'header.length' is an array (false).
     */
    public static boolean isArray_header_length() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'header.length'
     */
    public static int offset_header_length() {
        return (32 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'header.length'
     */
    public static int offsetBits_header_length() {
        return 32;
    }

    /**
     * Return the value (as a short) of the field 'header.length'
     */
    public short get_header_length() {
        return (short)getUIntBEElement(offsetBits_header_length(), 8);
    }

    /**
     * Set the value of the field 'header.length'
     */
    public void set_header_length(short value) {
        setUIntBEElement(offsetBits_header_length(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'header.length'
     */
    public static int size_header_length() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'header.length'
     */
    public static int sizeBits_header_length() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: data
    //   Field type: short[], unsigned
    //   Offset (bits): 40
    //   Size of each element (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'data' is signed (false).
     */
    public static boolean isSigned_data() {
        return false;
    }

    /**
     * Return whether the field 'data' is an array (true).
     */
    public static boolean isArray_data() {
        return true;
    }

    /**
     * Return the offset (in bytes) of the field 'data'
     */
    public static int offset_data(int index1) {
        int offset = 40;
        if (index1 < 0 || index1 >= 23) throw new ArrayIndexOutOfBoundsException();
        offset += 0 + index1 * 8;
        return (offset / 8);
    }

    /**
     * Return the offset (in bits) of the field 'data'
     */
    public static int offsetBits_data(int index1) {
        int offset = 40;
        if (index1 < 0 || index1 >= 23) throw new ArrayIndexOutOfBoundsException();
        offset += 0 + index1 * 8;
        return offset;
    }

    /**
     * Return the entire array 'data' as a short[]
     */
    public short[] get_data() {
        short[] tmp = new short[23];
        for (int index0 = 0; index0 < numElements_data(0); index0++) {
            tmp[index0] = getElement_data(index0);
        }
        return tmp;
    }

    /**
     * Set the contents of the array 'data' from the given short[]
     */
    public void set_data(short[] value) {
        for (int index0 = 0; index0 < value.length; index0++) {
            setElement_data(index0, value[index0]);
        }
    }

    /**
     * Return an element (as a short) of the array 'data'
     */
    public short getElement_data(int index1) {
        return (short)getUIntBEElement(offsetBits_data(index1), 8);
    }

    /**
     * Set an element of the array 'data'
     */
    public void setElement_data(int index1, short value) {
        setUIntBEElement(offsetBits_data(index1), 8, value);
    }

    /**
     * Return the total size, in bytes, of the array 'data'
     */
    public static int totalSize_data() {
        return (184 / 8);
    }

    /**
     * Return the total size, in bits, of the array 'data'
     */
    public static int totalSizeBits_data() {
        return 184;
    }

    /**
     * Return the size, in bytes, of each element of the array 'data'
     */
    public static int elementSize_data() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of each element of the array 'data'
     */
    public static int elementSizeBits_data() {
        return 8;
    }

    /**
     * Return the number of dimensions in the array 'data'
     */
    public static int numDimensions_data() {
        return 1;
    }

    /**
     * Return the number of elements in the array 'data'
     */
    public static int numElements_data() {
        return 23;
    }

    /**
     * Return the number of elements in the array 'data'
     * for the given dimension.
     */
    public static int numElements_data(int dimension) {
      int array_dims[] = { 23,  };
        if (dimension < 0 || dimension >= 1) throw new ArrayIndexOutOfBoundsException();
        if (array_dims[dimension] == 0) throw new IllegalArgumentException("Array dimension "+dimension+" has unknown size");
        return array_dims[dimension];
    }

    /**
     * Fill in the array 'data' with a String
     */
    public void setString_data(String s) { 
         int len = s.length();
         int i;
         for (i = 0; i < len; i++) {
             setElement_data(i, (short)s.charAt(i));
         }
         setElement_data(i, (short)0); //null terminate
    }

    /**
     * Read the array 'data' as a String
     */
    public String getString_data() { 
         char carr[] = new char[Math.min(net.tinyos.message.Message.MAX_CONVERTED_STRING_LENGTH,23)];
         int i;
         for (i = 0; i < carr.length; i++) {
             if ((char)getElement_data(i) == (char)0) break;
             carr[i] = (char)getElement_data(i);
         }
         return new String(carr,0,i);
    }

}
