extensions [gis]

breed [residents resident]
breed [pedestrians pedestrian]
breed [cars car]
breed [intersections intersection]
directed-link-breed [roads road]

residents-own [init_dest reached? current_int moving? evacuated? dead? speed decision miltime path shelter normal-speed]
roads-own [crowd traffic mid-x mid-y]
intersections-own [shelter? id evacuee_count myneighbors entrance? test]
pedestrians-own [shelter moving? evacuated? dead? speed path decision]
cars-own [moving? evacuated? dead? speed path decision car_ahead space_hw speed_diff acc road_on]
globals [ev_times mouse-was-down? road-network shelter_locations shelter-locations evacuation-radius mortality_rate simulation_start_time patch_to_meter patch_to_feet fd_to_ftps fd_to_mph tick_to_sec min_lon min_lat max_evacuation_time max_evac_time output-filename green-percentage]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; HELPER FUNCTIONS ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report mouse-clicked?
  report (mouse-was-down? = true and not mouse-down?)
end

to-report find-nearest-shelter [agent]
  let nearest-shelter min-one-of intersections with [shelter?] [distance agent]
  report nearest-shelter
end

to-report rayleigh-random [sigma]
  report (sqrt((- ln(1 - random-float 1 ))*(2 *(sigma ^ 2))))
end

to make-decision
  let rnd random-float 100
  ifelse (rnd < 25) [ ; 25% have shorter milling time and 75% have longer milling time
    set decision 1
    set miltime ((rayleigh-random Rsig1_short) + Rtau1_short) ; Shorter milling time
  ] [
    set decision 2
    set miltime ((rayleigh-random Rsig2_long) + Rtau2_long) ; Longer milling time
  ]
end

to move-towards-shelter [agent]
  let target-shelter [shelter] of agent
  if target-shelter != nobody [
    let target-x [xcor] of target-shelter
    let target-y [ycor] of target-shelter
    ask agent [
      face target-shelter
      let distance-to-shelter distance target-shelter
      ifelse (distance-to-shelter <= speed) [
        move-to target-shelter
        set reached? true
        mark-evacuated
      ] [
        ; Reduce speed on black patches
        ifelse [pcolor] of patch-here = black [
          set speed normal-speed / 2
        ] [
          ; Check for nearby agents and slow down if necessary
          let ahead-agent one-of residents in-cone 1 1
          ifelse ahead-agent != nobody [
            set speed normal-speed * 0.85 ; Slow down by 15% if another agent is directly ahead
          ] [
            set speed normal-speed
          ]
        ]
        fd speed
      ]
    ]
  ]
end

to mark-evacuated
  if not evacuated? [
    set color green
    set moving? false
    set evacuated? true
    set dead? false
    set ev_times lput (ticks / 60) ev_times ; log time in minutes
  ]
end

to mark-dead
  set color red
  set moving? false
  set evacuated? false
  set dead? true
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; SETUP INITIAL PARAMETERS ;:;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-init-val
  set immediate_evacuation false
  set Ped_Speed 0.01  ; Increased speed
  set Ped_Sigma 0.005  ; Adjusted standard deviation
  set Rtau1_short 300  ; Time constant for shorter milling time (6 minutes in seconds)
  set Rtau2_long 600  ; Time constant for longer milling time (10 minutes in seconds)
  set Rsig1_short 120  ; Adjusted sigma for shorter milling time variation
  set Rsig2_long 240  ; Adjusted sigma for longer milling time variation
  set patch_to_meter 1
  set fd_to_ftps 0.01  ; Further adjusted conversion factor
  set tick_to_sec 1  ; Set tick duration to 1 second
  set evacuation-radius 2 / patch_to_meter
  set max_evacuation_time 7200  ; Max evacuation model time in seconds (2 hours)
  set max_evac_time 2400  ; Max evacuation time in seconds, agents are considered dead after this time if not evacuated (40 minutes)
  set output-filename "evacuation_results_delayed.csv"
  set green-percentage 0 ; Initialize the global variable
  file-open output-filename
  file-write "tick, green-percentage, dead?, shelter-x, shelter-y" ; Write the header line
  file-print ""
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; READ GIS FILES ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to read-gis-files
  gis:load-coordinate-system "new_part_of_aarhus/cut_aarhus_split.prj"
  set shelter_locations gis:load-dataset "shelters/shelters.shp"
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

