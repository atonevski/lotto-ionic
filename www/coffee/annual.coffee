angular.module 'app.annual', []

.controller 'Annual', ($scope, $http, $ionicPopup, $timeout, $ionicLoading) ->
  # bar chart
  $scope.hideChart = true
  $scope.sbarChart = { }
  $scope.sbarChart.title  = 'Bar chart title'
  $scope.sbarChart.width  = $scope.width
  $scope.sbarChart.height = $scope.height
  
  query = """
    SELECT
      YEAR(B), COUNT(A), SUM(C), SUM(I), SUM(D)
    GROUP BY YEAR(B)
    ORDER BY YEAR(B)
  """
  $ionicLoading.show()
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.sales = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          year:     a[0]
          draws:    a[1]
          'лото':   a[2]
          'џокер':  a[3]
          x7:       a[4]
        }
      $scope.sbarChart.data   = $scope.sales
      $scope.sbarChart.labels = 'year'
      $scope.sbarChart.categories = ['лото', 'џокер']
      $ionicLoading.hide()
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат годишните податоци. Пробај подоцна."
        duration: 3000
      })


