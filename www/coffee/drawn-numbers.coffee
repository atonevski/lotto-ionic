#
# drawn-numbers.coffee
# lotto-ionic
# v0.0.2
# Copyright 2016 Andreja Tonevski, https://github.com/atonevski/lotto-ionic
# For license information see LICENSE in the repository
#

angular.module 'app.drawn.numbers', []

.controller 'LottoDrawnNumbers', ($scope, $http, $ionicLoading) ->
  query = """
    SELECT A, B, P, Q, R, S, T, U, V, W
    ORDER BY B DESC
    LIMIT #{ $scope.LIMIT_DRAWS }
  """
  $ionicLoading.show()
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.numbers = res.table.rows.map (r) ->
        a = $scope.eval_row r
        sorted = a[2..8].sort((a, b)-> +a - +b)
        sorted.push a[9]
        {
          draw:   a[0]
          date:   a[1]
          column: a[2..9]
          sorted: sorted
        }
      # console.log 'last drawn numbers: ', $scope.numbers
      $ionicLoading.hide()
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат последните добитни комбинации. Пробај подоцна."
        duration: 3000
      })
