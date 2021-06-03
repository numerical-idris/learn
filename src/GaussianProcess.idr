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
||| This module contains the `GaussianProcess` type for defining Gaussian process, along with
||| functionality for training and inference.
module GaussianProcess

import Tensor
import Data.Vect
import Kernel
import MeanFunction
import Optimize
import Distribution
import Util

||| A Gaussian process is a collection of random variables, any finite number of which have joint
||| Gaussian distribution. It can be viewed as a function from a feature space to a joint Gaussian
||| distribution over a target space.
public export
data GaussianProcess : (0 features : Shape) -> Type where
  ||| Construct a `GaussianProcess` as a pair of mean function and kernel.
  MkGP : MeanFunction features -> Kernel features -> GaussianProcess features

-- todo implement for no training data
-- todo we don't use the likelihood mean
||| The posterior Gaussian process conditioned on the specified `training_data`.
|||
||| @prior The prior belief.
||| @likelihood The likelihood of the observations given the prior target distribution. Here this is
|||   simply the noise variance. The mean is unused.
||| @training_data The observed feature and corresponding target values.
export
posterior : {s : Nat}
 -> (prior : GaussianProcess features)
 -> (likelihood : Gaussian [] (S s))
 -> (training_data : (Tensor ((S s) :: features) Double, Tensor [S s] Double))
 -> Maybe $ GaussianProcess features
posterior (MkGP mean_function kernel) (MkGaussian _ cov) (x_train, y_train) =
  map foo $ inverse (kernel x_train x_train + cov) where
    foo : Tensor [S s, S s] Double -> GaussianProcess features
    foo inv = MkGP posterior_mean_function posterior_kernel where
      posterior_mean_function : MeanFunction features
      -- todo can we use rewrite to avoid the use of implicits here and for posterior_kernel?
      posterior_mean_function {sm} x =
        mean_function x + (@@) {head=[_]} ((@@) {head=[_]} (kernel x x_train) inv) y_train

      posterior_kernel : Kernel features
      posterior_kernel x x' =
        kernel x x' - (@@) {head=[_]} ((@@) {head=[_]} (kernel x x_train) inv) (kernel x_train x')

||| The marginal distribution of the Gaussian process at the specified feature values.
|||
||| @at The feature values at which to evaluate the marginal distribution.
export
marginalise : {samples : Nat}
  -> GaussianProcess features
  -> Tensor (samples :: features) Double
  -> Gaussian [] samples
marginalise (MkGP mean_function kernel) x = MkGaussian (mean_function x) (kernel x x)

log_marginal_likelihood : {samples : Nat}
 -> GaussianProcess features
 -> Gaussian [] (S samples)
 -> (Tensor ((S samples) :: features) Double, Tensor [S samples] Double)
 -> Maybe $ Tensor [] Double
log_marginal_likelihood (MkGP _ kernel) (MkGaussian _ cov) (x, y) =
  map foo $ inverse (kernel x x + cov) where
    foo : Tensor [S samples, S samples] Double -> Tensor [] Double
    foo inv = let n = the (Tensor [] _) $ const $ the Double $ cast samples
                  log2pi = the (Tensor [] _) $ log $ const $ 2.0 * PI
                  half = the (Tensor [] _) $ const $ 1.0 / 2
               in - half * ((@@) {head=[]} ((@@) {head=[]} y inv) y - log (det inv) + n * log2pi)

||| Find the hyperparameter values that optimize the log marginal likelihood of the `data` for the
||| prior (as constructed from `prior_from_parameters`) and `likelihood`. Optimization is defined
||| according to `optimizer`. For maximum likelihood estimation, it should (at least approximately)
||| maximize its objective.
|||
||| @optimizer Implements the optimization tactic.
||| @prior_from_parameters Constructs the prior from the hyperparameters
||| @likelihood The likelihood of the observations given the prior target distribution.
||| @data_ The data.
export
optimize : {samples : Nat}
 -> (optimizer : Optimizer hp)
 -> (prior_from_parameters : hp -> GaussianProcess features)
 -> (likelihood : Gaussian [] (S samples))
 -> (data_ : (Tensor ((S samples) :: features) Double, Tensor [S samples] Double))
 -> Maybe hp
optimize optimizer gp_from_hyperparameters likelihood training_data = optimizer objective where
  objective : hp -> Maybe $ Tensor [] Double
  objective hp' = log_marginal_likelihood (gp_from_hyperparameters hp') likelihood training_data
