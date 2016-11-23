#
# weekly.coffee
# lotto-ionic
# v0.0.2
# Copyright 2016 Andreja Tonevski, https://github.com/atonevski/lotto-ionic
# For license information see LICENSE in the repository
#

angular.module 'app.weekly', []

.controller 'Weekly', ($scope, $http, $stateParams, $timeout
, $ionicLoading, $ionicPosition, $ionicScrollDelegate) ->

  $scope.bubbleVisible = no
  $scope.bubble = d3.select '#weekly-list'
                    .append 'div'
                    .attr 'class', 'bubble bubble-left'
                    .attr 'id', 'weekly-bubble'
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
    sales = $scope.sales[idx]

    t = """
      <div class='row row-no-padding'>
        <div class='col col-offset-80 text-right positive'>
          <small><i class='ion-close-round'></i></small>
        </div>
      </div>
      <dl class='dl-horizontal'>
        <dt>Коло:</dt>
        <dd>#{ sales.draw }</dd>
        <dt>Дата:</dt>
        <dd>#{ $scope.dateToDMY sales.date }</dd>
        <hr />
        <dt>Лото:</dt><dd></dd>
        <hr />
        <dt>Уплата:</dt>
        <dd>#{ $scope.thou_sep sales.lotto }</dd>
    """
    t += """
        <dt>Добитници:</dt>
        <dd>
          <span style='color: red'>
            <strong>#{ if sales.lx7 > 0 then sales.lx7 + 'x7'  else '' }</strong>
          </span>
          <span style='color: orange'>
            <strong>#{ if sales.lx6p > 0 then sales.lx6p +
                 'x6<sup><strong>+</strong></sup>' else '' } 
            </strong>
          </span>
          #{ if sales.lx6 > 0 then sales.lx6 + 'x6' else '' } 
          #{ if sales.lx5 > 0 then $scope.thou_sep sales.lx5 + 'x5' else '' } 
          #{ if sales.lx4 > 0 then $scope.thou_sep sales.lx4 + 'x4' else '' } 
        </dd>
    """
    t += """
        <dt>Доб. комбинација:</dt>
        <dd>
          #{ sales.lwcol[0..6].sort((a, b)-> +a - +b).join(' ') }
          <span style='color: steelblue'>#{ sales.lwcol[7] }</span>
          <br />
          [ #{ sales.lwcol[0..6].join(' ') }
          <span style='color: steelblue'>#{ sales.lwcol[7] }</span> ]
        </dd>
    """

    t += """
        <hr />
        <dt>Џокер:</dt><dd></dd>
        <hr />
        <dt>Уплата:</dt>
        <dd>#{ $scope.thou_sep $scope.sales[idx].joker }</dd>
    """
    t += """
        <dt>Добитници:</dt>
        <dd>
          <span style='color: red'>
            <strong>#{ if sales.jx6 > 0 then sales.jx6 + 'x6' else '' }</strong>
          </span>
          <span style='color: orange'>
            <strong>#{ if sales.jx5 > 0 then sales.jx5 + 'x5' else '' }
            </strong>
          </span>
          #{ if sales.jx4 > 0 then sales.jx4 + 'x4' else '' } 
          #{ if sales.jx3 > 0 then $scope.thou_sep sales.jx3 + 'x3' else '' } 
          #{ if sales.jx2 > 0 then $scope.thou_sep sales.jx2 + 'x2' else '' } 
          #{ if sales.jx1 > 0 then $scope.thou_sep sales.jx1 + 'x1' else '' } 
        </dd>
    """
    t += """
        <dt>Доб. комбинација:</dt>
        <dd>
          #{ sales.jwcol.split('').join(' ') }
        </dd>
    """

    t += "</dl>"

    id      = "\#draw-#{sales.draw}"
    el      = angular.element document.querySelector id
    offset  = $ionicPosition.offset el
    new_top = offset.top + $ionicScrollDelegate.getScrollPosition().top
    $scope.bubble.html t
          .style 'left', (event.pageX + 10) + 'px'
          .style 'top', (new_top - 102) + 'px'
          .style 'opacity', 1

  # line chart
  $scope.hideChart = true
  $scope.lineChart = { }
  $scope.lineChart.width  = $scope.width
  $scope.lineChart.height = $scope.height

  # since ng-if not working
  $scope.lineChart.hide = true

  $scope.dow_to_mk = (d) ->
    switch Math.floor d
      when 1 then 'недела'
      when 2 then 'понеделник'
      when 3 then 'вторник'
      when 4 then 'среда'
      when 5 then 'четврток'
      when 6 then 'петок'
      when 7 then 'сабота'
      else ''

  $scope.dow_to_en = (d) ->
    switch Math.floor d
      when 1 then 'Sunday'
      when 2 then 'Monday'
      when 3 then 'Tuesday'
      when 4 then 'Wednesday'
      when 5 then 'Thursday'
      when 6 then 'Friday'
      when 7 then 'Saturday'
      else "*#{ d }*"

  $scope.year = parseInt $stateParams.year
  # A: draw #, B: date, C: lotto sales, D: x7 (lotto), I: joker sales, J: x6 (joker)
  queryYear = """SELECT A, dayOfWeek(B), 
                        C, I, B, D, E, F, G, H,
                        J, K, L, M, N, O,
                        P, Q, R, S, T, U, V, W,
                        X
                 WHERE YEAR(B) = #{ $scope.year }
                 ORDER BY A"""
  $ionicLoading.show()
  $http.get $scope.qurl(queryYear)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.sales = res.table.rows.map (r) ->
        a = $scope.eval_row r
        {
          draw:   a[0]
          dow:    a[1]
          lotto:  a[2]
          joker:  a[3]
          date:   a[4]
          lx7:    a[5]
          lx6p:   a[6]
          lx6:    a[7]
          lx5:    a[8]
          lx4:    a[9]

          lwcol:  a[16..23]

          jx6:    a[10]
          jx5:    a[11]
          jx4:    a[12]
          jx3:    a[13]
          jx2:    a[14]
          jx1:    a[15]

          jwcol:  a[24]
        }
      $scope.buildSeries()
      $ionicLoading.hide()
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат податоци за #{ $sope.year } година. Пробај подоцна."
        duration: 3000
      })

  # build line chart series (only lotto sales)
  $scope.buildSeries = () ->
    arr = [[], [],  [], [], [], [], [], [] ]
    for sale in $scope.sales
      arr[sale.dow].push { x: sale.date, y: sale.lotto, lx7: sale.lx7, draw: sale.draw }
    series = [ ]
    for i, a of arr
      if arr[i].length > 0
        series.push { name: $scope.dow_to_mk(i), data: arr[i] }
    $scope.series = series
        


  query = "SELECT YEAR(B), COUNT(A) GROUP BY YEAR(B) ORDER BY YEAR(B)"
  $http.get $scope.qurl(query)
    .success (data, status) ->
      res = $scope.to_json data
      $scope.years = res.table.rows.map (r) ->
        a = $scope.eval_row r
        { year: a[0], draws: a[1] }
      $scope.select = ($scope.years.filter (x) -> x.year is $scope.year)[0]
  $scope.newSelection = (v) ->
    $scope.lineChart.hide = true
    $scope.select = v
    $scope.year   = $scope.select.year
    queryYear = """SELECT A, dayOfWeek(B), 
                          C, I, B, D, E, F, G, H,
                          J, K, L, M, N, O,
                          P, Q, R, S, T, U, V, W,
                          X
                  WHERE YEAR(B) = #{ $scope.year }
                  ORDER BY A"""
    # update scope.sales and scope.series
    $ionicLoading.show()
    $http.get $scope.qurl(queryYear)
      .success (data, status) ->
        res = $scope.to_json data
        $scope.sales = res.table.rows.map (r) ->
          a = $scope.eval_row r
          {
            draw:   a[0]
            dow:    a[1]
            lotto:  a[2]
            joker:  a[3]
            date:   a[4]
            lx7:    a[5]
            lx6p:   a[6]
            lx6:    a[7]
            lx5:    a[8]
            lx4:    a[9]

            lwcol:  a[16..23]

            jx6:    a[10]
            jx5:    a[11]
            jx4:    a[12]
            jx3:    a[13]
            jx2:    a[14]
            jx1:    a[15]

            jwcol:  a[24]
          }
        $scope.buildSeries()
        $scope.lineChart.hide = true
        $ionicLoading.hide()
      .error (err) ->
        $ionicLoading.show({
          template: "Не може да се вчитаат податоци за #{ $sope.year } година." +
                    " Пробај подоцна."
          duration: 3000
        })
  $scope.$watch 'sales', () ->
    if $scope.year is $scope.lastYear
      $ionicScrollDelegate.$getByHandle('scroll-to-bottom').scrollBottom true
    
  
