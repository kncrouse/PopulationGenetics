;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Variable & Breed Declarations ::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

globals [
  allele-types ; list of alleles used for this simulation
  generation-number ; current generation
  population-radius ; size that the population occupies in the world
]

breed [ organisms organism ]
breed [ populations population ]
breed [ alleles allele ]

populations-own [
  hubnet-client? ; true = hubnet client user ; false = npc population
  user-id ; id that connects each population to the hubnet control center
  gene-flow-populations ; populations of adjacent populations for gene flow during reproduction
]

organisms-own [
  my-generation ; generation number when they were born
  parent-population ; population that includes this organism
  first-allele ; first allele of diploid organism
  second-allele ; second allele of diploid organism
]

alleles-own [
  parent-organism ; the organism to which this allele belongs
  allele-type ; gui settings determine which type matches which color
]

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Setup ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to startup
  hubnet-reset
  setup
end

to setup
  clear-all-plots
  setup-parameters
  ask patches [ set pcolor 87 ]
  ask populations [ setup-population ]
  update-interface-plots
  reset-ticks
end

to setup-parameters
  update-allele-types-list
  set population-radius sqrt ( 3 * population-size )
  set generation-number 0
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:            CREATE A POPULATION AND SET VARIABLES                           ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; create a new population and connect to hubnet
to create-new-hubnet-population
  create-populations 1 [
    set user-id hubnet-message-source
    set hubnet-client? true
    setup-population
    send-info-to-clients
  ]
end

; create a new npc wandering population
to create-new-population
  create-populations 1 [ ; NOTE: the space after 'Wu' is important because the code requires names to have a minimum length of 3 characters
    set user-id one-of [ "Walker" "McCann" "Bennett" "Kieper" "Driver" "Rowe" "Smith" "Hollenbeck" "Chang" "Moore" "Wu " "McEwan" "Ortner" "Kennedy" "Anderson" "Roeder" "Paulsen" ] ; see Huerta-Sánchez, Rohlfs et al. 2019
    if any? other populations with [ substring user-id 0 3 = substring [user-id] of myself 0 3 ]
        [ set user-id (word user-id " " count populations with [ substring user-id 0 3 = substring [user-id] of myself 0 3 ])]
    set hubnet-client? false
    setup-population
  ]
end

; general population settings
to setup-population
  move-to one-of patches
  ask organisms with [ parent-population = myself ] [ remove-organism ]
  set color pcolor
  set size 0
  set shape "clown"
  set gene-flow-populations no-turtles
  create-organism-population
  set label user-id
  set label-color black
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:       CREATE A ORGANISMS OF POPULATION AND SET VARIABLES                   ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to create-organism-population

  ; this code ensures that initial populations have an even distribution of allele types
  let total-allele-count 2 * population-size
  let allele-type-list []
  let index 0
  while [ total-allele-count > 0 ] [
    set allele-type-list lput item index allele-types allele-type-list
    set total-allele-count total-allele-count - 1
    set index index + 1
    if index = length allele-types [ set index 0 ]]

  let item-index 0
  let parent self
  hatch-organisms population-size
  [
    set first-allele initialize-allele item item-index allele-type-list
    set item-index item-index + 1
    set second-allele initialize-allele item item-index allele-type-list
    set item-index item-index + 1
    set parent-population parent
    move-to parent-population move-to one-of patches in-radius ( population-radius * 0.75 )
    setup-organism
  ]
end

; general organism settings
to setup-organism
  set size 3
  set label ""
  set hidden? show-alleles
  set-organism-shape-and-color
  set xcor xcor + random-float 1 - random-float 1
  set ycor ycor + random-float 1 - random-float 1
  set my-generation generation-number + 1
end

; set the shape and color of organism based on alleles
to set-organism-shape-and-color
  let dominance get-allele-dominance-relationship [allele-type] of first-allele [allele-type] of second-allele
  set shape "clown"
  if dominance = "recessive-dominant" [ set color [color] of second-allele ]
  if dominance = "dominant-recessive" [ set color [color] of first-allele ]
  if dominance = "identical" [ set color [color] of first-allele ] ; this is techincally unnecessary and could be removed along with ... (*)
  if dominance = "codominant" [
    set shape word "clown" word " " [color] of second-allele
    set color [color] of first-allele ]
