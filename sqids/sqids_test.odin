package sqids

import "core:testing"
import "core:slice"

@(test)
test_encoding :: proc(t: ^testing.T) {
  s, _ := init()
  defer deinit(s)

  expect_encode(t, s, "encoding no numbers", {}, "")
  expect_decode(t, s, "decoding empty string", "", {})
  expect_decode(t, s, "decoding an ID with an invalid character", "*", {})

  {
    name := "simple"
    numbers := []uint{1, 2, 3}
    id := "86Rf07"

    expect_encode(t, s, name, numbers, id)
    expect_decode(t, s, name, id, numbers)
  }

  {
    name := "different inputs"

    numbers := []uint{0, 0, 0, 1, 2, 3, 100, 1_000, 100_000, 1_000_000, max(uint)}
    expect_encode_decode(t, s, name, numbers)
  }

  {
    name := "incremental numbers"

    cases := []struct{
      id: string,
      numbers: []uint,
    }{
      { "bM", {0} },
      { "Uk", {1} },
      { "gb", {2} },
      { "Ef", {3} },
      { "Vq", {4} },
      { "uw", {5} },
      { "OI", {6} },
      { "AX", {7} },
      { "p6", {8} },
      { "nJ", {9} },
    }

    for c in cases {
      expect_encode(t, s, name, c.numbers, c.id)
      expect_decode(t, s, name, c.id, c.numbers)
    }
  }

  {
    name := "incremental numbers, same index 0"

    cases := []struct{
      id: string,
      numbers: []uint,
    }{
      { "SvIz", {0, 0} },
      { "n3qa", {0, 1} },
      { "tryF", {0, 2} },
      { "eg6q", {0, 3} },
      { "rSCF", {0, 4} },
      { "sR8x", {0, 5} },
      { "uY2M", {0, 6} },
      { "74dI", {0, 7} },
      { "30WX", {0, 8} },
      { "moxr", {0, 9} },
    }

    for c in cases {
      expect_encode(t, s, name, c.numbers, c.id)
      expect_decode(t, s, name, c.id, c.numbers)
    }
  }

  {
    name := "incremental numbers, same index 1"

    cases := []struct{
      id: string,
      numbers: []uint,
    }{
      { "SvIz", {0, 0} },
      { "nWqP", {1, 0} },
      { "tSyw", {2, 0} },
      { "eX68", {3, 0} },
      { "rxCY", {4, 0} },
      { "sV8a", {5, 0} },
      { "uf2K", {6, 0} },
      { "7Cdk", {7, 0} },
      { "3aWP", {8, 0} },
      { "m2xn", {9, 0} },
    }

    for c in cases {
      expect_encode(t, s, name, c.numbers, c.id)
      expect_decode(t, s, name, c.id, c.numbers)
    }
  }

  {
    name := "multi input"

    numbers := []uint{
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
      26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
      50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73,
      74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97,
      98, 99,
    }

    expect_encode_decode(t, s, name, numbers)
  }
}

