#
# winners.coffee
# lotto-ionic
# v0.0.2
# Copyright 2016 Andreja Tonevski, https://github.com/atonevski/lotto-ionic
# For license information see LICENSE in the repository
#

angular.module 'app.winners', []

.controller 'Winners', ($scope, $http, $ionicLoading) ->
  # dummy controller
  console.log 'Winners'

.controller 'LottoWinners', ($scope, $http, $ionicLoading
, $ionicPosition, $ionicScrollDelegate) ->

  $scope.bubbleVisible = no
  $scope.bubble = d3.select '#winners-list'
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
    winners = $scope.winners[idx]

    t = """
      <div class='row row-no-padding'>
        <div class='col col-offset-80 text-right positive'>
          <small><i class='ion-close-round'></i></small>
        </div>
      </div>
      <h4 style='text-align: center'>#{ idx + 1 }/#{ $scope.winners.length }</h4>
      <dl class='dl-horizontal'>
        <dt>Коло:</dt>
        <dd>#{ winners.draw }</dd>
        <dt>Дата:</dt>
        <dd>#{ $scope.dateToDMY winners.date }</dd>
        <hr />
        <dt>Лото:</dt><dd></dd>
        <hr />
        <dt>Уплата:</dt>
        <dd>#{ $scope.thou_sep winners.lsales }</dd>
    """
    t += """
        <dt>Добитници:</dt>
        <dd>
          <span style='color: red;'>
            <strong>#{ winners.lx7 + 'x7' }</strong>
          </span>
          <span style='color: orange'>
            <strong>
              #{ if winners.lx6p > 0 then winners.lx6p +
                 'x6<sup><strong>+</strong></sup>' else '' }
            </strong>
          </span>
          #{ if winners.lx6 > 0 then winners.lx6 + 'x6' else '' } 
          #{ $scope.thou_sep winners.lx5 + 'x5' } 
          #{ $scope.thou_sep winners.lx4 + 'x4' } 
        </dd>
    """
    t += """
        <dt>Доб. комбинација:</dt>
        <dd>
          #{ winners.lwcol[0..6].sort((a, b)-> +a - +b).join(' ') }
          <span style='color: steelblue'>#{ winners.lwcol[7] }</span>
          <br />
          [ #{ winners.lwcol[0..6].join(' ') }
          <span style='color: steelblue'>#{ winners.lwcol[7] }</span> ]
        </dd>
    """
    t += """
        <hr />
        <dt>Џокер:</dt><dd></dd>
        <hr />
        <dt>Уплата:</dt>
        <dd>#{ $scope.thou_sep winners.jsales }</dd>
    """
    t += """
        <dt>Добитници:</dt>
        <dd>
          <span style='color: red'>
            <strong>#{ if winners.jx6 > 0 then winners.jx6 + 'x6' else '' }</strong>
          </span>
          <span style='color: orange'>
            <strong>#{ if winners.jx5 > 0 then winners.jx5 + 'x5' else '' }</strong>
          </span>
          #{ if winners.jx4 > 0 then winners.jx4 + 'x4' else '' } 
          #{ if winners.jx3 > 0 then $scope.thou_sep winners.jx3 + 'x3' else '' } 
          #{ if winners.jx2 > 0 then $scope.thou_sep winners.jx2 + 'x2' else '' } 
          #{ if winners.jx1 > 0 then $scope.thou_sep winners.jx1 + 'x1' else '' } 
        </dd>
    """
    t += """
        <dt>Доб. комбинација:</dt>
        <dd>
          #{ winners.jwcol.split('').join(' ') }
        </dd>
    """
    t += "</dl>"

    id = "\#winners-#{ winners.year }-#{ winners.draw }"
    el = angular.element document.querySelector id
    offset = $ionicPosition.offset el
    new_top = offset.top + $ionicScrollDelegate.getScrollPosition().top
    $scope.bubble.html t
          .style 'left', (event.pageX + 10) + 'px'
          .style 'top', (new_top - 58) + 'px'
          .style 'opacity', 1

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
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат лото добитниците. Пробај подоцна."
        duration: 3000
      })