end

; reports the dominance status of the two alleles of a organism based on gui settings
; the above and below functions could probably be consolidated
to-report get-allele-dominance-relationship [ allele1 allele2 ]
  if ( allele1 = allele2 ) [ report "identical" ] ; (*) ... this line here.

  let dominance1
  (ifelse-value
    ( allele1 = "one" ) [ allele-one-dominance ]
    ( allele1 = "two" ) [ allele-two-dominance ]
    ( allele1 = "three" ) [ allele-three-dominance ]
    ( allele1 = "four" ) [ allele-four-dominance ]
    [ "" ])

  let dominance2
  (ifelse-value
    ( allele2 = "one" ) [ allele-one-dominance ]
    ( allele2 = "two" ) [ allele-two-dominance ]
    ( allele2 = "three" ) [ allele-three-dominance ]
    ( allele2 = "four" ) [ allele-four-dominance ]
    [ "" ])

  if ( dominance1 = "dominant" and dominance2 = "dominant" ) [ report "codominant" ]
  if ( dominance1 = "dominant" and dominance2 = "recessive" ) [ report "dominant-recessive" ]
  if ( dominance1 = "recessive" and dominance2 = "dominant" ) [ report "recessive-dominant" ]
  if ( dominance1 = "recessive" and dominance2 = "recessive" ) [ report "codominant" ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:              CREATE ALLELES OF ORGANISM AND SET VARIABLES                  ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; create random allele, add to organism, and report
to-report initialize-allele [ atype ]
  let parent self
  let allele-to-report nobody
  hatch-alleles 1 [
    set allele-type atype
    setup-allele
    set parent-organism parent
    set allele-to-report self
  ]
  report allele-to-report
end

; general allele settings
to setup-allele
  set size 1
  set label ""
  set shape "circle"
  set parent-organism nobody
  update-allele-color
  set hidden? not show-alleles
end

; get the color of given allele based on gui settings
to update-allele-color
  set color read-from-string get-allele-color-string allele-type
end

; reported results depend on gui
to-report get-allele-color-string [ type-input ]
  if type-input = "one" [ report allele-one-color ]
  if type-input = "two" [ report allele-two-color ]
  if type-input = "three" [ report allele-three-color ]
  if type-input = "four" [ report allele-four-color ]
end

; reported results depend on gui
to-report get-allele-dominance [ type-input ]
  if type-input = "one" [ report allele-one-dominance ]
  if type-input = "two" [ report allele-two-dominance ]
  if type-input = "three" [ report allele-three-dominance ]
  if type-input = "four" [ report allele-four-dominance ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Runtime Procedures :::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to go
  listen-clients
  ask populations [ population-wander ]
  ask populations [ set gene-flow-populations get-adjacent-populations ]
  ask organisms [ organism-wander ]
  update-visibility-settings
  update-organism-shape-and-color
  update-allele-types-list
  ask populations with [ hubnet-client? = true ] [ send-info-to-clients ]
  ask alleles [ update-allele-color ]
  tick
end

; obsever command to update whether organisms or alleles are visible
to update-visibility-settings
  ask alleles [ set hidden? not show-alleles ]
  ask organisms [ set hidden? show-alleles ]
end

; observer command to update the "organism" of all organisms
to update-organism-shape-and-color
  ask organisms [ set-organism-shape-and-color ]
end

to-report to-upper-case [ input-letter ]
  let index position input-letter [ "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" ]
  report item index [ "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" ]
end

; create a list based on which alleles are turned on in gui settings
to update-allele-types-list
  set allele-types []
  if allele-one-on? [ set allele-types lput "one" allele-types ]
  if allele-two-on? [ set allele-types lput "two" allele-types ]
  if allele-three-on? [ set allele-types lput "three" allele-types ]
  if allele-four-on? [ set allele-types lput "four" allele-types ]
  if empty? allele-types [ set allele-one-on? true update-allele-types-list ]
  ask alleles with [ not member? allele-type allele-types ] [ set allele-type one-of allele-types ]
end

to execute-reproduce
  ask populations [ population-reproduce ]
  ask organisms with [ my-generation = generation-number ] [ remove-organism ]
  set generation-number generation-number + 1
  update-interface-plots
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:                     POPULATION RUNTIME PROCEDURES                          ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to population-wander
  set xcor mean [xcor] of organisms with [ parent-population = myself ]
  set ycor mean [ycor] of organisms with [ parent-population = myself ]
end

; population command to move in given direction
to execute-move [new-heading]
  set heading new-heading
  fd 1
  ask organisms with [ parent-population = myself ] [ set heading new-heading fd 1 ]
end

to-report get-adjacent-populations
  let reporter no-turtles
  if any? other populations in-radius ( population-radius * 1.5 )  [
    set reporter other populations in-radius ( population-radius * 1.5 ) ]
  report reporter
end

; population reproduces to maintain population carrying capacity set by POPULATION-SIZE
to population-reproduce
  while [count organisms with [ my-generation = generation-number + 1 and parent-population = myself ] < population-size]  [
    ask one-of organisms with [ my-generation = generation-number and parent-population = myself ] [ reproduce get-mate-in-gene-pool ]
  ]
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:                   ORGANISM & ALLELE RUNTIME PROCEDURES                     ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; organism command to move position
to organism-wander
  let patchy one-of patches in-cone population-radius 30 with [ distance [parent-population] of myself <= population-radius ]
  ifelse patchy = nobody [ face parent-population ] [ face patchy ]
  fd 0.05
  update-allele-positions
end

; organism command to update both allele positions
to update-allele-positions
  ask first-allele [ move-to myself set heading [heading] of myself rt 45 fd 0.5 ]
  ask second-allele [ move-to myself set heading [heading] of myself lt 135 fd 0.5 ]
end

; organism command to create offspring from alleles of self and mate
to reproduce [ mate ]
  let number-of-offspring ifelse-value (read-from-string selection-on-phenotype = color) [( floor rate-of-selection ) + ifelse-value ( random-float 1.0 < ( rate-of-selection - floor rate-of-selection ) ) [ 1 ] [ 0 ]] [1] ; natural selection
  let current-offspring-count 0
  while [ current-offspring-count < number-of-offspring and count organisms with [ my-generation = generation-number + 1 and parent-population = [parent-population] of myself ] < population-size ] [
    hatch-organisms 1 [
      set first-allele initialize-allele one-of (sentence [allele-type] of first-allele [allele-type] of second-allele )
      set second-allele initialize-allele one-of (sentence [allele-type] of [first-allele] of mate [allele-type] of [second-allele] of mate )
      update-for-mutation
      setup-organism ]
    set current-offspring-count current-offspring-count + 1 ]
end

; organism command to find someone to mate with
to-report get-mate-in-gene-pool
  let mate-to-report nobody
  ifelse ( gene-flow-between-populations and [gene-flow-populations] of parent-population != no-turtles ) [
    set mate-to-report one-of organisms with [ my-generation = generation-number and parent-population = [parent-population] of myself or member? parent-population [gene-flow-populations] of [parent-population] of myself ]
  ][
    set mate-to-report one-of organisms with [ my-generation = generation-number and parent-population = [parent-population] of myself ]
  ]
  report mate-to-report
end

; organism command to mutate alleles based on given gui rate
to update-for-mutation
  if random-float 1.0 < mutation-rate [
    ask first-allele [ remove-allele ]
    set first-allele initialize-allele one-of allele-types ]
  if random-float 1.0 < mutation-rate [
    ask second-allele [ remove-allele ]
    set second-allele initialize-allele one-of allele-types ]
end

; remove organism from the world
to remove-organism
  ask first-allele [ remove-allele ]
  ask second-allele [ remove-allele ]
  die
end

; remove allele from the world
to remove-allele
  die
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:                            HubNet Procedures                               ::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

; DETERMINES WHICH CLIENT SENT A COMMAND AND WHAT THE COMMAND WAS
to listen-clients
  while [ hubnet-message-waiting? ]
  [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [ create-new-hubnet-population ]
    [
      ifelse hubnet-exit-message?
      [ remove-population ]
      [
        ask populations with [ user-id = hubnet-message-source ]
          [ execute-command hubnet-message-tag ]
      ]
    ]
  ]
end

; REMOVE ALL AGENTS WHEN YOU CLOSE CLIENT WINDOW
to remove-population
  ask populations with [user-id = hubnet-message-source]
  [
    ask organisms with [ parent-population = myself ] [ remove-organism ]
    die
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
end

; population command to send information to corresponding client gui
to send-info-to-clients

  let my-organisms organisms with [ parent-population = myself ]
  hubnet-send user-id "YOU ARE POPULATION" user-id
  hubnet-send user-id "LOCATION" (word "(" pxcor "," pycor ")")
  hubnet-send user-id "GENERATION" generation-number

  ; ADJACENT POPULATIONS
  let adjacent-populations ""
  foreach sort gene-flow-populations [ s -> set adjacent-populations (word " " [user-id] of s "," adjacent-populations ) ]
  if length adjacent-populations > 2 [ set adjacent-populations but-first but-last adjacent-populations ]
  hubnet-send user-id "ADJACENT POPULATIONS" ifelse-value ( gene-flow-populations = no-turtles ) [ "" ] [ adjacent-populations ]

  ; ALLELES
  let alleles-string ""
  foreach allele-types [ t1 ->
    let allele-letter first get-allele-color-string t1
    set allele-letter ifelse-value ( get-allele-dominance t1 = "dominant" ) [ to-upper-case allele-letter ] [ allele-letter ]
    let allele-count count alleles with [ member? parent-organism my-organisms and allele-type = t1 ]
    set alleles-string (word alleles-string allele-letter ": " allele-count "    ") ]
  hubnet-send user-id "ALLELE FREQUENCIES" alleles-string

  ; GENOTYPES
  let genotypes-string ""
  let allele-types-list allele-types
  foreach allele-types [ t1 ->
    foreach allele-types-list [ t2 ->
      let allele-letter-1 first get-allele-color-string t1
      set allele-letter-1 ifelse-value ( get-allele-dominance t1 = "dominant" ) [ to-upper-case allele-letter-1 ] [ allele-letter-1 ]
      let allele-letter-2 first get-allele-color-string t2
      set allele-letter-2 ifelse-value ( get-allele-dominance t2 = "dominant" ) [ to-upper-case allele-letter-2 ] [ allele-letter-2 ]
      let genotype-count count organisms with [ member? self my-organisms and (( [allele-type] of first-allele = t1 and [allele-type] of second-allele = t2 ) or ( [allele-type] of first-allele = t2 and [allele-type] of second-allele = t1 ))]
      set genotypes-string (word genotypes-string allele-letter-1 allele-letter-2 ": " genotype-count "    ") ]
    set allele-types-list remove-item 0 allele-types-list ]
  hubnet-send user-id "GENOTYPE FREQUENCIES" genotypes-string
end

;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::: Plots ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

to update-interface-plots
  let color-list [ "red" "orange" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" ]

  ; ALLELE VARIATION WITHIN POPULATION
  set-current-plot "Genetic Variation per Population"
  clear-plot
  let index 0
  foreach sort populations [ p ->
    let this-current-population p
    let sum-of-squares 0
    foreach allele-types [ atype -> set sum-of-squares sum-of-squares + (( count alleles with [ allele-type = atype and [parent-population] of parent-organism = this-current-population ] / ( 2 * population-size )) ^ 2)]
    let simpsons-diversity 1 - sum-of-squares
    set-current-plot-pen "default"
    let index-2 0
    repeat 90 [
      plot-pen-down
      plotxy ( index + 0.1 + index-2 ) simpsons-diversity
      set index-2 index-2 + 0.01
      plot-pen-up ]
    set index index + 1 ]

  ; PROPORTION OF ALLELES WITHIN POPULATION
  set-current-plot "Proportion of Alleles Per Population"
  clear-plot
  set index 0
  foreach sort populations [ p ->
    let this-current-population p
    let allele-frequency-so-far count alleles with [ [parent-population] of parent-organism = this-current-population ]
    foreach color-list [ clr ->
      if ( count alleles with [ get-allele-color-string allele-type = clr and [parent-population] of parent-organism = this-current-population ] > 0 ) [
        set-current-plot-pen clr
        let index-2 0
        repeat 90 [
          plot-pen-down
          plotxy ( index + 0.1 + index-2 ) (allele-frequency-so-far / (2 * population-size))
          set index-2 index-2 + 0.01
          plot-pen-up ]
        set allele-frequency-so-far allele-frequency-so-far - ( count alleles with [ get-allele-color-string allele-type = clr and [parent-population] of parent-organism = this-current-population ])
      ]
    ]
    set index index + 1 ]

  ; PROPORTION OF ALL ALLELES OVER GENERATIONS
  set-current-plot "Proportion of Alleles Over Generations"
  let allele-frequency-so-far count alleles
  foreach color-list [ clr ->
    if ( count alleles with [ get-allele-color-string allele-type = clr ] > 0 ) [
      set-current-plot-pen clr
      let index-2 0
      repeat 100 [
        plot-pen-down
        plotxy ( generation-number + index-2 ) ( allele-frequency-so-far / count alleles )
        set index-2 index-2 + 0.01
        plot-pen-up ]
      set allele-frequency-so-far allele-frequency-so-far - ( count alleles with [ get-allele-color-string allele-type = clr ])
    ]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
281
10
1068
798
-1
-1
19.0
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
1180
10
1287
43
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
1085
10
1175
43
reset
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
12
541
265
574
gene-flow-between-populations
gene-flow-between-populations
0
1
-1000

SLIDER
12
500
265
533
mutation-rate
mutation-rate
0
1.0
0.01
.01
1
NIL
HORIZONTAL

CHOOSER
12
582
265
627
selection-on-phenotype
selection-on-phenotype
"red" "orange" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray"
2

SLIDER
12
635
265
668
rate-of-selection
rate-of-selection
0
5
1.0
.1
1
NIL
HORIZONTAL

SWITCH
1085
92
1251
125
show-alleles
show-alleles
1
1
-1000

SWITCH
12
43
264
76
allele-one-on?
allele-one-on?
0
1
-1000

SWITCH
12
137
264
170
allele-two-on?
allele-two-on?
0
1
-1000

SWITCH
12
231
264
264
allele-three-on?
allele-three-on?
0
1
-1000

TEXTBOX
63
430
213
448
EVOLUTION SETTINGS
14
0.0
1

TEXTBOX
72
14
198
32
ALLELE SETTINGS
14
0.0
1

BUTTON
1292
10
1423
43
reproduce
execute-reproduce
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
293
24
374
69
Generation
generation-number
17
1
11

MONITOR
949
22
1055
67
Total Population
count organisms
17
1
11

BUTTON
1259
92
1423
125
add population
create-new-population
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
12
460
265
493
population-size
population-size
10
100
10.0
5
1
NIL
HORIZONTAL

PLOT
1085
340
1424
535
Proportion of Alleles per Population
population
proportion of alleles
0.0
6.0
0.0
1.0
true
false
"" ""
PENS
"red" 0.01 1 -2674135 false "" ""
"orange" 0.01 1 -955883 true "" ""
"yellow" 0.01 1 -1184463 true "" ""
"lime" 0.01 1 -13840069 true "" ""
"turquoise" 0.01 1 -14835848 true "" ""
"cyan" 0.01 1 -11221820 true "" ""
"sky" 0.01 1 -13791810 true "" ""
"blue" 0.01 1 -13345367 true "" ""
"violet" 0.01 1 -8630108 true "" ""
"magenta" 0.01 1 -5825686 true "" ""
"pink" 0.01 1 -2064490 true "" ""
"gray" 0.01 1 -7500403 true "" ""

PLOT
1085
545
1424
740
Proportion of Alleles Over Generations
generation
proportion of alleles
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"red" 0.01 1 -2674135 false "" ""
"orange" 0.01 1 -955883 false "" ""
"yellow" 0.01 1 -4079321 false "" ""
"lime" 0.01 1 -13840069 false "" ""
"turquoise" 0.01 1 -14835848 false "" ""
"cyan" 0.01 1 -11221820 false "" ""
"sky" 0.01 1 -13791810 false "" ""
"blue" 0.01 1 -13345367 false "" ""
"violet" 0.01 1 -8630108 false "" ""
"magenta" 0.01 1 -5825686 false "" ""
"pink" 0.01 1 -2064490 false "" ""
"gray" 0.01 0 -7500403 true "" ""

PLOT
1085
136
1423
331
Genetic Variation per Population
population
Simpson's Diversity
0.0
6.0
0.0
1.0
true
false
"" ""
PENS
"default" 0.01 1 -16777216 false "" ""

CHOOSER
12
80
121
125
allele-one-color
allele-one-color
"red" "orange" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray"
0

CHOOSER
12
174
121
219
allele-two-color
allele-two-color
"red" "orange" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray"
7

CHOOSER
12
268
121
313
allele-three-color
allele-three-color
"red" "orange" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray"
2

CHOOSER
125
80
264
125
allele-one-dominance
allele-one-dominance
"dominant" "recessive"
0

CHOOSER
125
174
264
219
allele-two-dominance
allele-two-dominance
"dominant" "recessive"
1

CHOOSER
125
268
264
313
allele-three-dominance
allele-three-dominance
"dominant" "recessive"
0

SWITCH
12
327
265
360
allele-four-on?
allele-four-on?
1
1
-1000

CHOOSER
12
365
121
410
allele-four-color
allele-four-color
"red" "orange" "yellow" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray"
1

CHOOSER
125
365
265
410
allele-four-dominance
allele-four-dominance
"dominant" "recessive"
1

SLIDER
1259
51
1423
84
reproduce-every
reproduce-every
0
100
50.0
10
1
ticks
HORIZONTAL

BUTTON
1085
51
1251
84
reproduce continuously
if ( ticks > 0 and ceiling ( ticks / reproduce-every ) = ticks / reproduce-every ) [\nexecute-reproduce\n]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
# Population Genetics 2.0.0

## WHAT IS IT?

This model simulates how the mechanisms of biological evolution shape emergent evolutionary patterns - how allele frequencies change in a population over time. Patterns in between- and within-population variation are expected to emerge in the simulation in correspondance with the parameter settings, which determine how the mechanisms of evolution (genetic drift, gene flow, mutation, and natural selection) operate.

During a simulation, "students" control populations of fish organisms via a HubNet Client and a "teacher" controls the environment via the HubNet Control Center. Teachers can set up to four alleles at the locus coding for fish color. A fish color phenotype is based on its genotype and the allele relationship parameter settings (i.e. dominant or recessive). The user interface plots show how the allele frequencies within and between populations change over generations.

## HOW IT WORKS

### TEACHER: HubNet Control Center

STARTUP: The HubNet Control Center should start upon opening this model. Change any of the paramater settings depending on what aspect of evolution you want to simulate. Press the GO button.

INSTRUCTIONS FOR YOUR STUDENTS: Instruct your students to open the NetLogo HubNet Client application, type their user name, select this activity and press ENTER. Make sure that they choose the correct port number and server address for this simulation. Once they enter the simulation, a new fish population is created and assigned to them. Instruct your students to move their populations around to acquaint themselves with the interface. Instructors can also press the ADD POPULATION button to create another "non-playable" population in the world.

SIMULATION: Press the REPRODUCE button to cause each population in the simulation to reproduce. Investigate how the allele frequencies have changed and instruct your students to record the specifics for their population as shown in their HubNet Client. Continue to press the REPRODUCE button and record how the EVOLUTION SETTINGS affect how the populations change over time. Modify the EVOLUTION SETTINGS as needed to change the environmental factors.

### STUDENT: HubNet Client

STARTUP: Students should open the NetLogo HubNet Client application, type their user name, select this activity and press ENTER. Make sure to choose the correct port number and server address for this simulation.

After logging in, the client interface will appear for the students, and if GO is pressed in NetLogo they will be assigned a population of fish, which should appear on the interface. The YOU ARE POPULATION monitor displays the name entered upon startup and will also appear on the simulation to label the appropriate population. The current location of the population is shown in the LOCATION monitor.

SIMULATION: Students are able to control the movement of their population with the UP, DOWN, LEFT, and RIGHT buttons. HubNet Client monitors show the current allele and genotype frequencies, as well as the current generation and closest adjacent populations.

## HOW TO USE IT

### GENERAL

SETUP: returns the model to the starting state.

GO: runs the simulation.

REPRODUCE: all fish organisms reproduce with someone else in their gene pool.

REPRODUCE CONTINUOUSLY: when pressed, executes the reproduce function at a time interval determined by REPRODUCE-EVERY slider. 

SHOW-ALLELES: when on, the alleles of the population are shown, otherwise the individual fish are shown, the phenotypes of which are based on the allele dominance parameter settings.

ADD POPULATION: when pressed, a new "non-playable" fish population is added to the world. It wanders randomly and its fish organisms can reproduce and share alleles with adjacent populations.

### ALLELE SETTINGS

ALLELE-X-ON?: allows the given allele type to possiblely exist in the enivornment.

ALLELE-X-COLOR: parameter setting determines what color this allele appears as.

ALLELE-X-DOMINANCE: parameter setting determines whether allele is dominant or recessive.

### EVOLUTION SETTINGS

POPULATION-SIZE: the current size of each population, which can be thought of as a fixed carrying capacity.

MUTATION-RATE: the rate at which alleles mutate to a random allele upon reproduction.

GENE-FLOW-BETWEEN-POPULATIONS: when on, allows populations that are close enough to an ADJACENT POPULATION to share alleles upon reproduction.

SELECTION-ON-PHENOTYPE: selects the phenotype color that natural selection can act upon during the simulation.

RATE-OF-SELECTION: for a phenotype that matches the currently set SELECTION-ON-PHENOTYPE this sets the average number of offspring that phenotype will have when they reproduce.

### MONITORS & PLOTS

GENERATION: the current generation of the populations in the simulation.

TOTAL POPULATION: the number of phenotypes from all populations in the simulation.

GENETIC VARIATION PER POPULATION: each bar represents a population's calculation of Simpson's Diversity on allele types.

PROPORTION OF ALLELES PER POPULATION: each bar represents a population broken into sections of color to represent the proportionate amount of each allele type.

PROPORTION OF ALLELES OVER GENERATIONS: shows the proportion of each allele type for each generation that the simulation has produced.

## THINGS TO NOTICE

MUTATION RATE: How does the MUTATION-RATE setting change the alleles? How does it change within population and between population variation?

GENE FLOW: How does the ALLOW-GENE-FLOW? setting change the alleles? How does it change within population and between population variation?

NATURAL SELECTION: How do the SELECTION-ON-PHENOTYPE and RATE-OF-SELECTION settings change the alleles? How do they change within population and between population variation?

GENETIC DRIFT: Notice that there are no settings for genetic drift, the fourth mechanism of evolution. Unlike the other mechanisms, genetic drift can never be turned off!

## THINGS TO TRY

Use the model with students to serve as an introduction to population genetics. Be sure to modify the EVOLUTION SETTINGS to simulate how different mechanisms can affect the allele frequencies and variation both within and between populations.

1. Vary the POPULATION-SIZE to explore how genetic drift affects very large and very small populations.

2. Change very large populations to very small populations to explore bottleneck or founder's effects.

3. Increase the MUTATION-RATE to a non-zero number to see how novelle mutations invade a population (or don't).

4. Turn on GENE-FLOW-BETWEEN-POPULATIONS and move populations within range of each other to see how populations share alleles during reproduction.

5. Use SELECTION-ON-PHENOTYPE to choose a color that environmental selective pressures are acting on and move the slider RATE-OF-SELECTION to a value higher than one if the selective pressures favor this phenotype, and to a value lower than one if the selective pressures do not favor this phenotype. Observe how your choices affect the prevalance of that allele over generations.

## POPULATION NAMES

The names generated during ADD POPULATION are taken from Huerta-Sánchez, Rohlfs and collegues' work on revealing the hidden female contributions to population genetics:

Dung, S. K., López, A., Barragan, E. L., Reyes, R. J., Thu, R., Castellanos, E., Catalan, F., Huerta-Sánchez, E. & Rohlfs, R. V. (2019). Illuminating Women’s Hidden Contribution to Historical Theoretical Population Genetics. Genetics, 211(2), 363-366.

## HOW TO CITE

Crouse, Kristin (2020). “Population Genetics” (Version 2.0.0). CoMSES Computational Model Library. Retrieved from: https://www.comses.net/codebases/6040/releases/2.0.0/

## COPYRIGHT AND LICENSE

© 2020 K N Crouse

This model was created at the University of Minnesota as part of a series of models to illustrate principles in biological evolution.

The model may be freely used, modified and redistributed provided this copyright is included and the resulting models are not used for profit.

Contact K N Crouse at crou0048@umn.edu if you have questions about its use.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

circle
false
0
Circle -7500403 true true 0 0 300

clown
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121

clown 105
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -13345367 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -13345367 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -13345367 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 115
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -8630108 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -8630108 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -8630108 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 125
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -5825686 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -5825686 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -5825686 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 135
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -2064490 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -2064490 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -2064490 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 15
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -2674135 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -2674135 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -2674135 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 25
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -955883 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -955883 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -955883 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 35
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -6459832 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -6459832 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -6459832 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 45
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -1184463 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1184463 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1184463 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 5
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -7500403 true true 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -7500403 true true 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -7500403 true true 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 55
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -10899396 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -10899396 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -10899396 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 65
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -13840069 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -13840069 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -13840069 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 75
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -14835848 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -14835848 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -14835848 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 85
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -11221820 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -11221820 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -11221820 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

clown 95
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -13791810 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -13791810 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -13791810 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

fish 2
false
0
Polygon -1 true false 56 133 34 127 12 105 21 126 23 146 16 163 10 194 32 177 55 173
Polygon -7500403 true true 156 229 118 242 67 248 37 248 51 222 49 168
Polygon -7500403 true true 30 60 45 75 60 105 50 136 150 53 89 56
Polygon -7500403 true true 50 132 146 52 241 72 268 119 291 147 271 156 291 164 264 208 211 239 148 231 48 177
Circle -1 true false 237 116 30
Circle -16777216 true false 241 127 12
Polygon -1 true false 159 228 160 294 182 281 206 236
Polygon -7500403 true true 102 189 109 203
Polygon -1 true false 215 182 181 192 171 177 169 164 152 142 154 123 170 119 223 163
Line -16777216 false 240 77 162 71
Line -16777216 false 164 71 98 78
Line -16777216 false 96 79 62 105
Line -16777216 false 50 179 88 217
Line -16777216 false 88 217 149 230
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
14
234
540
785
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
387
17
449
50
Up
NIL
NIL
1
T
OBSERVER
NIL
I

BUTTON
387
112
449
145
Down
NIL
NIL
1
T
OBSERVER
NIL
K

BUTTON
449
64
511
97
Right
NIL
NIL
1
T
OBSERVER
NIL
L

BUTTON
325
64
387
97
Left
NIL
NIL
1
T
OBSERVER
NIL
J

MONITOR
177
10
295
59
LOCATION
NIL
3
1

MONITOR
14
10
170
59
YOU ARE POPULATION
NIL
3
1

MONITOR
14
64
295
113
ADJACENT POPULATIONS
NIL
3
1

MONITOR
25
247
120
296
GENERATION
NIL
3
1

TEXTBOX
187
795
337
813
NIL
11
0.0
1

MONITOR
14
118
295
167
ALLELE FREQUENCIES
NIL
3
1

MONITOR
14
172
536
221
GENOTYPE FREQUENCIES
NIL
3
1

TEXTBOX
556
463
579
551
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
