# [Sqids Odin](https://sqids.org/odin)

[![npm version](https://img.shields.io/npm/v/sqids.svg)](https://www.npmjs.com/package/sqids)
[![Downloads](https://img.shields.io/npm/dm/sqids)](https://www.npmjs.com/package/sqids)

[Sqids](https://sqids.org/odin) (*pronounced "squids"*) is a small library that lets you **generate unique IDs from numbers**. It's good for link shortening, fast & URL-safe ID generation and decoding back into numbers for quicker database lookups.

Features:

- **Encode multiple numbers** - generate short IDs from one or several non-negative numbers
- **Quick decoding** - easily decode IDs back into numbers
- **Unique IDs** - generate unique IDs by shuffling the alphabet once
- **ID padding** - provide minimum length to make IDs more uniform
- **URL safe** - auto-generated IDs do not contain common profanity
- **Randomized output** - Sequential input provides nonconsecutive IDs
- **Many implementations** - Support for [40+ programming languages](https://sqids.org/)

## 🧰 Use-cases

Good for:

- Generating IDs for public URLs (eg: link shortening)
- Generating IDs for internal systems (eg: event tracking)
- Decoding for quicker database lookups (eg: by primary keys)

Not good for:

- Sensitive data (this is not an encryption library)
- User IDs (can be decoded revealing user count)

## 🚀 Getting started

Copy the `sqids` folder to your project.

## 👩‍💻 Examples

Simple encode & decode:

```odin
import "sqids"

s, err := sqids.init()
if err != .None {
  // init failed
  return
}
defer sqids.deinit(s)

id, encode_err := sqids.encode(s, {1, 2, 3}) // "86Rf07"
if encode_err != .None {
    // encodings can fail if blocklist leads to too many retries
}
defer delete(id)  // caller owns the memory

numbers := sqids.decode(s, id) // []uint{1, 2, 3}
defer delete(numbers) // caller owns the memory
```

> **Note**
> 🚧 Because of the algorithm's design, **multiple IDs can decode back into the same sequence of numbers**. If it's important to your design that IDs are canonical, you have to manually re-encode decoded numbers and check that the generated ID matches.

Enforce a *minimum* length for IDs:

```odin
import "sqids"

s, err := sqids.init({
  min_length = 10,
})
if err != .None {
  // init failed
  return
}
defer sqids.deinit(s)

id, _ := sqids.encode(s, {1, 2, 3}) // "86Rf07xd4z"
defer delete(id)

numbers := sqids.decode(s, id) // []uint{1, 2, 3}
defer delete(numbers)
```

Randomize IDs by providing a custom alphabet:

```odin
import "sqids"

s, err := sqids.init({
  alphabet = "FxnXM1kBN6cuhsAvjW3Co7l2RePyY8DwaU04Tzt9fHQrqSVKdpimLGIJOgb5ZE",
})

id, _ := sqids.encode(s, {1, 2, 3}) // "B4aajs"
defer delete(id)

numbers := sqids.decode(s, id) // []uint{1, 2, 3}
defer delete(numbers)
```

Prevent specific words from appearing anywhere in the auto-generated IDs:

```odin
import "sqids"

s, err := sqids.init({
  blocklist = []string{"86Rf07"},
})

id, _ := sqids.encode(s, {1, 2, 3}) // "se8ojk"
defer delete(id)

numbers := sqids.decode(s, id) // []uint{1, 2, 3}
defer delete(numbers)
```

Use your own allocator:

```odin
import "sqids"

// ...

id, _ := sqids.encode(s, {1,2,3}, allocator = my_allocator)
defer delete(id)
```

## 📝 License

[MIT](LICENSE)