.controller 'JokerWinners', ($scope, $http, $ionicLoading
, $ionicPosition, $ionicScrollDelegate) ->
  $scope.bubbleVisible = no
  $scope.bubble = d3.select '#winners-list'
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
    winners = $scope.winners[idx]

    t = """
      <div class='row row-no-padding'>
        <div class='col col-offset-80 text-right positive'>
          <small><i class='ion-close-round'></i></small>
        </div>
      </div>
      <h4 style='text-align: center'>#{ idx + 1 }/#{ $scope.winners.length }</h4>
      <dl class='dl-horizontal'>
        <dt>Коло:</dt>
        <dd>#{ winners.draw }</dd>
        <dt>Дата:</dt>
        <dd>#{ $scope.dateToDMY winners.date }</dd>
        <hr />
        <dt>Лото:</dt><dd></dd>
        <hr />
        <dt>Уплата:</dt>
        <dd>#{ $scope.thou_sep winners.lsales }</dd>
    """
    t += """
        <dt>Добитници:</dt>
        <dd>
          <span style='color: red;'>
            <strong>
              #{ if winners.lx7 then winners.lx7 + 'x7' else '' }
            </strong>
          </span>
          <span style='color: orange'>
            <strong> #{ if winners.lx6p > 0 then winners.lx6p +
                 'x6<sup><strong>+</strong></sup>' else '' } 
            </strong>
          </span>
          #{ if winners.lx6 > 0 then winners.lx6 + 'x6' else '' } 
          #{ $scope.thou_sep winners.lx5 + 'x5' } 
          #{ $scope.thou_sep winners.lx4 + 'x4' } 
        </dd>
    """
    t += """
        <dt>Доб. комбинација:</dt>
        <dd>
          #{ winners.lwcol[0..6].sort((a, b)-> +a - +b).join(' ') }
          <span style='color: steelblue'>#{ winners.lwcol[7] }</span>
          <br />
          [ #{ winners.lwcol[0..6].join(' ') }
          <span style='color: steelblue'>#{ winners.lwcol[7] }</span> ]
        </dd>
    """
    t += """
        <hr />
        <dt>Џокер:</dt><dd></dd>
        <hr />
        <dt>Уплата:</dt>
        <dd>#{ $scope.thou_sep winners.jsales }</dd>
    """
    t += """
        <dt>Добитници:</dt>
        <dd>
          <span style='color: red'>
            <strong>#{ if winners.jx6 > 0 then winners.jx6 + 'x6' else '' }</strong>
          </span>
          <span style='color: orange'>
            <strong>#{ if winners.jx5 > 0 then winners.jx5 + 'x5' else '' }</strong>
          </span>
          #{ if winners.jx4 > 0 then winners.jx4 + 'x4' else '' } 
          #{ if winners.jx3 > 0 then $scope.thou_sep winners.jx3 + 'x3' else '' } 
          #{ if winners.jx2 > 0 then $scope.thou_sep winners.jx2 + 'x2' else '' } 
          #{ if winners.jx1 > 0 then $scope.thou_sep winners.jx1 + 'x1' else '' } 
        </dd>
    """
    t += """
        <dt>Доб. комбинација:</dt>
        <dd>
          #{ winners.jwcol.split('').join(' ') }
        </dd>
    """
    t += "</dl>"

    id = "\#winners-#{ winners.year }-#{ winners.draw }"
    el = angular.element document.querySelector id
    offset = $ionicPosition.offset el
    new_top = offset.top + $ionicScrollDelegate.getScrollPosition().top
    $scope.bubble.html t
          .style 'left', (event.pageX + 10) + 'px'
          .style 'top', (new_top - 58) + 'px'
          .style 'opacity', 1
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
    .error (err) ->
      $ionicLoading.show({
        template: "Не може да се вчитаат џокер добитниците. Пробај подоцна."
        duration: 3000
      })
