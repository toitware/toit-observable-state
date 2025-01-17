// Copyright (C) 2025 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be found
// in the LICENSE file.

import .api as api
import encoding.tison
import monitor
import system.services show ServiceResourceProxy

class ObservableState extends ServiceResourceProxy:
  latch_/monitor.Latch? := ?
  state_/Map? := null

  constructor client/api.ObservableStateServiceClient handle/int:
    latch_ = monitor.Latch
    super client handle
    (client_ as api.ObservableStateServiceClient).listen this
    state_ = latch_.get
    latch_ = null

  size -> int:
    return state_.size

  operator[] key/string -> any:
    return state_.get key --if-absent=: throw "key '$key' not found"

  get key/string -> any:
    return state_.get key --if-absent=: null

  get key/string [--if-absent] -> any:
    return state_.get key --if-absent=if-absent

  do [block] -> none:
    state_.do block

  stringify -> string:
    return state_.stringify

  on-notified_ notification/any -> none:
    if notification is Map:
      latch_.set notification.copy
    else:
      key := notification[0]
      new := notification[1]
      old := null
      state_.update key --if-absent=(: new):
        old = it  // Capture the old value.
        new
      on-changed key --old=old --new=new

  on-changed key/string --old/any --new/any -> none:
    // Override in subclasses.