@(test)
test_alphabet :: proc(t: ^testing.T) {
  cases := []struct{
    numbers: []uint,
    alphabet: string,
    err: Error,
  }{
    { {1, 2, 3}, "abc", .None },
    { {1, 2, 3}, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:'\"/?.>,<`~", .None },
    { {}, "ë1092", .Invalid_Multibyte_Character },
    { {}, "aabcdefg", .Alphabet_Repeating_Character },
    { {}, "ab", .Alphabet_Too_Short },
  }

  for c in cases {
    s, err := init({ alphabet = c.alphabet })
    defer deinit(s)
    testing.expectf(t, err == c.err, "init: expected '%v', got '%v'", c.err, err)

    if err != .None {
      continue
    }

    expect_encode_decode(t, s, "alphabet", c.numbers)
  }
}

@(test)
test_blocklist :: proc(t: ^testing.T) {
  cases := []struct{
    name: string,
    blocklist: Maybe([]string),
    numbers: []uint,
    id: string,
  }{
    {
      name = "if no custom blocklist param, use the default blocklist",
      numbers = []uint{4572721},
      blocklist = nil,
      id = "JExTR",
    },
    {
      name = "if an empty blocklist param passed, don't use any blocklist",
      blocklist = []string{""},
      numbers = []uint{4572721},
      id = "aho1e",
    },
  }

  for c in cases {
    s, _ := init({ blocklist = c.blocklist })
    defer deinit(s)

    expect_encode(t, s, c.name, c.numbers, c.id)
  }

  {
    name := "if a non-empty blocklist param passed, use only that"
    s, _ := init({
      blocklist = []string{"ArUO"}, // originally encoded 100000
    })
    defer deinit(s)

    // make sure we don't use the default blocklist
    expect_decode(t, s, name, "aho1e", []uint{4572721})
    expect_encode(t, s, name, []uint{4572721}, "aho1e")

    // make sure we are using the passed blocklist
    expect_decode(t, s, name, "ArUO", []uint{100000})
    expect_encode(t, s, name, []uint{100000}, "QyG4")
    expect_decode(t, s, name, "QyG4", []uint{100000})
  }

  {
    name := "blocklist"
    s, _ := init({ blocklist = []string{
      "JSwXFaosAN", // normal result of 1st encoding, let's block that word on purpose
      "OCjV9JK64o", // result of 2nd encoding
      "rBHf",       // result of 3rd encoding is `4rBHfOiqd3`, let's block a substring
      "79SM",       // result of 4th encoding is `dyhgw479SM`, let's block the postfix
      "7tE6",       // result of 4th encoding is `7tE6jdAHLe`, let's block the prefix
    }})
    defer deinit(s)

    expect_encode(t, s, name, []uint{1_000_000, 2_000_000}, "1aYeB7bRUt")
    expect_decode(t, s, name, "1aYeB7bRUt", []uint{1_000_000, 2_000_000})
  }

  {
    name := "decoding blocklist words should still work"
    s, _ := init({ blocklist = []string{ "86Rf07", "se8ojk", "ARsz1p", "Q8AI49", "5sQRZO" }})
    defer deinit(s)

    expect_decode(t, s, name, "86Rf07", []uint{1, 2, 3})
    expect_decode(t, s, name, "se8ojk", []uint{1, 2, 3})
    expect_decode(t, s, name, "ARsz1p", []uint{1, 2, 3})
    expect_decode(t, s, name, "Q8AI49", []uint{1, 2, 3})
    expect_decode(t, s, name, "5sQRZO", []uint{1, 2, 3})
  }

  {
    name := "match against a short blocklist word"
    s, _ := init({ blocklist = []string{"pnd"}})
    defer deinit(s)

    expect_encode_decode(t, s, name, []uint{1000})
  }

  {
    name := "blocklist filtering in constructor"
    s, _ := init({ 
      alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
      blocklist = []string{"sxnzkl"},
    })
    defer deinit(s)

    expect_encode(t, s, name, []uint{1,2,3}, "IBSHOZ")
  }

  {
    name := "max encoding attempts"
    s, _ := init({ 
      alphabet = "abc",
      min_length = 3,
      blocklist = []string{"cab", "abc", "bca"},
    })
    defer deinit(s)

    testing.expectf(t, len(s.alphabet) == int(s.min_length), "%s: expected '%v', got '%v'", name, len(s.alphabet), s.min_length)

    _, err := encode(s, []uint{0})
    testing.expectf(t, err == .Reached_Max_Attempts, "%s: expected '%v', got '%v'", "Reached_Max_Attempts", err)
  }

  {
    name := "specific is_blocked_id scenarios"
    cases := []struct{
      blocklist: []string,
      numbers: []uint,
      id: string,
    }{
      { []string{"hey"},   []uint{100}, "86u" },
      { []string{"86u"},   []uint{100}, "sec" },
      { []string{"vFO"},   []uint{1_000_000}, "gMvFo" },
      { []string{"lP3i"},  []uint{100, 202, 303, 404}, "oDqljxrokxRt" },
      { []string{"1HkYs"}, []uint{100, 202, 303, 404}, "oDqljxrokxRt" },
      { []string{"0hfxX"}, []uint{101, 202, 303, 404, 505, 606, 707}, "862REt0hfxXVdsLG8vGWD" },
      { []string{"hfxX"},  []uint{101, 202, 303, 404, 505, 606, 707}, "seu8n1jO9C4KQQDxdOxsK" },
    }

    for c in cases {
      s, _ := init({ blocklist = c.blocklist })
      defer deinit(s)

      expect_encode(t, s, name, c.numbers, c.id)
    }
  }
}

@(test)
test_minlength :: proc(t: ^testing.T) {
  {
    name := "simple"
    s, _ := init({ min_length = auto_cast len(default_options.alphabet) })
    defer deinit(s)

    numbers := []uint{1, 2, 3}
    id := "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM"

    expect_encode(t, s, name, numbers, id)
    expect_decode(t, s, name, id, numbers)
  }

  {
    name := "incremental"
    alphabet_len: u8 = auto_cast len(default_options.alphabet)

    cases := []struct{
      min_length: u8,
      id: string,
    }{
      { 6, "86Rf07" },
      { 7, "86Rf07x" },
      { 8, "86Rf07xd" },
      { 9, "86Rf07xd4" },
      { 10, "86Rf07xd4z" },
      { 11, "86Rf07xd4zB" },
      { 12, "86Rf07xd4zBm" },
      { 13, "86Rf07xd4zBmi" },
      { alphabet_len+0, "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM" },
      { alphabet_len+1, "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMy" },
      { alphabet_len+2, "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf" },
      { alphabet_len+3, "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf1" },
    }

    numbers := []uint{1, 2, 3}

    for c in cases {
      s, _ := init({ min_length = c.min_length })
      defer deinit(s)

      expect_encode(t, s, name, numbers, c.id)
      expect_decode(t, s, name, c.id, numbers)
      testing.expectf(t, len(c.id) == auto_cast c.min_length, "%s: expected length %v, got %v", name, len(c.id), c.min_length)
    }
  }

  {
    name := "incremental numbers"
    s, _ := init({ min_length = auto_cast len(default_options.alphabet) })
    defer deinit(s)

    cases := []struct{
      id: string,
      numbers: []uint,
    }{
      { "SvIzsqYMyQwI3GWgJAe17URxX8V924Co0DaTZLtFjHriEn5bPhcSkfmvOslpBu", {0, 0} },
      { "n3qafPOLKdfHpuNw3M61r95svbeJGk7aAEgYn4WlSjXURmF8IDqZBy0CT2VxQc", {0, 1} },
      { "tryFJbWcFMiYPg8sASm51uIV93GXTnvRzyfLleh06CpodJD42B7OraKtkQNxUZ", {0, 2} },
      { "eg6ql0A3XmvPoCzMlB6DraNGcWSIy5VR8iYup2Qk4tjZFKe1hbwfgHdUTsnLqE", {0, 3} },
      { "rSCFlp0rB2inEljaRdxKt7FkIbODSf8wYgTsZM1HL9JzN35cyoqueUvVWCm4hX", {0, 4} },
      { "sR8xjC8WQkOwo74PnglH1YFdTI0eaf56RGVSitzbjuZ3shNUXBrqLxEJyAmKv2", {0, 5} },
      { "uY2MYFqCLpgx5XQcjdtZK286AwWV7IBGEfuS9yTmbJvkzoUPeYRHr4iDs3naN0", {0, 6} },
      { "74dID7X28VLQhBlnGmjZrec5wTA1fqpWtK4YkaoEIM9SRNiC3gUJH0OFvsPDdy", {0, 7} },
      { "30WXpesPhgKiEI5RHTY7xbB1GnytJvXOl2p0AcUjdF6waZDo9Qk8VLzMuWrqCS", {0, 8} },
      { "moxr3HqLAK0GsTND6jowfZz3SUx7cQ8aC54Pl1RbIvFXmEJuBMYVeW9yrdOtin", {0, 9} },
    }

    for c in cases {
      expect_encode(t, s, name, c.numbers, c.id)
      expect_decode(t, s, name, c.id, c.numbers)
    }
  }

  {
    name := "min lengths"

    cases := [][]uint{
			{0},
			{0, 0, 0, 0, 0},
			{1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			{100, 200, 300},
			{1_000, 2_000, 3_000},
			{1_000_000},
			//{Number.MAX_SAFE_INTEGER}
    }

    min_lengths := []uint{0, 1, 5, 10, len(default_options.alphabet)}

    for min_length in min_lengths {
      for c in cases {
        s, _ := init({ min_length = auto_cast min_length })
        defer deinit(s)

        id, _ := encode(s, c)
        defer delete(id)
        testing.expectf(t, len(id) >= auto_cast min_length, "%s: expected length %v, got %v", name, min_length, len(id))
      }
    }
  }
}

expect_decode :: proc(t: ^testing.T, s: Sqids, name: string, id: string, expected_nums: []uint, loc := #caller_location) {
  nums := decode(s, id)
  defer delete(nums)
  testing.expectf(t, slice.equal(nums, expected_nums), "%s: %v -> '%v', expected '%v'", name, nums, expected_nums, loc = loc)
}

expect_encode :: proc(t: ^testing.T, s: Sqids, name: string, nums: []uint, expected_id: string, loc := #caller_location) {
  id, err := encode(s, nums)
  defer delete(id)
  testing.expectf(t, err == .None, "%s: error '%v'", name, err)
  testing.expectf(t, expected_id == id, "%s: %v -> '%v', expected '%v'", name, nums, id, expected_id, loc = loc)
}

expect_encode_decode :: proc(t: ^testing.T, s: Sqids, name: string, nums: []uint, loc := #caller_location) {
  id, err := encode(s, nums)
  defer delete(id)
  testing.expectf(t, err == .None, "%s: error '%v'", name, err)

  new_nums := decode(s, id)
  defer delete(new_nums)
  testing.expectf(t, slice.equal(new_nums, nums), "%s: %v -> '%v', expected '%v'", name, new_nums, nums)
}
