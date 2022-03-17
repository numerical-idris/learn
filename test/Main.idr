{--
Copyright 2022 Joel Berkeley

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
module Main

import Unit.Model.TestKernel
import Unit.TestDistribution
import Unit.TestTensor
import Unit.TestUtil
import Unit.TestXLA

import Utils

main : IO ()
main = do
  Unit.Model.TestKernel.test
  Unit.TestDistribution.test
  Unit.TestTensor.test
  Unit.TestUtil.test
  Unit.TestXLA.test

  Utils.test

  putStrLn "Tests passed"
