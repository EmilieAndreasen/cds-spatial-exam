extensions [gis]

breed [residents resident]
breed [pedestrians pedestrian]
breed [cars car]
breed [intersections intersection]
directed-link-breed [roads road]

residents-own [init_dest reached? current_int moving? evacuated? dead? speed decision miltime path]
roads-own [crowd traffic mid-x mid-y]
intersections-own [shelter? id previous fscore gscore path evacuee_count myneighbors entrance? test]
pedestrians-own [current_int shelter next_int moving? evacuated? dead? speed path decision]
cars-own [current_int moving? evacuated? dead? next_int shelter speed path decision car_ahead space_hw speed_diff acc road_on]
globals [ev_times mouse-was-down? road-network shelter_locations shelter-locations evacuation-radius mortality_rate simulation_start_time patch_to_meter patch_to_feet fd_to_ftps fd_to_mph tick_to_sec min_lon min_lat max_evacuation_time]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; HELPER FUNCTIONS ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report mouse-clicked?
  report (mouse-was-down? = true and not mouse-down?)
end

to-report find-origins
  let origins no-turtles
  ask residents [
    let nearest-int min-one-of intersections [distance myself]
    set origins (turtle-set origins nearest-int)
  ]
  report origins
end

to-report rayleigh-random [sigma]
  report (sqrt((- ln(1 - random-float 1 ))*(2 *(sigma ^ 2))))
end

to make-decision
  let rnd random-float 100
  ifelse (rnd < 50) [ ; assuming 50% on foot and 50% by car
    set decision 1
    set miltime ((rayleigh-random Rsig1) + Rtau1 ) * 60 / tick_to_sec
  ] [
    set decision 2
    set miltime ((rayleigh-random Rsig2) + Rtau2 ) * 60 / tick_to_sec
  ]
end

to-report Astar [ source gl gls ]
  let rchd? false
  let dstn nobody
  let closedset []
  let openset []

  ask intersections [ set previous -1 set gscore 1000000 set fscore 1000000 ]
  set openset lput [who] of source openset

  ask source [
    set gscore 0
    set fscore (gscore + distance gl)
  ]

  while [ not empty? openset and (not rchd?) ] [
    let current Astar-smallest openset
    if member? current [who] of gls [
      set dstn turtle current
      set rchd? true
    ]
    set openset remove current openset
    set closedset lput current closedset

    ask turtle current [
      ask out-road-neighbors [
        let neighbor-who [who] of self
        let tent-gscore [gscore] of myself + [link-length] of (road [who] of myself who)
        let tent-fscore tent-gscore + distance gl
        if ( member? neighbor-who closedset and ( tent-fscore >= [fscore] of turtle neighbor-who ) ) [ stop ]
        if ( not member? neighbor-who closedset or ( tent-fscore < [fscore] of turtle neighbor-who )) [
          ask turtle neighbor-who [
            set previous current
            set gscore tent-gscore
            set fscore tent-fscore
            if not member? who openset [
              set openset lput who openset
            ]
          ]
        ]
      ]
    ]
  ]

  let route []
  ifelse dstn != nobody [
    while [ [previous] of dstn != -1 ] [
      set route fput [who] of dstn route
      set dstn turtle ([previous] of dstn)
    ]
  ]
  [
    set route []
  ]
  report route
end

to-report Astar-smallest [ who_list ]
  let min-who 0
  let min-fscr 100000000
  foreach who_list [ [?1] ->
    let fscr [fscore] of intersection ?1
    if fscr < min-fscr [
      set min-fscr fscr
      set min-who ?1
    ]
  ]
  report min-who
end

to move-gm
  set car_ahead cars in-cone (150 / patch_to_feet) 20
  set car_ahead car_ahead with [self != myself]
  set car_ahead car_ahead with [not evacuated?]
  set car_ahead car_ahead with [moving?]
  set car_ahead car_ahead with [abs(subtract-headings heading [heading] of myself) < 160]
  set car_ahead car_ahead with [distance myself > 0.0001]
  set car_ahead min-one-of car_ahead [distance myself]
  ifelse is-turtle? car_ahead [
    set space_hw distance car_ahead
    set speed_diff [speed] of car_ahead - speed
    ifelse space_hw < (6 / patch_to_feet) [set speed 0]
    [
      set acc (alpha / fd_to_mph * 5280 / patch_to_feet) * ((speed) ^ 0) / ((space_hw) ^ 2) * speed_diff
      set speed speed + acc
    ]
    if speed > (space_hw - (6 / patch_to_feet)) [set speed min list (space_hw - (6 / patch_to_feet)) [speed] of car_ahead]
    if speed > (max_speed / fd_to_mph) [set speed (max_speed / fd_to_mph)]
    if speed < 0 [set speed 0]
  ]
  [
    if speed < (max_speed / fd_to_mph) [set speed speed + (acceleration / fd_to_ftps * tick_to_sec)]
    if speed > max_speed / fd_to_mph [set speed max_speed / fd_to_mph]
  ]
  if speed > distance next_int [set speed distance next_int]
