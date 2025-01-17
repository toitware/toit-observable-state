// Copyright (C) 2025 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/LICENSE file.

import expect show *
import .shared

// TODO(kasper):
//  - test cross process
//  - test multiple clients for same state
//  - test multiple states
//  - test with map, list, bool, double values
main:
  provider := TestServiceProvider
  provider.state["fisk"] = "hest"
  provider.install
  client := TestClient
  client.open

  state := client.get-state
  expect-equals "hest" state["fisk"]
  expect-list-equals [] state.changes

  provider.state["kurt"] = "hat"
  expect-equals "hest" state["fisk"]
  expect-equals "hat" state["kurt"]
  expect-list-equals [["kurt", null, "hat"]] state.changes

  provider.state["fisk"] = "gris"
  expect-equals "gris" state["fisk"]
  expect-equals "hat" state["kurt"]
  expect-list-equals [["fisk", "hest", "gris"]] state.changes

  provider.state["fisk"] = "gris"  // Not an update.
  provider.state["kurt"] = 42
  provider.state["fisk"] = 87
  expect-list-equals [["kurt", "hat", 42], ["fisk", "gris", 87]] state.changes

  provider.state["fisk"] = null
  expect-list-equals [["fisk", 87, null]] state.changes

  client.close
  provider.uninstall --wait
