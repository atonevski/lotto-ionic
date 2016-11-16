angular.module 'app.stats', []

.controller 'LottoStats', ($scope, $http, $ionicLoading) ->
  $scope.hideChart = true
  $scope.sbarChart = { }
  $scope.sbarChart.title  = 'Bar chart title'
  $scope.sbarChart.width  = $scope.width
  $scope.sbarChart.height = $scope.height

  # A: draw #, B: date, P..W: winning column lotto, X: winning column joker
  query = """SELECT A, B, P, Q, R, S, T, U, V, W
             ORDER BY B"""
  $ionicLoading.show()
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.winColumns = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          draw:   a[0]
          date:   a[1]
          lotto:  [ a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9] ]
        }
      $buildLottoFreqs()
      $ionicLoading.hide()
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат добитните комбинации. Пробај подоцна."
        duration: 3000
      })

  # change this method to have a parameter 'all', 'stresa', 'venus'
  # and to produce different tables
  $buildLottoFreqs = () ->
    arr = [0..34].map (e) -> ([0..7].map () -> 0)
    for row in $scope.winColumns
      for i, n of row.lotto
        arr[n][i]++
    for i, a of arr
      arr[i].push a.reduce (t, e) -> t + e
    $scope.freqs = arr[1..-1].map (a, i) ->
        {
          number: (i + 1)
          '1ви':  a[0]
          '2ри':  a[1]
          '3ти':  a[2]
          '4ти':  a[3]
          '5ти':  a[4]
          '6ти':  a[5]
          '7ми':  a[6]
          'доп.': a[7]
          total:  a[8]
        }
    $scope.sbarChart.data   = $scope.freqs
    $scope.sbarChart.labels = 'number'
    $scope.sbarChart.labVals = [1..34].filter (v) -> v%2 isnt 0
    $scope.sbarChart.categories = [
      '1ви', '2ри', '3ти', '4ти', '5ти', '6ти', '7ми', 'доп.'
    ]

.controller 'JokerStats', ($scope, $http, $ionicLoading) ->
  $scope.hideChart = true
  $scope.sbarChart = { }
  $scope.sbarChart.title  = 'Bar chart title'
  $scope.sbarChart.width  = $scope.width
  $scope.sbarChart.height = $scope.height

  # A: draw #, B: date, P..W: winning column lotto, X: winning column joker
  query = """SELECT A, B, X
             ORDER BY B"""
  $ionicLoading.show()
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.winColumns = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          draw:   a[0]
          date:   a[1]
          joker:  a[2].split ''
        }
      $buildJokerFreqs()
      $ionicLoading.hide()
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат добитните комбинации. Пробај подоцна."
        duration: 3000
      })

  # change this method to have a parameter 'all', 'stresa', 'venus'
  # and to produce different tables
  $buildJokerFreqs = () ->
    arr = [0..9].map (e) -> ([0..5].map () -> 0)
    for row in $scope.winColumns
      for i, n of row.joker
        arr[n][i]++
    for i, a of arr
      arr[i].push a.reduce (t, e) -> t + e
    $scope.freqs = arr.map (a, i) ->
        {
          number: i
          '1ви':  a[0]
          '2ри':  a[1]
          '3ти':  a[2]
          '4ти':  a[3]
          '5ти':  a[4]
          '6ти':  a[5]
          total:  a[6]
        }
    $scope.sbarChart.data   = $scope.freqs
    $scope.sbarChart.labels = 'number'
    # $scope.sbarChart.labVals = [1..34].filter (v) -> v%2 isnt 0
    $scope.sbarChart.categories = [
      '1ви', '2ри', '3ти', '4ти', '5ти', '6ти' ]

