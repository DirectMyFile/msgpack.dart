part of msgpack;

ByteBuffer unpack(buffer) => new Unpacker(buffer)..unpack()..data.buffer;

class Unpacker {
    ByteData data;
    int index = 0;

    Unpacker(ByteBuffer buffer) {
        data = new ByteData.view(buffer);
    }

    unpack() {
        int type = data.getUint8(index++);

        if (type >= 0xe0) return type - 0x100;
        if (type < 0xc0) {
            if (type < 0x80) return type;
            else if (type < 0x90) return unpackMap(() => type - 0x80);
            else if (type < 0xa0) return unpackList(() => type - 0x90);
            else return unpackString(() => type - 0xa0);
        }

        switch (type) {
            case 0xc0: return null;
            case 0xc2: return false;
            case 0xc3: return true;

            case 0xcf: return unpackU64();
            case 0xce: return unpackU32();
            case 0xcd: return unpackU16();
            case 0xcc: return unpackU8();

            case 0xd3: return unpackS64();
            case 0xd2: return unpackS32();
            case 0xd1: return unpackS16();
            case 0xd0: return unpackS8();

            case 0xd9: return unpackString(unpackU8);
            case 0xda: return unpackString(unpackU16);
            case 0xdb: return unpackString(unpackU32);

            case 0xdf: return unpackMap(unpackU32);
            case 0xde: return unpackMap(unpackU16);
            case 0x80: return unpackMap(unpackU8);

            case 0xdd: return unpackList(unpackU32);
            case 0xdc: return unpackList(unpackU16);
            case 0x90: return unpackList(unpackU8);
        }
    }

    int unpackU64() {
        int value = data.getUint64(index);
        index += 8;
        return value;
    }

    int unpackU32() {
        int value = data.getUint32(index);
        index += 4;
        return value;
    }

    int unpackU16() {
        int value = data.getUint16(index);
        index += 2;
        return value;
    }

    int unpackU8() {
        return data.getUint8(index++);
    }

    int unpackS64() {
        int value = data.getInt64(index);
        index += 8;
        return value;
    }

    int unpackS32() {
        int value = data.getInt32(index);
        index += 4;
        return value;
    }

    int unpackS16() {
        int value = data.getInt16(index);
        index += 2;
        return value;
    }

    int unpackS8() {
        return data.getInt8(index++);
    }

    String unpackString(int unpackCount()) {
        int count = unpackCount();
        String value = UTF8.decode(new List.from(new Uint8List.view(data.buffer, index, count)));
        index += count;
        return value;
    }

    Map unpackMap(int unpackCount()) {
        Map map = {};
        int count = unpackCount();
        for (int i = 0; i < count; ++i) {
            map[unpack()] = unpack();
        }
        return map;
    }

    List unpackList(int unpackCount()) {
        List list = [];
        int count = unpackCount();
        for (int i = 0; i < count; ++i) {
            list.add(unpack());
        }
        return list;
    }

    unpackMessage(factory(List fields)) {
        List fields = unpack();
        return factory(fields);
    }
}