end

to mark-evacuated
  if not evacuated? [
    set color green
    set moving? false
    set evacuated? true
    set dead? false
    set ev_times lput (ticks * tick_to_sec / 60) ev_times
    ask current_int [set evacuee_count evacuee_count + 1]
  ]
end

to mark-dead
  set color red
  set moving? false
  set evacuated? false
  set dead? true
end

to-report is-heading-right? [link_heading direction]
  if direction = "north" [ if abs(subtract-headings 0 link-heading) <= 90 [report true]]
  if direction = "east" [ if abs(subtract-headings 90 link-heading) <= 90 [report true]]
  if direction = "south" [ if abs(subtract-headings 180 link-heading) <= 90 [report true]]
  if direction = "west" [ if abs(subtract-headings 270 link-heading) <= 90 [report true]]
  report false
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; SETUP INITIAL PARAMETERS ;:;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-init-val
  set immediate_evacuation false
  set Ped_Speed 4
  set Ped_Sigma 0.65
  set max_speed 35
  set acceleration 5
  set deceleration 25
  set alpha 0.14
  set Rtau1 10
  set Rtau2 10
  set Rsig1 1.65
  set Rsig2 1.65
  set patch_to_meter 1
  set fd_to_ftps 0.3048
  set tick_to_sec 1
  set evacuation-radius 2 / patch_to_meter
  set max_evacuation_time 30
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; READ GIS FILES ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to read-gis-files
  gis:load-coordinate-system "new_part_of_aarhus/cut_aarhus_split.prj"
  set shelter_locations gis:load-dataset "shelters_reprojected/shelters_reprojected.shp"
  set road-network gis:load-dataset "new_part_of_aarhus/cut_aarhus_split.shp"

  let min-x 571124.0821833728
  let max-x 577657.318834567
  let min-y 6219999.98388973
  let max-y 6227772.827541529

  let expansion-margin 10
  set min-x min-x - expansion-margin
  set max-x max-x + expansion-margin
  set min-y min-y - expansion-margin
  set max-y max-y + expansion-margin

  let netlogo-envelope (list min-x max-x min-y max-y)
  gis:set-world-envelope netlogo-envelope

  print (word "World Envelope: " gis:world-envelope)
  print (word "NetLogo Envelope: " netlogo-envelope)
  print (word "Transformation Set")
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; LOAD NETWORK ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load-network
  ask intersections [ die ]
  ask roads [ die ]

  foreach gis:feature-list-of road-network [ i ->
    foreach gis:vertex-lists-of i [ j ->
      let previous-node-pt nobody
      foreach j [ k ->
        let location gis:location-of k
        if not empty? location [
          let new-node-pt nobody
          create-intersections 1 [
            set xcor item 0 location
            set ycor item 1 location
            set myneighbors n-of 0 turtles
            set shelter? false
            set size 0.2
            set shape "circle"
            set color brown
            set hidden? true
            set new-node-pt self
          ]
          ifelse previous-node-pt = nobody [
            set previous-node-pt new-node-pt
          ] [
            ask previous-node-pt [ create-link-with new-node-pt ]
            set previous-node-pt new-node-pt
          ]
        ]
      ]
    ]
  ]

  ask intersections [ set myneighbors link-neighbors ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; LOAD SHELTERS ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load-shelters
  set shelter-locations []
  foreach gis:feature-list-of shelter_locations [ i ->
    foreach gis:vertex-lists-of i [ j ->
      foreach j [ k ->
        let location gis:location-of k
        if not empty? location [
          let x item 0 location
          let y item 1 location
          set shelter-locations lput (list x y) shelter-locations
          create-intersections 1 [
            set xcor x
            set ycor y
            set shelter? true
            set shape "circle"
            set size 2
            set color yellow
          ]
          ; Debug print
          print (word "Shelter created at: " x ", " y)
        ]
      ]
    ]
  ]
end


to-report check-evacuation
  let close-enough? false
  foreach shelter-locations [ shelter-coord ->
    let shelter-x item 0 shelter-coord
    let shelter-y item 1 shelter-coord
    if distancexy shelter-x shelter-y < evacuation-radius [
      set close-enough? true
    ]
  ]
  report close-enough?
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; CONNECT SHELTERS ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to connect-shelters
  foreach shelter-locations [ shelter-coord ->
    let shelter-x item 0 shelter-coord
    let shelter-y item 1 shelter-coord
    let nearest-int min-one-of intersections [distancexy shelter-x shelter-y]
    create-roads-between shelter-x shelter-y nearest-int
  ]
end

to create-roads-between [ shelter-x shelter-y nearest-int ]
  let shelter-int one-of intersections with [xcor = shelter-x and ycor = shelter-y]
  if (shelter-int != nobody and shelter-int != nearest-int) [
    ask nearest-int [
      create-road-to shelter-int
      ask shelter-int [ create-road-to myself ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; LOAD POPULATION ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load-population
  ask residents [ die ]
  ask pedestrians [ die ]
  ask cars [ die ]

  let min-xcor min [min-pxcor] of patches
  let max-xcor max [max-pxcor] of patches
  let min-ycor min [min-pycor] of patches
  let max-ycor max [max-pycor] of patches

  let num-residents 300

  repeat num-residents [
    let valid-location? false
    let x 0
    let y 0

    while [not valid-location?] [
      ifelse random 2 = 0 [
        let spawn-location one-of intersections
        if spawn-location != nobody [
          set x [xcor] of spawn-location
          set y [ycor] of spawn-location
          set valid-location? true
        ]
      ] [
        let selected-road one-of roads
        if selected-road != nobody [
          set x [mid-x] of selected-road
          set y [mid-y] of selected-road
          set valid-location? true
        ]
      ]
    ]

    create-residents 1 [
      set xcor x
      set ycor y
      set color orange
      set shape "dot"
      set size 2
      set moving? false
      set init_dest min-one-of intersections [distance myself]
      set speed random-normal Ped_Speed Ped_Sigma
      if fd_to_ftps != 0 [
        set speed speed / fd_to_ftps
      ]
      if speed < 0.001 [set speed 0.001]
      set evacuated? false
      set dead? false
      set reached? false
      set path []
      make-decision
      if immediate_evacuation [
        set miltime 0
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; LOAD ROUTES ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load-routes
  let shelters intersections with [shelter?]

  ; Debug print to verify shelters
  print (word "Number of shelters: " count shelters)
  ask shelters [ print (word "Shelter at: " xcor ", " ycor " shelter? = " shelter?) ]

  let origins find-origins

  ; Debug print to verify origins
  print (word "Number of origins: " count origins)
  ask origins [
    print (word "Origin at: " xcor ", " ycor)
  ]

  let limit 10
  let limited-origins ifelse-value (count origins > limit) [n-of limit origins] [origins]

  ; Debug print to verify limited origins
  print (word "Number of limited origins: " count limited-origins)
  ask limited-origins [
    print (word "Limited origin at: " xcor ", " ycor)
  ]

  ask limited-origins [
    let goals shelters
    let closest-goal min-one-of goals [distance myself]
    let route Astar self closest-goal goals
    set path route

    ; Debug print for route
    print (word "Route from: " xcor ", " ycor " to " [xcor] of closest-goal ", " [ycor] of closest-goal " path: " route)
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; LOAD 1/2 ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load1
  ca
  setup-init-val
  ask patches [ set pcolor white ]
  set ev_times []
  read-gis-files
  load-network
  load-shelters
  connect-shelters
  reset-timer
  reset-ticks
  set simulation_start_time ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; LOAD 2/2 ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load2
  load-population
  load-routes
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;    GO    ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  let current-time (ticks * tick_to_sec / 60)
  if current-time >= max_evacuation_time [
    stop
  ]

  ; Print debug information for residents
  ask residents [
    print (word "Resident " who " at " xcor ", " ycor " reached? " reached? " moving? " moving? " path: " path)
  ]

  ask residents with [reached?] [
    let spd speed
    let dcsn decision
    if dcsn = 1 [
      ask current_int [
        hatch-pedestrians 1 [
          set size 2
          set shape "dot"
          set current_int myself
          set speed spd
          set evacuated? false
          set dead? false
          set moving? false
          set color orange
          set path [path] of myself
          set decision 1
          ifelse is-list? path and empty? path [set shelter -1] [set shelter last path]
          if shelter = -1 and [shelter?] of current_int [set shelter -99]
        ]
      ]
    ]
    if dcsn = 2 [
      ask current_int [
        hatch-cars 1 [
          set size 2
          set current_int myself
          set evacuated? false
          set dead? false
          set moving? false
          set color sky
          set path [path] of myself
          set decision 2
          ifelse is-list? path and empty? path [set shelter -1] [set shelter last path]
          if shelter = -1 and [shelter?] of current_int [set shelter -99]
        ]
      ]
    ]
    die
  ]

  ask pedestrians with [not evacuated? and not dead?] [
    if check-evacuation [mark-evacuated]
  ]

  ask pedestrians with [not moving? and not empty? path and not evacuated? and not dead?] [
    set next_int intersection item 0 path
    set path remove-item 0 path
    set heading towards next_int
    set moving? true
    ask road ([who] of current_int) ([who] of next_int) [set crowd crowd + 1]
  ]

  ask pedestrians with [moving?] [
    ifelse speed > distance next_int [fd distance next_int] [fd speed]
    if (distance next_int < 0.005) [
      set moving? false
      ask road ([who] of current_int) ([who] of next_int) [set crowd crowd - 1]
      set current_int next_int
      if check-evacuation [mark-evacuated]
    ]
  ]

  ask cars with [not evacuated? and not dead?] [
    if check-evacuation [mark-evacuated]
  ]

  ask cars with [not moving? and not empty? path and not evacuated? and not dead?] [
    set next_int intersection item 0 path
    set path remove-item 0 path
    set heading towards next_int
    set moving? true
    ask road ([who] of current_int) ([who] of next_int) [set traffic traffic + 1]
  ]

  ask cars with [moving?] [
    move-gm
    fd speed
    if (distance next_int < 0.005) [
      set moving? false
      ask road ([who] of current_int) ([who] of next_int) [set traffic traffic - 1]
      set current_int next_int
      if check-evacuation [mark-evacuated]
    ]
  ]

  ask residents with [current-time >= max_evacuation_time] [mark-dead]
  ask cars with [current-time >= max_evacuation_time] [mark-dead]
  ask pedestrians with [current-time >= max_evacuation_time] [mark-dead]

  let total-agents count residents + count pedestrians + count cars
  if total-agents > 0 [
    set mortality_rate ((count residents with [dead?] + count pedestrians with [dead?] + count cars with [dead?]) / total-agents) * 100
  ]

  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
228
11
940
724
-1
-1
3.5025
1
10
1
1
1
0
0
0
1
-100
100
-100
100
1
1
1
ticks
30.0

PLOT
946
342
1370
495
Percentage of Evacuated
Min
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Evacuated" 1.0 0 -10899396 true "" "plotxy (ticks / 60) (count turtles with [ color = green ] / (count residents + count pedestrians + count cars) * 100)"
"Cars" 1.0 0 -13345367 true "" "plotxy (ticks / 60) (count cars with [ color = green ] / (count residents + count pedestrians + count cars) * 100)"
"Pedestrians" 1.0 0 -14835848 true "" "plotxy (ticks / 60) (count pedestrians with [ color = green ] / (count residents + count pedestrians + count cars) * 100)"

SWITCH
67
13
221
46
immediate_evacuation
immediate_evacuation
1
1
-1000

BUTTON
1294
10
1373
43
GO
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
8
54
217
82
Residents' Decision Making Probabalisties : (Percent)
11
0.0
1

INPUTBOX
8
87
109
147
R1_HorEvac_Foot
25.0
1
0
Number

INPUTBOX
8
150
109
210
R3_VerEvac_Foot
25.0
1
0
Number

MONITOR
962
47
1044
92
Time (min)
ticks / 60
1
1
11

INPUTBOX
113
214
163
274
Hc
1.0
1
0
Number

PLOT
945
158
1370
332
Percentage of Casualties
Min
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Dead" 1.0 0 -2674135 true "" "plotxy (ticks / 60) (count turtles with [color = red] / (count residents + count pedestrians + count cars) * 100)"
"Cars" 1.0 0 -5825686 true "" "plotxy (ticks / 60) (count cars with [color = red] / (count residents + count pedestrians + count cars) * 100)"
"Pedestrians" 1.0 0 -955883 true "" "plotxy (ticks / 60) ((count pedestrians with [color = red] + count residents with [color = red]) / (count residents + count pedestrians + count cars) * 100)"

BUTTON
946
12
1022
45
READ (1/2)
load1\noutput-print \"READ (1/2) DONE!\"\nbeep
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
5
215
121
257
Critical Depth and Time: (Meters and Seconds)
11
0.0
1

INPUTBOX
8
539
58
599
Rtau1
10.0
1
0
Number

INPUTBOX
58
539
108
599
Rsig1
1.65
1
0
Number

INPUTBOX
8
603
58
663
Rtau3
10.0
1
0
Number

INPUTBOX
58
603
108
663
Rsig3
1.65
1
0
Number

TEXTBOX
10
523
210
551
Evacuation Decsion Making Times:
11
0.0
1

TEXTBOX
18
274
67
302
On foot: (ft/s)
11
0.0
1

INPUTBOX
66
276
136
336
Ped_Speed
4.0
1
0
Number

INPUTBOX
144
276
215
336
Ped_Sigma
0.65
1
0
Number

MONITOR
1074
48
1156
93
Evacuated
count turtles with [ color = green ]
17
1
11

MONITOR
1165
48
1242
93
Casualty
count turtles with [ color = red ]
17
1
11

MONITOR
1166
101
1260
146
Mortality (%)
mortality_rate
2
1
11

BUTTON
1223
10
1289
43
Read (2/2)
load2\noutput-print \"READ (2/2) DONE!\"\nbeep
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
117
87
217
147
R2_HorEvac_Car
25.0
1
0
Number

INPUTBOX
117
150
217
210
R4_VerEvac_Car
25.0
1
0
Number

INPUTBOX
114
539
164
599
Rtau2
10.0
1
0
Number

INPUTBOX
164
539
214
599
Rsig2
1.65
1
0
Number

INPUTBOX
116
604
166
664
Rtau4
10.0
1
0
Number

INPUTBOX
163
604
213
664
Rsig4
1.65
1
0
Number

INPUTBOX
66
340
137
400
max_speed
35.0
1
0
Number

TEXTBOX
13
340
53
368
by car:\n(mph)
11
0.0
1

INPUTBOX
66
401
139
461
acceleration
5.0
1
0
Number

INPUTBOX
143
401
218
461
deceleration
25.0
1
0
Number

TEXTBOX
8
413
57
447
(ft/s^2)
11
0.0
1

INPUTBOX
66
462
139
522
alpha
0.14
1
0
Number

TEXTBOX
5
476
65
517
(mi^2/hr)
11
0.0
1

BUTTON
7
14
62
47
Initialize
setup-init-val
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
947
504
1370
725
Evacuation Time Histogram
Minutes (after the earthquake)
#
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Histogram" 1.0 1 -16777216 true "set-plot-x-range 0 60\nset-plot-y-range 0 count turtles with [ color = green ]\nset-histogram-num-bars 60\nset-plot-pen-mode 1 ; bar mode" "histogram ev_times"
"Mean" 1.0 0 -10899396 true "set-plot-pen-mode 0 ; line mode" "plot-pen-reset\nplot-pen-up\nplotxy mean ev_times 0\nplot-pen-down\nplotxy mean ev_times plot-y-max"
"Median" 1.0 0 -2674135 true "set-plot-pen-mode 0 ; line mode" "plot-pen-reset\nplot-pen-up\nplotxy median ev_times 0\nplot-pen-down\nplotxy median ev_times plot-y-max"

MONITOR
1043
101
1159
146
Per Evacuated (%)
count turtles with [ color = green ] / (count residents + count pedestrians + count cars) * 100
1
1
11

INPUTBOX
166
213
216
273
Tc
120.0
1
0
Number

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Exp" repetitions="5" runMetricsEveryStep="false">
    <setup>pre-read
turn-vertical intersection vertical_shelter_num
read-all</setup>
    <go>go</go>
    <metric>count turtles with [color = red] / (count residents + count pedestrians) * 100</metric>
    <metric>count turtles with [color = green and distance one-of intersections with [gate? and gate-type = "Ver"] &lt; 0.01]</metric>
    <enumeratedValueSet variable="tsunami-case">
      <value value="&quot;250yrs&quot;"/>
      <value value="&quot;500yrs&quot;"/>
      <value value="&quot;1000yrs&quot;"/>
      <value value="&quot;2500yrs&quot;"/>
      <value value="&quot;5000yrs&quot;"/>
      <value value="&quot;10000yrs&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="immediate-evacuation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hc">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R3-VerEvac-Foot">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ped-Speed">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ped-Sigma">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Rtau3">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Rsig3">
      <value value="1.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vertical_shelter_num">
      <value value="82"/>
      <value value="74"/>
      <value value="486"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