.controller 'WinnersStats', ($scope, $http, $ionicLoading, $ionicPosition, $ionicScrollDelegate) ->
  $scope.bubbleVisible = no
  $scope.bubble = d3.select '#stats-list'
                    .append 'div'
                    .attr 'class', 'bubble bubble-left'
                    .attr 'id', 'winners-bubble'
                    .on('click', ()->
                      $scope.bubble.transition().duration 1000
                            .style 'opacity', 0
                      $scope.bubbleVisible = no
                    )
                    .style 'opacity', 0

  $scope.showBubble = (event, idx) ->

    return if $scope.bubbleVisible
    event.stopPropagation()
    $scope.bubbleVisible = yes

    t = """
      <div class='row row-no-padding'>
        <div class='col col-offset-80 text-right positive'>
          <small><i class='ion-close-round'></i></small>
        </div>
      </div>
      <dl class='dl-horizontal'>
        <dt>Година:</dt>
        <dd>#{ $scope.winners[idx].year }</dd>
        <dt>Вкупно кола:</dt>
        <dd>#{ $scope.winners[idx].draws }</dd>
        <hr />
        <dt>Лото:</dt><dd></dd>
        <hr />
        <dt>Најмала уплата:</dt>
        <dd>#{ $scope.thou_sep $scope.winners[idx].min }</dd>
        <dt>Просечна уплата:</dt>
        <dd>#{ $scope.thou_sep $scope.winners[idx].avg }</dd>
        <dt>Најголема уплата:</dt>
        <dd>#{ $scope.thou_sep $scope.winners[idx].max }</dd>
        <hr />
        <dt>Џокер:</dt><dd></dd>
        <hr />
        <dt>Најмала уплата:</dt>
        <dd>#{ $scope.thou_sep $scope.winners[idx].jmin }</dd>
        <dt>Просечна уплата:</dt>
        <dd>#{ $scope.thou_sep $scope.winners[idx].javg }</dd>
        <dt>Најголема уплата:</dt>
        <dd>#{ $scope.thou_sep $scope.winners[idx].jmax }</dd>
      </dl>
    """

    el = angular.element document.querySelector "\#winners-#{$scope.winners[idx].year}"
    offset = $ionicPosition.offset el
    new_top = offset.top + $ionicScrollDelegate.getScrollPosition().top
    $scope.bubble.html t
          .style 'left', (event.pageX + 10) + 'px'
          .style 'top', (new_top - 60) + 'px'
          .style 'opacity', 1
    

  # load data
  $ionicLoading.show()
  # count x7
  qx7 = """
      SELECT
        YEAR(B), COUNT(D)
      WHERE D > 0
      GROUP BY YEAR(B)
      ORDER BY YEAR(B)
    """
  $http.get $scope.qurl(qx7)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.winX7 = { }
      res.table.rows.forEach (r) ->
        a = $scope.eval_row r
        $scope.winX7[a[0]] = a[1]
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат добитници x7. Пробај подоцна."
        duration: 3000
      })

  # count x6p
  qx6p= """
      SELECT
        YEAR(B), COUNT(E)
      WHERE E > 0
      GROUP BY YEAR(B)
      ORDER BY YEAR(B)
    """
  $http.get $scope.qurl(qx6p)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.winX6p = { }
      res.table.rows.forEach (r) ->
        a = $scope.eval_row r
        $scope.winX6p[a[0]] = a[1]
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат добитници x6+1. Пробај подоцна."
        duration: 3000
      })

  # count x6
  qx6 = """
      SELECT
        YEAR(B), COUNT(F)
      WHERE F > 0
      GROUP BY YEAR(B)
      ORDER BY YEAR(B)
    """
  $http.get $scope.qurl(qx6)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.winX6 = { }
      res.table.rows.forEach (r) ->
        a = $scope.eval_row r
        $scope.winX6[a[0]] = a[1]
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат добитници x6. Пробај подоцна."
        duration: 3000
      })

  # A: draw #, B: date, P..W: winning column lotto, X: winning column joker
  query = """
      SELECT 
        YEAR(B), COUNT(A), MIN(C), MAX(C), AVG(C),
        SUM(D), SUM(E), AVG(F), AVG(G), AVG(H),
        MIN(I), MAX(I), AVG(I)
      GROUP BY YEAR(B)
      ORDER BY YEAR(B)
    """
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.winners = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          year:   a[0]
          draws:  a[1]

          min:    a[2]
          max:    a[3]
          avg:    Math.round a[4]
          jmin:   a[10]
          jmax:   a[11]
          javg:   Math.round a[12]

          x7:     a[5]
          'x6+1': a[6]
          x6:     Math.round a[7]
          x5:     Math.round a[8]
          x4:     Math.round a[9]
        }
      $ionicLoading.hide()
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчита статистика на добитници. Пробај подоцна."
        duration: 3000
      })
