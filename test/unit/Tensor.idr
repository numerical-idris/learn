{--
Copyright 2021 Joel Berkeley

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--}
import Data.Vect                                                                                     
import Tensor                                                                                        
                                                                                                     
test_can_broadcast : List (from ** to ** Broadcastable from to)

test_can_broadcast_scalar : Broadcastable [] []
test_can_broadcast_scalar = Same

test_can_broadcast_scalar_to_any : Broadcastable [] [3, 2, 5]
test_can_broadcast_scalar_to_any = Stack $ Nest $ Stack $ Nest $ Stack $ Nest Same

test_cannot_broadcast_any_to_scalar : Broadcastable [3, 2, 5] [] -> Void
test_cannot_broadcast_any_to_scalar _ impossible

test_can_broadcast_to_itself : Broadcastable [3, 2, 5] [3, 2, 5]
test_can_broadcast_to_itself = Same

test_can_stack_inner_1 : Broadcastable [3, 1, 5] [3, 7, 5]
test_can_stack_inner_1 = Extend [1, 5] [7, 5] (Stack Same)

test_cannot_stack_greater_than_one : Broadcastable [3, 2] [3, 7] -> Void
test_cannot_stack_greater_than_one (Stack (Nest (Stack (Nest Same)))) impossible
test_cannot_stack_greater_than_one (Stack (Nest (Stack (Nest (Stack _))))) impossible
test_cannot_stack_greater_than_one (Stack (Nest (Stack (Nest (Extend _ _ _))))) impossible
test_cannot_stack_greater_than_one (Stack (Nest (Stack (Nest (Nest _))))) impossible
test_cannot_stack_greater_than_one (Extend [2] [7] (Stack (Nest Same))) impossible
test_cannot_stack_greater_than_one (Extend [2] [7] (Stack (Nest (Stack _)))) impossible
test_cannot_stack_greater_than_one (Extend [2] [7] (Stack (Nest (Extend _ _ _)))) impossible
test_cannot_stack_greater_than_one (Extend [2] [7] (Stack (Nest (Nest _)))) impossible

test_can_nest : Broadcastable [3, 2, 5] [1, 3, 2, 5]
test_can_nest = Nest Same