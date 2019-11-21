;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Variable & Breed Declarations ::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

globals [ allele-types global-tick-count ]

breed [ phenotypes phenotype ]
breed [ students student ]
breed [ alleles allele ]

students-own [ user-id phenotype-group generation-number gene-flow-student ]
phenotypes-own [ parent-student first-allele second-allele sex]
alleles-own [ parent-phenotype allele-type ]

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Setup ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to setup
  hubnet-reset
  clear-all
  ask patches [ set pcolor green ]
  setup-allele-types
  set global-tick-count 0
  reset-ticks
end

to setup-allele-types
  set allele-types []
  if allele-one-on? [ set allele-types lput "one" allele-types ]
  if allele-two-on? [ set allele-types lput "two" allele-types ]
  if allele-three-on? [ set allele-types lput "three" allele-types ]
  if allele-four-on? [ set allele-types lput "four" allele-types ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:            CREATE A STUDENT CLIENT AND SET PARAMETERS                      ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to create-new-student
  create-students 1
  [
    setup-student-vars
    send-info-to-clients
  ]
end

to setup-student-vars
  set user-id hubnet-message-source
  move-to one-of patches
  face one-of neighbors4
  set phenotype-group []
  set color pcolor
  set size 0.1
  set label user-id
  set generation-number 0
  set gene-flow-student nobody
  create-phenotype-group
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:       CREATE A PHENOTYPE INDIVIDUALS OF STUDENT AND SET PARAMETERS         ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to create-phenotype-group
  let parent self
  hatch-phenotypes individuals-per-group
  [
    set sex initialize-sex
    set first-allele initialize-allele
    set second-allele initialize-allele
    set size 2.0
    set label ""
    set-shape-and-color
    set parent-student parent
    set xcor (xcor + random-float group-radius - random-float group-radius)
    set ycor (ycor + random-float group-radius - random-float group-radius)
    ask parent [ set phenotype-group lput myself phenotype-group ]
  ]
end

to set-shape-and-color
  let dominance get-allele-dominance

  if dominance = "recessive-dominant" [
    set shape get-phenotype-shape
    set color [color] of second-allele ]

  if dominance = "dominant-recessive" [
    set shape get-phenotype-shape
    set color [color] of first-allele ]

  if dominance = "identical" [
    set shape get-phenotype-shape
    set color [color] of first-allele ]

  if dominance = "codominant" [
    set shape word get-phenotype-shape word " " [color] of second-allele
    set color [color] of first-allele ]
end

to-report get-allele-dominance
  if [allele-type] of first-allele = "one" and [allele-type] of second-allele = "one" [ report "identical" ]
  if [allele-type] of first-allele = "one" and [allele-type] of second-allele = "two" [ report allele-one-two-relationship ]
  if [allele-type] of first-allele = "one" and [allele-type] of second-allele = "three" [ report allele-one-three-relationship ]
  if [allele-type] of first-allele = "one" and [allele-type] of second-allele = "four" [ report allele-one-four-relationship ]

  if [allele-type] of first-allele = "two" and [allele-type] of second-allele = "one" [
    let d allele-one-two-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "two" and [allele-type] of second-allele = "two" [ report "identical" ]
  if [allele-type] of first-allele = "two" and [allele-type] of second-allele = "three" [ report allele-two-three-relationship ]
  if [allele-type] of first-allele = "two" and [allele-type] of second-allele = "four" [ report allele-two-four-relationship ]

  if [allele-type] of first-allele = "three" and [allele-type] of second-allele = "one" [
    let d allele-one-three-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "three" and [allele-type] of second-allele = "two" [
    let d allele-two-three-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "three" and [allele-type] of second-allele = "three" [ report "identical" ]
  if [allele-type] of first-allele = "three" and [allele-type] of second-allele = "four" [ report allele-three-four-relationship ]

  if [allele-type] of first-allele = "four" and [allele-type] of second-allele = "one" [
    let d allele-one-four-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "four" and [allele-type] of second-allele = "two" [
    let d allele-two-four-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "four" and [allele-type] of second-allele = "three" [
    let d allele-three-four-relationship
    if d = "codominant" [ report "codominant" ]
    if d = "dominant-recessive" [ report "recessive-dominant" ]
    if d = "recessive-dominant" [ report "dominant-recessive" ] ]
  if [allele-type] of first-allele = "four" and [allele-type] of second-allele = "four" [ report "identical" ]
end

to-report get-phenotype-shape
  if sex = "asexual" [ report "club" ]
  if sex = "male" [ report "spade" ]
  if sex = "female" [ report "heart" ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:              CREATE ALLELES OF PHENOTYPE AND SET PARAMETERS                ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to-report initialize-sex
  ifelse random-float 1.0 < sexual-to-asexual-ratio [
    report coin-flip-sex
  ][
    report "asexual"
  ]
end

to-report coin-flip-sex
  ifelse random-float 1.0 < 0.5 [ report "male" ][ report "female" ]
end

to-report initialize-allele
  let parent self
  let chosen-allele one-of allele-types
  let new-allele nobody
  hatch-alleles 1 [
    set size 1.0
    set label ""
    set shape "circle"
    set allele-type chosen-allele
    set color get-allele-color chosen-allele
    set new-allele self
    set parent-phenotype parent
  ]
  report new-allele
end

to-report get-allele-color [ type-input ]
  if type-input = "one" [ report read-from-string allele-one-color ]
  if type-input = "two" [ report read-from-string allele-two-color ]
  if type-input = "three" [ report read-from-string allele-three-color ]
  if type-input = "four" [ report read-from-string allele-four-color ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Runtime Procedures :::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to go
  listen-clients
  ask phenotypes [ wander ]
  ask students [ send-info-to-clients ]
  update-visibility-settings
  if reproduce-every > 0 [
    ifelse global-tick-count <= reproduce-every [
      set global-tick-count global-tick-count + 1 ]
    [ set global-tick-count 0
      ask students [execute-reproduce ]]
  ]
  tick
end

to update-visibility-settings
  ifelse show-alleles [
    ask alleles [ set hidden? false ]
    ask phenotypes [ set hidden? true ]
  ][
    ask alleles [ set hidden? true ]
    ask phenotypes [ set hidden? false ]
  ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Phenotype Procedures :::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to wander
    let new-patch nobody
    ask parent-student [
      set new-patch one-of patches in-radius group-radius
    ]
    face new-patch
    fd 1
    update-allele-positions
end

to update-allele-positions
  ask first-allele [ move-to one-of [neighbors] of myself ]
  ask second-allele [ move-to one-of [neighbors] of myself ]
end

to reproduce-asexually
  hatch-phenotypes ifelse-value (read-from-string selection-on-phenotype = color) [ offspring-per-parent * rate-of-selection ] [offspring-per-parent] [
    let me self
    ask parent-student [ set phenotype-group lput myself phenotype-group ]
    ask first-allele [ hatch-alleles 1 [
        set parent-phenotype me
        ask me [set first-allele myself ]]]
    ask second-allele [ hatch-alleles 1 [
        set parent-phenotype me
        ask me [set second-allele myself ]]]
    update-for-mutation
    set-shape-and-color
  ]
end

to reproduce-sexually
  let eligible-males get-eligible-males
  let mate nobody
  if length eligible-males > 0 [ set mate one-of eligible-males ]

  if mate != nobody [
    hatch-phenotypes ifelse-value (read-from-string selection-on-phenotype = color) [ offspring-per-parent * rate-of-selection ] [offspring-per-parent] [
      let me self
      ask parent-student [ set phenotype-group lput myself phenotype-group ]

      let allele-set []
      set allele-set lput first-allele allele-set
      set allele-set lput second-allele allele-set
      set allele-set lput [first-allele] of mate allele-set
      set allele-set lput [second-allele] of mate allele-set

      ask one-of allele-set [ hatch-alleles 1 [
          set parent-phenotype me
          ask me [set first-allele myself ]]]
      ask one-of allele-set [ hatch-alleles 1 [
          set parent-phenotype me
          ask me [set second-allele myself ]]]

      set sex coin-flip-sex
      set size 2.0
      set label ""
      update-for-mutation
      set-shape-and-color
    ]
  ]
end

to update-for-mutation
  if random-float 1.0 < mutation-rate [
    ask first-allele [ remove-allele ]
    set first-allele initialize-allele ]
  if random-float 1.0 < mutation-rate [
    ask second-allele [ remove-allele ]
    set second-allele initialize-allele ]
end

to-report get-eligible-males
  let eligible-males []

  ; GATHERS ALL MALES IN GROUP
  foreach (([phenotype-group] of parent-student)) [
    if [sex] of ? = "male" [
      set eligible-males lput ? eligible-males
    ]
  ]
  ; GATHERS ALL MALES IN ADJACENT GROUP
  if ([gene-flow-student] of parent-student != nobody) [
    foreach (([phenotype-group] of [gene-flow-student] of parent-student)) [
      if [sex] of ? = "male" [
        set eligible-males lput ? eligible-males
      ]
    ]
  ]
  report eligible-males
end

to remove-phenotype
  ask parent-student [ set phenotype-group remove myself phenotype-group ]
  ask first-allele [ remove-allele ]
  ask second-allele [ remove-allele ]
  die
end

to remove-allele
  die
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: HubNet Procedures ::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; DETERMINES WHICH CLIENT SENT A COMMAND
; AND WHAT THE COMMAND WAS
to listen-clients
  while [ hubnet-message-waiting? ]
  [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [ create-new-student ]
    [
      ifelse hubnet-exit-message?
      [ remove-student ]
      [
        ask students with [ user-id = hubnet-message-source ]
          [ execute-command hubnet-message-tag ]
      ]
    ]
  ]
end

; NETLOGO EXECUTES COMMANDS OF CLIENTS
;; Up    - make the turtle move up by 1 patch
;; Down  - make the turtle move down by 1 patch
;; Right - make the turtle move right by 1 patch
;; Left  - make the turtle move left by 1 patch
to execute-command [command]
  if command = "Up"
  [ execute-move 0 stop ]
  if command = "Down"
  [ execute-move 180 stop ]
  if command = "Right"
  [ execute-move 90 stop ]
  if command = "Left"
  [ execute-move 270 stop ]
  if command = "reproduce now"
  [ execute-reproduce ]
end

to send-info-to-clients
  hubnet-send user-id "YOU ARE GROUP:" user-id
  hubnet-send user-id "LOCATED AT:" (word "(" pxcor "," pycor ")")
  hubnet-send user-id "GENERATION:" generation-number

  if allow-gene-flow? [
    ifelse any? other students in-radius group-radius [
      set gene-flow-student one-of other students in-radius group-radius
      hubnet-send user-id "ADJACENT GROUP:" [user-id] of gene-flow-student
    ][
      set gene-flow-student nobody
      hubnet-send user-id "ADJACENT GROUP:" ""
    ]
  ]

  hubnet-send user-id "asexual count" count phenotypes with [ [user-id] of parent-student = [user-id] of myself and sex = "asexual" ]
  hubnet-send user-id "asexual %" precision (100 * ((count phenotypes with [ [user-id] of parent-student = [user-id] of myself and sex = "asexual" ]) / (count phenotypes with [ [user-id] of parent-student = [user-id] of myself] + .0001))) 3
  hubnet-send user-id "sexual count" count phenotypes with [ [user-id] of parent-student = [user-id] of myself and (sex = "male" or sex = "female") ]
  hubnet-send user-id "sexual %" precision (100 * ((count phenotypes with [ [user-id] of parent-student = [user-id] of myself and (sex = "male" or sex = "female") ]) / (count phenotypes with [ [user-id] of parent-student = [user-id] of myself] + .0001))) 3

  hubnet-send user-id "allele one count" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "one" ]
  hubnet-send user-id "allele two count" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "two" ]
  hubnet-send user-id "allele three count" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "three" ]
  hubnet-send user-id "allele four count" count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "four" ]

  hubnet-send user-id "allele one %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "one" ]) / (count alleles with [ member? parent-phenotype [phenotype-group] of myself] + .0001)) 3
  hubnet-send user-id "allele two %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "two" ]) / (count alleles with [ member? parent-phenotype [phenotype-group] of myself] + .0001)) 3
  hubnet-send user-id "allele three %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "three" ]) / (count alleles with [ member? parent-phenotype [phenotype-group] of myself] + .0001)) 3
  hubnet-send user-id "allele four %" precision (100 * (count alleles with [ member? parent-phenotype [phenotype-group] of myself and allele-type = "four" ]) / (count alleles with [ member? parent-phenotype [phenotype-group] of myself] + .0001)) 3

end

; STUDENTS MOVE IN CHOSEN DIRECTION
to execute-move [new-heading]
  set heading new-heading
  fd 1
end

; ALL ELIGIBLE PHENOTYPES IN STUDENT GROUP REPRODUCE
to execute-reproduce
  set generation-number generation-number + 1
  let old-phenotype-group phenotype-group
  foreach old-phenotype-group [
    if [sex] of ? = "asexual" [ ask ? [ reproduce-asexually ]]
    if [sex] of ? = "female" [ ask ? [ reproduce-sexually ]]
  ]
  foreach old-phenotype-group [ ask ? [remove-phenotype ]]
end

; REMOVE ALL AGENTS WHEN YOU CLOSE CLIENT WINDOW
to remove-student
  ask students with [user-id = hubnet-message-source]
  [
    foreach phenotype-group [ ask ? [ remove-phenotype ]]
    die
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
675
95
1161
602
-1
-1
11.61
1
10
1
1
1
0
1
1
1
0
40
0
40
1
1
1
ticks
30.0

BUTTON
762
54
840
87
NIL
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

BUTTON
677
54
754
87
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
479
218
660
251
allow-gene-flow?
allow-gene-flow?
0
1
-1000

TEXTBOX
476
142
669
160
---------- Mutation ------------
11
0.0
1

TEXTBOX
476
200
669
218
--------- Gene Flow ------------
11
0.0
1

TEXTBOX
477
259
669
277
------- Natural Selection --------
11
0.0
1

TEXTBOX
476
45
671
63
--------- Reproduction ---------
11
0.0
1

CHOOSER
156
63
285
108
allele-two-color
allele-two-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black" "white"
8

SLIDER
478
160
662
193
mutation-rate
mutation-rate
0
1.0
0
.01
1
NIL
HORIZONTAL

SLIDER
677
14
844
47
group-radius
group-radius
0
20
10
1
1
patches
HORIZONTAL

CHOOSER
479
277
659
322
selection-on-phenotype
selection-on-phenotype
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black" "white"
1

SLIDER
479
327
659
360
rate-of-selection
rate-of-selection
0
10
1
.1
1
NIL
HORIZONTAL

SLIDER
850
14
1020
47
individuals-per-group
individuals-per-group
0
50
5
1
1
NIL
HORIZONTAL

TEXTBOX
20
42
145
60
---- allele one ----
12
0.0
1

TEXTBOX
162
43
287
61
---- allele two ----\n
12
0.0
1

CHOOSER
13
61
144
106
allele-one-color
allele-one-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black" "white"
0

SLIDER
478
63
661
96
sexual-to-asexual-ratio
sexual-to-asexual-ratio
0
1.0
0.5
.01
1
NIL
HORIZONTAL

SWITCH
1027
14
1156
47
show-alleles
show-alleles
1
1
-1000

SLIDER
478
103
662
136
offspring-per-parent
offspring-per-parent
0
10
2
1
1
NIL
HORIZONTAL

CHOOSER
299
50
467
95
allele-one-two-relationship
allele-one-two-relationship
"dominant-recessive" "recessive-dominant" "codominant"
0

CHOOSER
299
102
467
147
allele-one-three-relationship
allele-one-three-relationship
"dominant-recessive" "recessive-dominant" "codominant"
2

CHOOSER
299
155
467
200
allele-one-four-relationship
allele-one-four-relationship
"dominant-recessive" "recessive-dominant" "codominant"
1

CHOOSER
299
208
467
253
allele-two-three-relationship
allele-two-three-relationship
"dominant-recessive" "recessive-dominant" "codominant"
0

CHOOSER
298
261
466
306
allele-two-four-relationship
allele-two-four-relationship
"dominant-recessive" "recessive-dominant" "codominant"
1

CHOOSER
298
314
466
359
allele-three-four-relationship
allele-three-four-relationship
"dominant-recessive" "recessive-dominant" "codominant"
0

SWITCH
13
111
144
144
allele-one-on?
allele-one-on?
0
1
-1000

SWITCH
157
112
285
145
allele-two-on?
allele-two-on?
0
1
-1000

SWITCH
13
278
146
311
allele-three-on?
allele-three-on?
0
1
-1000

SWITCH
157
278
285
311
allele-four-on?
allele-four-on?
0
1
-1000

CHOOSER
12
229
146
274
allele-three-color
allele-three-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black" "white"
3

CHOOSER
157
229
285
274
allele-four-color
allele-four-color
"red" "orange" "brown" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "black" "white"
1

TEXTBOX
16
209
150
227
---- allele three ----
12
0.0
1

TEXTBOX
162
209
300
227
---- allele four ----
12
0.0
1

TEXTBOX
306
17
466
35
ALLELE RELATIONSHIPS
14
0.0
1

TEXTBOX
496
17
646
35
EVOLUTION SETTINGS
14
0.0
1

PLOT
347
379
661
602
Allele Frequencies
time
allele %
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"one" 1.0 0 -16777216 true "" "set-plot-pen-color read-from-string allele-one-color plot 100 * (count alleles with [ allele-type = \"one\" ] / (count alleles + 1))"
"two" 1.0 0 -14737633 true "" "set-plot-pen-color read-from-string allele-two-color plot 100 * (count alleles with [ allele-type = \"two\" ] / (count alleles + 1))"
"three" 1.0 0 -12895429 true "" "set-plot-pen-color read-from-string allele-three-color plot 100 * (count alleles with [ allele-type = \"three\" ] / (count alleles + 1))"
"four" 1.0 0 -11053225 true "" "set-plot-pen-color read-from-string allele-four-color plot 100 * (count alleles with [ allele-type = \"four\" ] / (count alleles + 1))"

MONITOR
13
149
143
194
allele one count
count alleles with [ allele-type = \"one\" ]
17
1
11

MONITOR
157
150
285
195
allele two count
count alleles with [ allele-type = \"two\" ]
17
1
11

MONITOR
13
316
146
361
allele three count
count alleles with [ allele-type = \"three\" ]
17
1
11

MONITOR
157
316
285
361
allele four count
count alleles with [ allele-type = \"four\" ]
17
1
11

PLOT
16
379
330
602
Reproductive Strategies
time
asexual % or sexual %
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"sexual" 1.0 0 -14737633 true "" "plot 100 * (count phenotypes with [ sex = \"male\" or sex = \"female\" ] / (count phenotypes + 1))"
"asexual" 1.0 0 -5987164 true "" "plot 100 * (count phenotypes with [ sex = \"asexual\" ] / (count phenotypes + 1))"

TEXTBOX
105
16
204
34
ALLELE TYPES
14
0.0
1

BUTTON
847
54
972
87
reproduce now
ask students [ execute-reproduce ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
978
54
1159
87
reproduce-every
reproduce-every
0
100
0
1
1
ticks
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?


## HOW TO USE IT


## THINGS TO NOTICE


## THINGS TO TRY


## COPYRIGHT AND LICENSE

Copyright 2016 K N Crouse.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

circle
false
0
Circle -7500403 true true 0 0 300

club
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122

club 0
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -16777216 true false 88 103 124

club 105
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -13345367 true false 88 103 124

club 115
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -8630108 true false 88 103 124

club 125
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -5825686 true false 88 103 124

club 135
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -2064490 true false 88 103 124

club 15
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -2674135 true false 88 103 124

club 25
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -955883 true false 88 103 124

club 35
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -6459832 true false 88 103 124

club 45
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -1184463 true false 88 103 124

club 55
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -10899396 true false 88 103 124

club 65
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -13840069 true false 88 103 124

club 75
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -14835848 true false 88 103 124

club 85
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -11221820 true false 88 103 124

club 9.9
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -1 true false 88 103 124

club 95
true
0
Circle -7500403 true true 148 119 122
Circle -7500403 true true 30 119 122
Polygon -7500403 true true 134 137 135 253 121 273 105 284 195 284 180 273 165 253 159 138
Circle -7500403 true true 88 39 122
Circle -13791810 true false 88 103 124

heart
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135

heart 0
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -16777216 true false 86 71 127

heart 105
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -13345367 true false 86 71 127

heart 115
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -8630108 true false 86 71 127

heart 125
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -5825686 true false 86 71 127

heart 135
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -2064490 true false 86 71 127

heart 15
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -2674135 true false 86 71 127

heart 25
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -955883 true false 86 71 127

heart 35
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -6459832 true false 86 71 127

heart 45
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -1184463 true false 86 71 127

heart 55
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -10899396 true false 86 71 127

heart 65
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -13840069 true false 86 71 127

heart 75
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -14835848 true false 86 71 127

heart 85
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -11221820 true false 86 71 127

heart 9.9
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -1 true false 86 71 127

heart 95
true
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135
Circle -13791810 true false 86 71 127

spade
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210

spade 0
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -16777216 true false 83 98 134

spade 105
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -13345367 true false 83 98 134

spade 115
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -8630108 true false 83 98 134

spade 125
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -5825686 true false 83 98 134

spade 135
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -2064490 true false 83 98 134

spade 15
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -2674135 true false 83 98 134

spade 25
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -955883 true false 83 98 134

spade 35
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -6459832 true false 83 98 134

spade 45
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -1184463 true false 83 98 134

spade 55
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -10899396 true false 83 98 134

spade 65
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -13840069 true false 83 98 134

spade 75
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -14835848 true false 83 98 134

spade 85
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -11221820 true false 83 98 134

spade 9.9
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -1 true false 83 98 134

spade 95
true
0
Circle -7500403 true true 135 120 122
Polygon -7500403 true true 255 165 240 135 210 105 183 80 167 61 158 47 150 30 146 150
Circle -7500403 true true 43 120 122
Polygon -7500403 true true 45 165 60 135 90 105 117 80 133 61 142 47 150 30 154 150
Polygon -7500403 true true 135 210 135 253 121 273 105 284 195 284 180 273 165 253 165 210
Circle -13791810 true false 83 98 134

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
238
104
666
535
0
0
0
1
1
1
1
1
0
1
1
1
0
40
0
40

BUTTON
91
87
153
120
Up
NIL
NIL
1
T
OBSERVER
NIL
I

BUTTON
91
153
153
186
Down
NIL
NIL
1
T
OBSERVER
NIL
K

BUTTON
153
120
215
153
Right
NIL
NIL
1
T
OBSERVER
NIL
L

BUTTON
29
120
91
153
Left
NIL
NIL
1
T
OBSERVER
NIL
J

MONITOR
146
12
243
61
LOCATED AT:
NIL
3
1

MONITOR
17
12
136
61
YOU ARE GROUP:
NIL
3
1

MONITOR
361
12
503
61
ADJACENT GROUP:
NIL
3
1

BUTTON
522
13
649
62
reproduce now
NIL
NIL
1
T
OBSERVER
NIL
R

MONITOR
253
12
350
61
GENERATION:
NIL
3
1

MONITOR
124
198
225
247
asexual %
NIL
5
1

MONITOR
124
252
225
301
sexual %
NIL
3
1

MONITOR
124
306
225
355
allele one %
NIL
3
1

MONITOR
17
306
117
355
allele one count
NIL
3
1

MONITOR
124
361
225
410
allele two %
NIL
3
1

MONITOR
17
361
117
410
allele two count
NIL
3
1

MONITOR
124
415
226
464
allele three %
NIL
3
1

MONITOR
17
415
117
464
allele three count
NIL
3
1

MONITOR
124
469
226
518
allele four %
NIL
3
1

MONITOR
17
469
117
518
allele four count
NIL
3
1

MONITOR
17
198
117
247
asexual count
NIL
3
1

MONITOR
17
252
117
301
sexual count
NIL
3
1

TEXTBOX
19
67
661
85
----------------------------------------------------------------------------------------------------------
11
0.0
1

TEXTBOX
48
515
198
533
NIL
11
0.0
1

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