to read-obstacle-data
  let obstacles gis:load-dataset "multipolygon_aarhus/cut_multipolygon_aarhus.shp"
  foreach gis:feature-list-of obstacles [ i ->
    foreach gis:vertex-lists-of i [ j ->
      foreach j [ k ->
        let location gis:location-of k
        if not empty? location [
          let x item 0 location
          let y item 1 location
          ask patch x y [
            set pcolor black ; Marking obstacles as black patches
          ]
        ]
      ]
    ]
  ]
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
;;;;;;;;;;; LOAD POPULATION ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load-population
  ask residents [ die ]
  ask pedestrians [ die ]
  ask cars [ die ]

  let min-xcor min [min-pxcor] of patches
  let max-xcor max [max-pxcor] of patches
  let min-ycor min [max-pycor] of patches
  let max-ycor max [max-pycor] of patches

  let num-residents 10000

  repeat num-residents [
    let valid-location? false
    let x 0
    let y 0

    while [not valid-location?] [
      let spawn-location one-of patches with [pcolor != black and any? intersections in-radius 2]
      if spawn-location != nobody [
        set x [pxcor] of spawn-location
        set y [pycor] of spawn-location
        set valid-location? true
      ]
    ]

    create-residents 1 [
      set xcor x
      set ycor y
      set color orange
      set shape "dot"
      set size 2
      set moving? false
      set normal-speed max list (random-normal Ped_Speed Ped_Sigma) 0.001 ; Ensure positive speed
      set speed normal-speed
      if fd_to_ftps != 0 [
        set speed speed / fd_to_ftps
      ]
      set evacuated? false
      set dead? false
      set reached? false
      set shelter find-nearest-shelter self
      make-decision
      if immediate_evacuation [
        set miltime 0
      ]
    ]
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
  read-obstacle-data
  load-network
  load-shelters
  reset-timer
  reset-ticks
  set simulation_start_time ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; LOAD 2/2 ;;;;;;;;;;;;;;

to load2
  load-population
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;    GO    ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  let current-time ticks ; current-time is now directly in seconds
  if current-time >= max_evacuation_time [
    stop
  ]

  ; Update residents' movement
  ask residents with [not reached? and not dead?] [
    if ticks >= miltime [
      set moving? true
    ]
    if moving? [
      move-towards-shelter self
    ]
    if not evacuated? and current-time >= max_evac_time [
      mark-dead
    ]
  ]

  ask residents with [current-time >= max_evacuation_time] [
    mark-dead
  ]

  let total-agents (count residents + count pedestrians + count cars)
  let green-turtles (count turtles with [color = green])
  if total-agents > 0 [
    set green-percentage (green-turtles / total-agents) * 100
  ]

  if member? ticks [300 600 900 1200 1500 1800 2100 2400 2700] [
    ask residents [
      file-write (word ticks ", " green-percentage ", " dead? ", " [xcor] of shelter ", " [ycor] of shelter)
      file-print ""
    ]
  ]

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; END SIMULATION ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to end-simulation
  file-close
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
949
161
1373
314
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
1133
11
1212
44
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

MONITOR
949
54
1031
99
Time (min)
ticks / 60
1
1
11

PLOT
949
323
1374
497
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

BUTTON
949
11
1025
44
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

INPUTBOX
8
240
58
300
Rtau1_short
300.0
1
0
Number

INPUTBOX
57
240
107
300
Rsig1_short
120.0
1
0
Number

TEXTBOX
10
218
210
246
Evacuation Decsion Making Times:
12
0.0
1

INPUTBOX
83
84
154
144
Ped_Sigma
0.005
1
0
Number

MONITOR
1037
54
1119
99
Evacuated
count turtles with [ color = green ]
17
1
11

MONITOR
1126
54
1203
99
Casualty
count turtles with [ color = red ]
17
1
11

MONITOR
1073
108
1167
153
Mortality (%)
mortality_rate
2
1
11

BUTTON
1032
11
1126
44
READ (2/2)
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
104
240
154
300
Rtau2_long
600.0
1
0
Number

INPUTBOX
152
240
202
300
Rsig2_long
240.0
1
0
Number

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

MONITOR
949
108
1065
153
Per Evacuated (%)
count turtles with [ color = green ] / (count residents + count pedestrians + count cars) * 100
1
1
11

INPUTBOX
8
84
76
144
Ped_Speed
0.01
1
0
Number

TEXTBOX
10
66
160
84
Setup values:
12
0.0
1

TEXTBOX
10
302
99
343
Agents acting faster
10
0.0
1

TEXTBOX
108
302
258
320
Agents acting slower
10
0.0
1

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
