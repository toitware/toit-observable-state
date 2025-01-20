// Copyright (C) 2025 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be found
// in the LICENSE file.

import .client as client
import system.services show ServiceClient ServiceSelector

interface ObservableStateService:
  listen handle/int -> none
  static LISTEN-INDEX ::= 100_000_000  // Avoid conflicts with other methods.

abstract class ObservableStateServiceClient extends ServiceClient
    implements ObservableStateService:
  constructor selector/ServiceSelector:
    super selector

  listen state/client.ObservableState -> none:
    invoke_ ObservableStateService.LISTEN-INDEX state.handle_
