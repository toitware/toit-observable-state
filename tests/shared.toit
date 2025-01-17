// Copyright (C) 2025 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/LICENSE file.

import expect show *
import observable-state.client
import observable-state.service
import observable-state.api

import system.services show ServiceClient ServiceProvider ServiceSelector

interface TestService extends api.ObservableStateService:
  static SELECTOR ::= ServiceSelector
      --uuid="7a8c3796-fc70-4640-8141-976a4d2011ef"
      --major=1
      --minor=0

  get-state -> int
  static GET-STATE-INDEX ::= 0

class TestServiceProvider extends service.ObservableStateServiceProviderBase:
  state/service.ObservableState ::= service.ObservableState

  constructor:
    super "observable-state/test-service" --major=1 --minor=2
    provides TestService.SELECTOR --handler=this

  handle index/int arguments/any --gid/int --client/int -> any:
    if index == TestService.GET-STATE-INDEX:
      return get-state --client=client
    return super index arguments --gid=gid --client=client

  get-state -> int:  // Satisfy checker.
    unreachable

  get-state --client/int -> service.ObservableStateResource:
    return service.ObservableStateResource state this client

class TestClient extends api.ObservableStateServiceClient implements TestService:
  static SELECTOR ::= TestService.SELECTOR
  constructor selector/ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  get-state -> TestState:
    handle := invoke_ TestService.GET-STATE-INDEX null
    return TestState this handle

class TestState extends client.ObservableState:
  changes_/List := []

  constructor client/TestClient handle/int:
    super client handle

  changes -> List:
    result := changes_
    changes_ = []
    return result

  on-changed key/string --old/any --new/any -> none:
    changes_.add [key, old, new]
