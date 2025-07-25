package sqids

import "core:strings"
import "core:slice"

@(private)
default_options: Options = {
  alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
  min_length = 0,
  blocklist = default_blocklist[:],
}

Blocklist :: distinct map[string]bool

Options :: struct {
  alphabet: string,
  min_length: u8,
  blocklist: Maybe([]string),
}

Sqids :: struct {
  alphabet: []u8,
  min_length: u8,
  blocklist: Blocklist,
}

Error :: enum {
  None = 0,
  Alphabet_Too_Short,
  Alphabet_Repeating_Character,
  Invalid_Multibyte_Character,
  Reached_Max_Attempts,
}

init :: proc(opts := Options{}, allocator := context.allocator) -> (Sqids, Error) {
  alphabet := default_options.alphabet if opts.alphabet == "" else opts.alphabet
  min_length := default_options.min_length if opts.min_length == 0 else opts.min_length
  blocklist: []string
  if bl, ok := opts.blocklist.?; ok {
    blocklist = bl
  } else {
    blocklist = default_blocklist[:]
  }

  if strings.rune_count(alphabet) != len(alphabet) {
    return {}, .Invalid_Multibyte_Character
  }

  if len(alphabet) < 3 {
    return {}, .Alphabet_Too_Short
  }

  alphabet_set := make(map[rune]struct{}, len(alphabet), context.temp_allocator)
  for c in alphabet {
    alphabet_set[c] = {}
  }

  if len(alphabet_set) != len(alphabet) {
    return {}, .Alphabet_Repeating_Character
  }

  filtered_blocklist := create_filtered_blocklist(alphabet, blocklist[:], allocator)

  alphabet_u8 := make([]u8, len(alphabet), allocator)
  for c, i in alphabet {
    alphabet_u8[i] = u8(c)
  }

  shuffle(alphabet_u8)

  return {
    min_length = min_length,
    alphabet = alphabet_u8,
    blocklist = filtered_blocklist,
  }, .None
}

deinit :: proc(s: Sqids) {
  delete(s.alphabet)
  delete(s.blocklist)
}

encode :: proc(s: Sqids, numbers: []uint, allocator := context.allocator) -> (string, Error) {
  if len(numbers) == 0 { return "", .None }

  return encode_numbers(s, numbers, 0, allocator)
}

encode_numbers :: proc(s: Sqids, numbers: []uint, increment := 0, allocator := context.allocator) -> (string, Error) {
  if increment > len(s.alphabet) {
    return "", .Reached_Max_Attempts
  }

  alphabet := slice.clone(s.alphabet, context.temp_allocator)

  offset := len(numbers)
  for n, i in numbers {
    offset += i
    offset += int(alphabet[n % len(alphabet)])
  }

  offset %= len(alphabet)
  offset = (offset + increment) % len(alphabet)

  slice.reverse(alphabet[:offset])
  slice.reverse(alphabet[offset:])
  slice.reverse(alphabet)
  prefix := alphabet[0]
  slice.reverse(alphabet)

  ret: [dynamic]u8
  defer delete(ret)

  append(&ret, prefix)
  for n, i in numbers {
    x := to_id(alphabet[1:], n, context.temp_allocator)
    append_elems(&ret, ..x)

    if i < len(numbers)-1 {
      append(&ret, alphabet[0])
      shuffle(alphabet)
    }
  }

  min_length := int(s.min_length)
  if min_length > len(ret) {
      append(&ret, alphabet[0])
      for min_length > len(ret) {
        shuffle(alphabet)
        n := min(min_length - len(ret), len(alphabet))
        append_elems(&ret, ..alphabet[0:n])
      }
  }

  id := strings.clone_from_bytes(ret[:], allocator)

  if is_blocked_id(s, id) {
    delete(id, allocator)
    return encode_numbers(s, numbers, increment+1, allocator)
  }

  return id, .None
}

decode :: proc(s: Sqids, input_id: string, allocator := context.allocator) -> []uint {
  if len(input_id) == 0 { return []uint{} }

  // we have a multibyte char in the id
  if strings.rune_count(input_id) != len(input_id) {
    return []uint{}
  }

  alphabet := slice.clone(s.alphabet, context.temp_allocator)
  id_u8 := make([]u8, len(input_id), context.temp_allocator)

  for c, i in input_id {
     id_u8[i] = u8(c)
  }

  for c in id_u8 {
     _, found := slice.linear_search(s.alphabet, c)
     if !found {
       return []uint{}
     }
  }

  prefix := id_u8[0]
  id := id_u8[1:]

  offset, _ := slice.linear_search(s.alphabet, prefix)

  slice.reverse(alphabet[:offset])
  slice.reverse(alphabet[offset:])

  ret := make([dynamic]uint, 0, allocator)

  for len(id) > 0 {
    separator := alphabet[0]

    index := slice.linear_search(id, separator) or_else len(id)
    left := id[0:index]
    right := index == len(id) ? []u8{} : id[index+1:]

    if len(left) == 0 {
      return ret[:]
    }

    append(&ret, to_number(alphabet[1:], left))

    if len(right) > 0 {
      shuffle(alphabet)
    }

    id = right
  }

  return ret[:]
}

shuffle :: proc(alphabet: []u8) {
  n := len(alphabet)
  i: int = 0
  j: int = n-1

  for j > 0 {
    r := (i * j + int(alphabet[i]) + int(alphabet[j])) % n
    alphabet[r], alphabet[i] = alphabet[i], alphabet[r]
    i += 1
    j -= 1
  }
}

to_id :: proc(alphabet: []u8, number: uint, allocator := context.allocator) -> []u8 {
  res := number
  id := make([dynamic]u8, 0, allocator)

  for {
    append(&id, alphabet[res % len(alphabet)])
    res = res / len(alphabet)
    if res == 0 { break }
  }

  value := id[:]
  slice.reverse(value)
  return value
}

to_number :: proc(alphabet: []u8, s: []u8) -> uint {
  num: uint = 0

  for c in s {
    if index, ok : = slice.linear_search(alphabet, c); ok {
      num = num * len(alphabet) + uint(index)
    }
  }

  return num
}

create_filtered_blocklist :: proc(alphabet: string, blocklist: []string, allocator := context.allocator) -> Blocklist {
  ret := make(Blocklist, allocator)

  lcalphabet := strings.to_lower(alphabet, context.temp_allocator)

  for word in blocklist {
    if len(word) < 3 { continue }

    lcword := strings.to_lower(word, context.temp_allocator)

    for c in lcword {
      if !strings.contains_rune(lcalphabet, c) {
        continue
      }
    }

    ret[lcword] = contains_number(lcword)
  }

  return ret
}

is_blocked_id :: proc(s: Sqids, id: string, allocator := context.allocator) -> bool {
  lower_id := strings.to_lower(id, context.temp_allocator)

  for word, has_number in s.blocklist {
    if len(word) > len(lower_id) {
      continue
    }

    if len(word) <= 3 || len(lower_id) <= 3 {
      if lower_id == word {
        return true
      }
    } else if has_number {
      if strings.starts_with(lower_id, word) || strings.ends_with(lower_id, word) {
        return true
      }
    } else if strings.contains(lower_id, word) {
      return true
    }
  }

  return false
}

contains_number :: proc(str: string) -> bool {
  for c in str {
    if c >= '0' && c <= '9' {
      return true
    }
  }

  return false
}
