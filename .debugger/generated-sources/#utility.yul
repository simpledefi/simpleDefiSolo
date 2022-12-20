{

    // uint256[]
    function abi_decode_available_length_t_array$_t_uint256_$dyn_memory_ptr_fromMemory(offset, length, end) -> array {
        array := allocate_memory(array_allocation_size_t_array$_t_uint256_$dyn_memory_ptr(length))
        let dst := array

        mstore(array, length)
        dst := add(array, 0x20)

        let src := offset
        if gt(add(src, mul(length, 0x20)), end) {
            revert(0, 0)
        }
        for { let i := 0 } lt(i, length) { i := add(i, 1) }
        {

            let elementPos := src

            mstore(dst, abi_decode_t_uint256_fromMemory(elementPos, end))
            dst := add(dst, 0x20)
            src := add(src, 0x20)
        }
    }

    // uint256[]
    function abi_decode_t_array$_t_uint256_$dyn_memory_ptr_fromMemory(offset, end) -> array {
        if iszero(slt(add(offset, 0x1f), end)) { revert(0, 0) }
        let length := mload(offset)
        array := abi_decode_available_length_t_array$_t_uint256_$dyn_memory_ptr_fromMemory(add(offset, 0x20), length, end)
    }

    function abi_decode_t_uint256_fromMemory(offset, end) -> value {
        value := mload(offset)
        validator_revert_t_uint256(value)
    }

    function abi_decode_tuple_t_array$_t_uint256_$dyn_memory_ptr_fromMemory(headStart, dataEnd) -> value0 {
        if slt(sub(dataEnd, headStart), 32) { revert(0, 0) }

        {

            let offset := mload(add(headStart, 0))
            if gt(offset, 0xffffffffffffffff) { revert(0, 0) }

            value0 := abi_decode_t_array$_t_uint256_$dyn_memory_ptr_fromMemory(add(headStart, offset), dataEnd)
        }

    }

    function abi_decode_tuple_t_uint256_fromMemory(headStart, dataEnd) -> value0 {
        if slt(sub(dataEnd, headStart), 32) { revert(0, 0) }

        {

            let offset := 0

            value0 := abi_decode_t_uint256_fromMemory(add(headStart, offset), dataEnd)
        }

    }

    function abi_encodeUpdatedPos_t_address_to_t_address(value0, pos) -> updatedPos {
        abi_encode_t_address_to_t_address(value0, pos)
        updatedPos := add(pos, 0x20)
    }

    function abi_encodeUpdatedPos_t_uint256_to_t_uint256(value0, pos) -> updatedPos {
        abi_encode_t_uint256_to_t_uint256(value0, pos)
        updatedPos := add(pos, 0x20)
    }

    function abi_encode_t_address_to_t_address(value, pos) {
        mstore(pos, cleanup_t_address(value))
    }

    function abi_encode_t_address_to_t_address_fromStack(value, pos) {
        mstore(pos, cleanup_t_address(value))
    }

    // address[] -> address[]
    function abi_encode_t_array$_t_address_$dyn_memory_ptr_to_t_array$_t_address_$dyn_memory_ptr_fromStack(value, pos)  -> end  {
        let length := array_length_t_array$_t_address_$dyn_memory_ptr(value)
        pos := array_storeLengthForEncoding_t_array$_t_address_$dyn_memory_ptr_fromStack(pos, length)
        let baseRef := array_dataslot_t_array$_t_address_$dyn_memory_ptr(value)
        let srcPtr := baseRef
        for { let i := 0 } lt(i, length) { i := add(i, 1) }
        {
            let elementValue0 := mload(srcPtr)
            pos := abi_encodeUpdatedPos_t_address_to_t_address(elementValue0, pos)
            srcPtr := array_nextElement_t_array$_t_address_$dyn_memory_ptr(srcPtr)
        }
        end := pos
    }

    // uint256[] -> uint256[]
    function abi_encode_t_array$_t_uint256_$dyn_memory_ptr_to_t_array$_t_uint256_$dyn_memory_ptr_fromStack(value, pos)  -> end  {
        let length := array_length_t_array$_t_uint256_$dyn_memory_ptr(value)
        pos := array_storeLengthForEncoding_t_array$_t_uint256_$dyn_memory_ptr_fromStack(pos, length)
        let baseRef := array_dataslot_t_array$_t_uint256_$dyn_memory_ptr(value)
        let srcPtr := baseRef
        for { let i := 0 } lt(i, length) { i := add(i, 1) }
        {
            let elementValue0 := mload(srcPtr)
            pos := abi_encodeUpdatedPos_t_uint256_to_t_uint256(elementValue0, pos)
            srcPtr := array_nextElement_t_array$_t_uint256_$dyn_memory_ptr(srcPtr)
        }
        end := pos
    }

    function abi_encode_t_stringliteral_15981855a3460be2ba5023bfe78bece62d42ab2ee27d514b2476360a28ee0d9c_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 21)
        store_literal_in_memory_15981855a3460be2ba5023bfe78bece62d42ab2ee27d514b2476360a28ee0d9c(pos)
        end := add(pos, 32)
    }

    function abi_encode_t_stringliteral_3cad5d3ec16e143a33da68c00099116ef328a882b65607bec5b2431267934a20_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 6)
        store_literal_in_memory_3cad5d3ec16e143a33da68c00099116ef328a882b65607bec5b2431267934a20(pos)
        end := add(pos, 32)
    }

    function abi_encode_t_stringliteral_5b610e8e1835afecdd154863369b91f55612defc17933f83f4425533c435a248_to_t_string_memory_ptr_fromStack(pos) -> end {
        pos := array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, 6)
        store_literal_in_memory_5b610e8e1835afecdd154863369b91f55612defc17933f83f4425533c435a248(pos)
        end := add(pos, 32)
    }

    function abi_encode_t_uint256_to_t_uint256(value, pos) {
        mstore(pos, cleanup_t_uint256(value))
    }

    function abi_encode_t_uint256_to_t_uint256_fromStack(value, pos) {
        mstore(pos, cleanup_t_uint256(value))
    }

    function abi_encode_tuple_t_address__to_t_address__fromStack_reversed(headStart , value0) -> tail {
        tail := add(headStart, 32)

        abi_encode_t_address_to_t_address_fromStack(value0,  add(headStart, 0))

    }

    function abi_encode_tuple_t_stringliteral_15981855a3460be2ba5023bfe78bece62d42ab2ee27d514b2476360a28ee0d9c_t_array$_t_uint256_$dyn_memory_ptr__to_t_string_memory_ptr_t_array$_t_uint256_$dyn_memory_ptr__fromStack_reversed(headStart , value0) -> tail {
        tail := add(headStart, 64)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_15981855a3460be2ba5023bfe78bece62d42ab2ee27d514b2476360a28ee0d9c_to_t_string_memory_ptr_fromStack( tail)

        mstore(add(headStart, 32), sub(tail, headStart))
        tail := abi_encode_t_array$_t_uint256_$dyn_memory_ptr_to_t_array$_t_uint256_$dyn_memory_ptr_fromStack(value0,  tail)

    }

    function abi_encode_tuple_t_stringliteral_3cad5d3ec16e143a33da68c00099116ef328a882b65607bec5b2431267934a20_t_uint256__to_t_string_memory_ptr_t_uint256__fromStack_reversed(headStart , value0) -> tail {
        tail := add(headStart, 64)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_3cad5d3ec16e143a33da68c00099116ef328a882b65607bec5b2431267934a20_to_t_string_memory_ptr_fromStack( tail)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 32))

    }

    function abi_encode_tuple_t_stringliteral_5b610e8e1835afecdd154863369b91f55612defc17933f83f4425533c435a248_t_uint256__to_t_string_memory_ptr_t_uint256__fromStack_reversed(headStart , value0) -> tail {
        tail := add(headStart, 64)

        mstore(add(headStart, 0), sub(tail, headStart))
        tail := abi_encode_t_stringliteral_5b610e8e1835afecdd154863369b91f55612defc17933f83f4425533c435a248_to_t_string_memory_ptr_fromStack( tail)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 32))

    }

    function abi_encode_tuple_t_uint256__to_t_uint256__fromStack_reversed(headStart , value0) -> tail {
        tail := add(headStart, 32)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

    }

    function abi_encode_tuple_t_uint256_t_address__to_t_uint256_t_address__fromStack_reversed(headStart , value1, value0) -> tail {
        tail := add(headStart, 64)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

        abi_encode_t_address_to_t_address_fromStack(value1,  add(headStart, 32))

    }

    function abi_encode_tuple_t_uint256_t_array$_t_address_$dyn_memory_ptr__to_t_uint256_t_array$_t_address_$dyn_memory_ptr__fromStack_reversed(headStart , value1, value0) -> tail {
        tail := add(headStart, 64)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

        mstore(add(headStart, 32), sub(tail, headStart))
        tail := abi_encode_t_array$_t_address_$dyn_memory_ptr_to_t_array$_t_address_$dyn_memory_ptr_fromStack(value1,  tail)

    }

    function abi_encode_tuple_t_uint256_t_array$_t_address_$dyn_memory_ptr_t_address_t_uint256__to_t_uint256_t_array$_t_address_$dyn_memory_ptr_t_address_t_uint256__fromStack_reversed(headStart , value3, value2, value1, value0) -> tail {
        tail := add(headStart, 128)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

        mstore(add(headStart, 32), sub(tail, headStart))
        tail := abi_encode_t_array$_t_address_$dyn_memory_ptr_to_t_array$_t_address_$dyn_memory_ptr_fromStack(value1,  tail)

        abi_encode_t_address_to_t_address_fromStack(value2,  add(headStart, 64))

        abi_encode_t_uint256_to_t_uint256_fromStack(value3,  add(headStart, 96))

    }

    function abi_encode_tuple_t_uint256_t_uint256_t_array$_t_address_$dyn_memory_ptr_t_address_t_uint256__to_t_uint256_t_uint256_t_array$_t_address_$dyn_memory_ptr_t_address_t_uint256__fromStack_reversed(headStart , value4, value3, value2, value1, value0) -> tail {
        tail := add(headStart, 160)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

        abi_encode_t_uint256_to_t_uint256_fromStack(value1,  add(headStart, 32))

        mstore(add(headStart, 64), sub(tail, headStart))
        tail := abi_encode_t_array$_t_address_$dyn_memory_ptr_to_t_array$_t_address_$dyn_memory_ptr_fromStack(value2,  tail)

        abi_encode_t_address_to_t_address_fromStack(value3,  add(headStart, 96))

        abi_encode_t_uint256_to_t_uint256_fromStack(value4,  add(headStart, 128))

    }

    function abi_encode_tuple_t_uint256_t_uint256_t_uint256__to_t_uint256_t_uint256_t_uint256__fromStack_reversed(headStart , value2, value1, value0) -> tail {
        tail := add(headStart, 96)

        abi_encode_t_uint256_to_t_uint256_fromStack(value0,  add(headStart, 0))

        abi_encode_t_uint256_to_t_uint256_fromStack(value1,  add(headStart, 32))

        abi_encode_t_uint256_to_t_uint256_fromStack(value2,  add(headStart, 64))

    }

    function allocate_memory(size) -> memPtr {
        memPtr := allocate_unbounded()
        finalize_allocation(memPtr, size)
    }

    function allocate_unbounded() -> memPtr {
        memPtr := mload(64)
    }

    function array_allocation_size_t_array$_t_uint256_$dyn_memory_ptr(length) -> size {
        // Make sure we can allocate memory without overflow
        if gt(length, 0xffffffffffffffff) { panic_error_0x41() }

        size := mul(length, 0x20)

        // add length slot
        size := add(size, 0x20)

    }

    function array_dataslot_t_array$_t_address_$dyn_memory_ptr(ptr) -> data {
        data := ptr

        data := add(ptr, 0x20)

    }

    function array_dataslot_t_array$_t_uint256_$dyn_memory_ptr(ptr) -> data {
        data := ptr

        data := add(ptr, 0x20)

    }

    function array_length_t_array$_t_address_$dyn_memory_ptr(value) -> length {

        length := mload(value)

    }

    function array_length_t_array$_t_uint256_$dyn_memory_ptr(value) -> length {

        length := mload(value)

    }

    function array_nextElement_t_array$_t_address_$dyn_memory_ptr(ptr) -> next {
        next := add(ptr, 0x20)
    }

    function array_nextElement_t_array$_t_uint256_$dyn_memory_ptr(ptr) -> next {
        next := add(ptr, 0x20)
    }

    function array_storeLengthForEncoding_t_array$_t_address_$dyn_memory_ptr_fromStack(pos, length) -> updated_pos {
        mstore(pos, length)
        updated_pos := add(pos, 0x20)
    }

    function array_storeLengthForEncoding_t_array$_t_uint256_$dyn_memory_ptr_fromStack(pos, length) -> updated_pos {
        mstore(pos, length)
        updated_pos := add(pos, 0x20)
    }

    function array_storeLengthForEncoding_t_string_memory_ptr_fromStack(pos, length) -> updated_pos {
        mstore(pos, length)
        updated_pos := add(pos, 0x20)
    }

    function checked_add_t_uint256(x, y) -> sum {
        x := cleanup_t_uint256(x)
        y := cleanup_t_uint256(y)

        // overflow, if x > (maxValue - y)
        if gt(x, sub(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, y)) { panic_error_0x11() }

        sum := add(x, y)
    }

    function checked_div_t_uint256(x, y) -> r {
        x := cleanup_t_uint256(x)
        y := cleanup_t_uint256(y)
        if iszero(y) { panic_error_0x12() }

        r := div(x, y)
    }

    function checked_mul_t_uint256(x, y) -> product {
        x := cleanup_t_uint256(x)
        y := cleanup_t_uint256(y)

        // overflow, if x != 0 and y > (maxValue / x)
        if and(iszero(iszero(x)), gt(y, div(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, x))) { panic_error_0x11() }

        product := mul(x, y)
    }

    function checked_sub_t_uint256(x, y) -> diff {
        x := cleanup_t_uint256(x)
        y := cleanup_t_uint256(y)

        if lt(x, y) { panic_error_0x11() }

        diff := sub(x, y)
    }

    function cleanup_t_address(value) -> cleaned {
        cleaned := cleanup_t_uint160(value)
    }

    function cleanup_t_uint160(value) -> cleaned {
        cleaned := and(value, 0xffffffffffffffffffffffffffffffffffffffff)
    }

    function cleanup_t_uint256(value) -> cleaned {
        cleaned := value
    }

    function finalize_allocation(memPtr, size) {
        let newFreePtr := add(memPtr, round_up_to_mul_of_32(size))
        // protect against overflow
        if or(gt(newFreePtr, 0xffffffffffffffff), lt(newFreePtr, memPtr)) { panic_error_0x41() }
        mstore(64, newFreePtr)
    }

    function panic_error_0x11() {
        mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
        mstore(4, 0x11)
        revert(0, 0x24)
    }

    function panic_error_0x12() {
        mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
        mstore(4, 0x12)
        revert(0, 0x24)
    }

    function panic_error_0x41() {
        mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)
        mstore(4, 0x41)
        revert(0, 0x24)
    }

    function round_up_to_mul_of_32(value) -> result {
        result := and(add(value, 31), not(31))
    }

    function store_literal_in_memory_15981855a3460be2ba5023bfe78bece62d42ab2ee27d514b2476360a28ee0d9c(memPtr) {

        mstore(add(memPtr, 0), "swapExactETHForTokens")

    }

    function store_literal_in_memory_3cad5d3ec16e143a33da68c00099116ef328a882b65607bec5b2431267934a20(memPtr) {

        mstore(add(memPtr, 0), "token0")

    }

    function store_literal_in_memory_5b610e8e1835afecdd154863369b91f55612defc17933f83f4425533c435a248(memPtr) {

        mstore(add(memPtr, 0), "token1")

    }

    function validator_revert_t_uint256(value) {
        if iszero(eq(value, cleanup_t_uint256(value))) { revert(0, 0) }
    }

}
