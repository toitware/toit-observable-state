// Copyright (C) 2025 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be found
// in the LICENSE file.

import .api as api
import encoding.tison
import system.services show ServiceHandler ServiceProvider ServiceResource

class ObservableState:
  raw_/Map := {:}
  encoded_/Map := {:}
  resources_/Set := {}

  size -> int:
    return raw_.size

  operator[] key/string -> any:
    return raw_.get key --if-absent=: throw "key '$key' not found"

  get key/string -> any:
    return raw_.get key --if-absent=: null

  get key/string [--if-absent] -> any:
    return raw_.get key --if-absent=if-absent

  operator[]= key/string value/any -> none:
    // We encode the value as tison to eagerly check if it
    // can be serialized before we store it in the maps.
    // This also allows us to filter out updates that do not
    // change the stored value.
    encoded := tison.encode value
    if (encoded_.get key) == encoded: return
    if value == null:
      raw_.remove key
      encoded_.remove key
    else:
      raw_[key] = value
      encoded_[key] = encoded
    resources_.do: | resource/ObservableStateResource |
      resource.notify_ [key, value]

  remove key/string -> none:
    this[key] = null

  do [block] -> none:
    raw_.do block

  stringify -> string:
    return raw_.stringify

  register-resource_ resource/ObservableStateResource -> Map:
    resources_.add resource
    return raw_

  unregister-resource_ resource/ObservableStateResource -> none:
    resources_.remove resource

abstract class ObservableStateServiceProviderBase extends ServiceProvider
    implements ServiceHandler api.ObservableStateService:
  constructor name/string --major/int --minor/int --patch/int=0 --tags/List?=null:
    super name --major=major --minor=minor --patch=patch --tags=tags

  handle index/int arguments/any --gid/int --client/int -> any:
    if index == api.ObservableStateService.LISTEN-INDEX:
      resource := (resource client arguments) as ObservableStateResource
      return listen resource
    unreachable

  listen resource/ObservableStateResource -> none:
    resource.listen

class ObservableStateResource extends ServiceResource:
  hash-code/int ::= hash-code-compute_
  state_/ObservableState

  constructor .state_ provider/ObservableStateServiceProviderBase client/int:
    super provider client --notifiable

  listen -> none:
    // Send the initially observed state to the client.
    notify_ (state_.register-resource_ this)

  on-closed -> none:
    state_.unregister-resource_ this

  static hash-code-next_ := 0
  static hash-code-compute_ -> int:
    result := hash-code-next_
    hash-code-next_ = (result + 1) & 0x3fff_ffff
    return result
