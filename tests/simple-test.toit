// Copyright (C) 2025 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/LICENSE file.

import observable-state.service show ObservableState
import expect show *
import .shared

// TODO(kasper):
//  - test cross process
main:
  test-working
  test-non-working

test-working:
  provider := TestServiceProvider {
    "one": ObservableState,
    "two": ObservableState
  }
  provider.states["one"]["fisk"] = "hest"
  provider.install

  client-one := TestClient
  client-one.open
  client-one-extra := TestClient
  client-one-extra.open
  client-two := TestClient
  client-two.open

  one := client-one.get-state "one"
  one-extra := client-one-extra.get-state "one"
  two := client-two.get-state "two"

  expect-equals "hest" one["fisk"]
  expect-list-equals [] one.changes

  provider.states["one"]["kurt"] = "hat"
  expect-equals "hest" one["fisk"]
  expect-equals "hat" one["kurt"]
  expect-list-equals [["kurt", null, "hat"]] one.changes

  provider.states["one"]["fisk"] = "gris"
  expect-equals "gris" one["fisk"]
  expect-equals "hat" one["kurt"]
  expect-list-equals [["fisk", "hest", "gris"]] one.changes

  provider.states["one"]["fisk"] = "gris"  // Not an update.
  provider.states["one"]["kurt"] = 42
  provider.states["one"]["fisk"] = 87
  expect-list-equals [["kurt", "hat", 42], ["fisk", "gris", 87]] one.changes

  provider.states["one"]["fisk"] = null
  expect-list-equals [["fisk", 87, null]] one.changes

  provider.states["two"]["hund"] = true
  expect one.changes.is-empty
  expect-list-equals [["hund", null, true]] two.changes

  // Check that the extra client also got all the changes.
  expect-equals 5 one-extra.changes.size

  // Check more complex values.
  previous := null
  [ 0, 1, -18, 0.123, -42.17, true, false, null, [1, 2, 3], {"kurt": 17}].do: | value |
    provider.states["two"]["fun"] = value
    expect-list-equals [["fun", previous, value]] two.changes
    previous = value

  client-one.close
  client-one-extra.close
  client-two.close

  provider.uninstall --wait

test-non-working:
  state := ObservableState
  expect-throw "AS_CHECK_FAILED": state[42 as any]
  expect-throw "SERIALIZATION_FAILED": state["42"] = state
