#
# winners.coffee
# lotto-ionic
# v0.0.2
# Copyright 2016 Andreja Tonevski, https://github.com/atonevski/lotto-ionic
# For license information see LICENSE in the repository
#

angular.module 'app.winners', []

.controller 'Winners', ($scope, $http, $ionicLoading) ->
  query = """
    SELECT *
    WHERE 
      D > 0 OR J > 0
    ORDER BY B
  """

  $ionicLoading.show()
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.winners = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          year:   a[1].getFullYear()
          draw:   a[0]
          date:   a[1]

          lsales: a[2]
          lx7:    a[3]
          lx6p:   a[4]
          lx6:    a[5]
          lx5:    a[6]
          lx4:    a[7]
          lwcol:  a[15..22]
         
          jsales: a[8]
          jx6:    a[9]
          jx5:    a[10]
          jx4:    a[11]
          jx3:    a[12]
          jx2:    a[13]
          jx1:    a[14]

          jwcol:  a[23]
        }
      $ionicLoading.hide()
      console.log $scope.winners
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат добитниците. Пробај подоцна."
        duration: 3000
      })

.controller 'LottoWinners', ($scope, $http, $ionicLoading) ->
  query = """
    SELECT *
    WHERE 
      D > 0
    ORDER BY B
  """

  $ionicLoading.show()
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.winners = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          year:   a[1].getFullYear()
          draw:   a[0]
          date:   a[1]

          lsales: a[2]
          lx7:    a[3]
          lx6p:   a[4]
          lx6:    a[5]
          lx5:    a[6]
          lx4:    a[7]
          lwcol:  a[15..22]
         
          jsales: a[8]
          jx6:    a[9]
          jx5:    a[10]
          jx4:    a[11]
          jx3:    a[12]
          jx2:    a[13]
          jx1:    a[14]

          jwcol:  a[23]
        }
      $ionicLoading.hide()
      console.log $scope.winners
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат лото добитниците. Пробај подоцна."
        duration: 3000
      })

.controller 'JokerWinners', ($scope, $http, $ionicLoading) ->
  query = """
    SELECT *
    WHERE 
      J > 0
    ORDER BY B
  """

  $ionicLoading.show()
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.winners = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          year:   a[1].getFullYear()
          draw:   a[0]
          date:   a[1]

          lsales: a[2]
          lx7:    a[3]
          lx6p:   a[4]
          lx6:    a[5]
          lx5:    a[6]
          lx4:    a[7]
          lwcol:  a[15..22]
         
          jsales: a[8]
          jx6:    a[9]
          jx5:    a[10]
          jx4:    a[11]
          jx3:    a[12]
          jx2:    a[13]
          jx1:    a[14]

          jwcol:  a[23]
        }
      $ionicLoading.hide()
      console.log $scope.winners
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат џокер добитниците. Пробај подоцна."
        duration: 3000
      })
