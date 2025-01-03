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
||| Kernel functions, as used in Gaussian processes.
module Model.Kernel

import Tensor
import Data.Nat

||| A `Kernel` function maps pairs of points in a feature space to the covariance between those two
||| points in some target space.
|||
||| @features The shape of the feature domain.
public export 0
Kernel : (0 features : Shape) -> Type
Kernel features =
  {sk, sk' : _} ->
  Tensor (sk :: features) F64 ->
  Tensor (sk' :: features) F64 ->
  Tag $ Tensor [sk, sk'] F64

scaledL2Norm :
  Tensor [] F64 ->
  {d, n, n' : _} ->
  Tensor [n, S d] F64 ->
  Tensor [n', S d] F64 ->
  Tag $ Tensor [n, n'] F64
scaledL2Norm len x x' =
  let xs = broadcast {to = [n, n', S d]} $ expand 1 x
   in reduce @{Sum} [2] $ ((xs - broadcast (expand 0 x')) / len) ^ fill 2.0

||| The radial basis function, or squared exponential kernel. This is a stationary kernel with form
|||
||| (\mathbf x_i, \mathbf x_j) \mapsto \exp \left(- \frac{r^2}{2l^2} \right)
|||
||| where `r^2 = (\mathbf x_i - \mathbf x_j)^ \intercal (\mathbf x_i - \mathbf x_j)` and the
||| length scale `l > 0`.
|||
||| Two points that are close in feature space will be more tightly correlated than points that
||| are further apart. The distance over which the correlation reduces is given by the length
||| scale `l`. Smaller length scales result in faster-varying target values.
|||
||| @lengthScale The length scale `l`.
export
rbf : (lengthScale : Tensor [] F64) -> {d : _} -> Kernel [S d]
rbf lengthScale x x' = pure $ exp (- !(scaledL2Norm lengthScale x x') / 2.0)

||| The Matern kernel for parameter 5/2. This is a stationary kernel with form
|||
||| (\mathbf x_i, \mathbf x_j) \mapsto \sigma^2 \left(
|||   1 + \frac{\sqrt{5}r}{l} + \frac{5 r^2}{3 l^2}
||| \right) \exp \left( -\frac{\sqrt{5}r}{l} \right)
|||
||| where `r^2 = (\mathbf x_i - \mathbf x_j)^ \intercal (\mathbf x_i - \mathbf x_j)` and the
||| length scale `l > 0`.
|||
||| @amplitude The amplitude `\sigma`.
||| @length_scale The length scale `l`.
export
matern52 :
  (amplitude : Tensor [] F64) -> (length_scale : Tensor [] F64) -> {d : _} -> Kernel [S d]
matern52 amp len x x' = do
  d2 <- tag $ 5.0 * !(scaledL2Norm len x x')
  d <- tag $ d2 ^ fill 0.5
  pure $ (amp ^ 2.0) * (d2 / 3.0 + d + fill 1.0) * exp (- d)
