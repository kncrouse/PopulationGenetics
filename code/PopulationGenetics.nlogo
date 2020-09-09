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
  update-interface-plots
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

  let parent self
  hatch-organisms population-size
  [
    let item-index random length allele-type-list
    set first-allele initialize-allele item item-index allele-type-list
    set allele-type-list remove-item item-index allele-type-list
    set item-index random length allele-type-list
    set second-allele initialize-allele item item-index allele-type-list
    set allele-type-list remove-item item-index allele-type-list
    set parent-population parent
    set my-generation generation-number
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
end

; set the shape and color of organism based on alleles
to set-organism-shape-and-color
  let dominance get-allele-dominance-relationship [allele-type] of first-allele [allele-type] of second-allele
  set shape "clown"
  if dominance = "recessive-dominant" [ set color [color] of second-allele ]
  if dominance = "dominant-recessive" [ set color [color] of first-allele ]
  if dominance = "identical" [ set color [color] of first-allele ] ; this is technically unnecessary and could be removed along with ... (*)
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

  ; HUBNET CLIENT
  listen-clients
  ask populations with [ hubnet-client? = true ] [ send-info-to-clients ]

  ; UPDATE STATE VARIABLES
  ask populations [ population-wander ]
  ask organisms [ organism-wander ]
  ask populations [ set gene-flow-populations get-adjacent-populations ]

  ; UPDATE INTERFACE VISUALS
  update-visibility-settings
  update-organism-shape-and-color
  update-allele-types-list
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
  while [count organisms with [ my-generation = generation-number + 1 and parent-population = myself ] < population-size ] [
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
  let number-of-offspring ifelse-value (read-from-string selection-on-phenotype = color) [( floor rate-of-selection ) + ifelse-value ( random-float 1.0 < ( rate-of-selection - floor rate-of-selection ) ) [ 1 ] [ 0 ]] [ 1 ] ; natural selection
  let current-offspring-count 0
  while [ current-offspring-count < number-of-offspring and count organisms with [ my-generation = generation-number + 1 and parent-population = [parent-population] of myself ] < population-size ] [
    hatch-organisms 1 [
      set first-allele initialize-allele one-of (sentence [allele-type] of first-allele [allele-type] of second-allele )
      set second-allele initialize-allele one-of (sentence [allele-type] of [first-allele] of mate [allele-type] of [second-allele] of mate )
        set my-generation generation-number + 1
      update-for-mutation
      setup-organism ]
    set current-offspring-count current-offspring-count + 1 ]
end

; organism command to find someone to mate with
to-report get-mate-in-gene-pool
  let mate-to-report nobody
  ifelse ( gene-flow-between-populations and [gene-flow-populations] of parent-population != no-turtles ) [
    set mate-to-report one-of other organisms with [ my-generation = generation-number and parent-population = [parent-population] of myself or member? parent-population [gene-flow-populations] of [parent-population] of myself ]
  ][
    set mate-to-report one-of other organisms with [ my-generation = generation-number and parent-population = [parent-population] of myself ]
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
  hubnet-send user-id "COORDINATES" (word "(" pxcor ", " pycor ")")
  hubnet-send user-id "GENERATION" generation-number

  ; GRAPH POSITION
  let graph-position position self sort populations + 1
  let counting-graph-position (ifelse-value ( graph-position = 1 ) [ "1st" ] ( graph-position = 2 ) [ "2nd" ] ( graph-position = 2 ) [ "3rd" ] [ (word graph-position "th") ] ) ; this will not work for numbers > 20
  hubnet-send user-id "HISTOGRAM POSITION" counting-graph-position

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
  let color-list [ "red" "orange" "yellow" "lime" "green" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "white" "black" ]

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
  set-current-plot "Total Proportion of Alleles Over Generations"
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
1291
10
1419
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
1157
10
1284
43
setup
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
1
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
0.0
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
1082
90
1248
123
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
1083
49
1177
82
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
generation
generation-number
17
1
11

MONITOR
949
22
1060
67
total population
count organisms
17
1
11

BUTTON
1256
90
1419
123
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
1083
339
1422
534
proportion of alleles per population
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
"green" 0.01 1 -10899396 true "" ""
"lime" 0.01 1 -13840069 true "" ""
"turquoise" 0.01 1 -14835848 true "" ""
"cyan" 0.01 1 -11221820 true "" ""
"sky" 0.01 1 -13791810 true "" ""
"blue" 0.01 1 -13345367 true "" ""
"violet" 0.01 1 -8630108 true "" ""
"magenta" 0.01 1 -5825686 true "" ""
"pink" 0.01 1 -2064490 true "" ""
"gray" 0.01 1 -7500403 true "" ""
"white" 0.01 1 -1 true "" ""
"black" 0.01 1 -16777216 true "" ""

PLOT
1083
544
1422
739
total proportion of alleles over generations
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
"yellow" 0.01 1 -1184463 false "" ""
"green" 0.01 1 -10899396 false "" ""
"lime" 0.01 1 -13840069 false "" ""
"turquoise" 0.01 1 -14835848 false "" ""
"cyan" 0.01 1 -11221820 false "" ""
"sky" 0.01 1 -13791810 false "" ""
"blue" 0.01 1 -13345367 false "" ""
"violet" 0.01 1 -8630108 false "" ""
"magenta" 0.01 1 -5825686 false "" ""
"pink" 0.01 1 -2064490 true "" ""
"gray" 0.01 1 -7500403 true "" ""
"white" 0.01 1 -1 true "" ""
"black" 0.01 1 -16777216 true "" ""

PLOT
1083
135
1421
330
genetic variation per population
population
index of variation
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
"red" "orange" "yellow" "green" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "white" "black"
0

CHOOSER
12
174
121
219
allele-two-color
allele-two-color
"red" "orange" "yellow" "green" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "white" "black"
1

CHOOSER
12
268
121
313
allele-three-color
allele-three-color
"red" "orange" "yellow" "green" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "white" "black"
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
326
265
359
allele-four-on?
allele-four-on?
0
1
-1000

CHOOSER
12
364
121
409
allele-four-color
allele-four-color
"red" "orange" "yellow" "green" "lime" "turquoise" "cyan" "sky" "blue" "violet" "magenta" "pink" "gray" "white" "black"
4

CHOOSER
125
364
265
409
allele-four-dominance
allele-four-dominance
"dominant" "recessive"
1

SLIDER
1313
49
1419
82
...every
...every
10
100
50.0
10
1
ticks
HORIZONTAL

BUTTON
1182
49
1309
82
reproduce...
if ( ticks > 0 and ceiling ( ticks / ...every ) = ticks / ...every ) [\nexecute-reproduce\n]
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
1083
10
1151
43
HubNet
hubnet-reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
# Population Genetics 2.1.0

#### Created with NetLogo 6.1.1

## WHAT IS IT?

This model simulates how the mechanisms of biological evolution (genetic drift, gene flow, mutation, and natural selection) shape emergent evolutionary patterns. That is, how allele frequencies change in a population over generations and shape patterns of between- and within-population variation.

During a simulation, "students" control populations of fish via a HubNet Client and a "teacher" controls the environment via the HubNet Control Center. Teachers can set up to four alleles at the locus coding for color. A fish's color phenotype is based on its genotype and the allele relationship set by parameters (i.e. dominant or recessive). The plots in the user interface show how the allele frequencies within and between populations change over generations.

## HOW IT WORKS

Click the SETUP button to start a new simulation and GO to get the simulation running. At this point, you should only see a blue screen - you have to manually add populations of fish in order to see anything interesting! You can add fish populations in two ways: (2) click the HUBNET button to create user-controlled populations or (1) click the ADD POPULATION button to create non-controlled populations. You can find more detailed instructions for these two options below. Once you have added your populations, click the REPRODUCE button to populate the world with a new generation of fish. Each new generation inherits alleles from the previous generation depending on the EVOLUTION SETTINGS. Once a new generation is born, the old generation dies.

### HubNet for Teachers: HubNet Control Center

STARTUP: Click on the HUBNET button to start the HubNet Control Center. Change any of the paramater settings depending on what aspect of evolution you want to simulate. Press the SETUP and GO buttons.

INSTRUCTIONS FOR YOUR STUDENTS: Instruct your students to open the NetLogo HubNet Client application, type their preferred user name, select this activity and press ENTER. Make sure that they choose the correct port number and server address for this simulation, which are shown in the HubNet Client. Upon enetering the simulation, a new fish population is created and assigned to them. Instruct your students to move their populations around to acquaint themselves with the interface. Instructors can also press the ADD POPULATION button to create another "non-playable" population in the world.

SIMULATION: Press the REPRODUCE button and the fish in each population will reproduce and die, thus propagating the next generation. Investigate how the allele frequencies have changed from the previous generation to this new generation and instruct your students to record the specifics changes for their population as shown in their HubNet Client. Continue to press the REPRODUCE button and discuss with your students how the EVOLUTION SETTINGS affect the evolution of fish populations over generations. You can modify the EVOLUTION SETTINGS to change the mechanisms of evolution at play (see THINGS TO NOTICE and THINGS TO TRY below for more information).

### HubNet for Students: HubNet Client

STARTUP: Students should open the NetLogo HubNet Client application, type their user name, select this activity and press ENTER. Make sure to choose the correct port number and server address for this simulation. Additionally, make sure that the version number for the HubNet Client and NetLogo applications match (current version is 6.1.1).

After logging in, the client interface will appear for the students, and if GO is pressed they will be assigned a population of fish, which should appear on the interface. The YOU ARE POPULATION monitor displays the name entered upon startup and will also appear on the simulation to label the appropriate population. The current location of the population is shown in the COORDINATES monitor.

SIMULATION: Students are able to control the movement of their population with the UP, DOWN, LEFT, and RIGHT buttons. When GENE-FLOW-BETWEEN-POPULATIONS is ON, students can move their populations to enable fish from adjacent populations to reproduce with the fish from their population, and vice versa. HubNet Client monitors show the current allele and genotype frequencies, as well as the current GENERATION and closest ADJACENT POPULATIONS.

### Outside of the Classroom

This model was built for classrooms using HubNet, but individual users can also simulate fish populations without using HubNet. Click ADD POPULATION to add new fish populations that are not connected to a HubNet Client. These populations wander about the environment randomly and reproduce at each generation. Change the parameter settings to investigate how these populations evolve over time. If you still want to investigate the details of a single population, click HUBNET and then within the HubNet popup window click LOCAL to start a HubNet Client locally. You can use this interface the same as described for students above.

## HOW TO USE IT

### GENERAL

HUBNET: press to begin or restart using the HubNet controls.

SETUP: initializes the model or returns the model to the starting state.

GO: runs the simulation.

REPRODUCE: all fish organisms reproduce with someone else in their gene pool.

REPRODUCE...: when pressed, executes the reproduce function at a time interval determined by ...EVERY slider. 

SHOW-ALLELES: when on, the alleles of the population are shown, otherwise the individual fish are shown, the phenotypes of which are based on the allele dominance parameter settings.

ADD POPULATION: when pressed, a new "non-playable" fish population is added to the world. It wanders randomly and its fish organisms can reproduce and share alleles with any adjacent populations.

### ALLELE SETTINGS

ALLELE-ONE-ON?: enables allele one to appear in the enivornment.

ALLELE-ONE-COLOR: determines what color allele one represents.

ALLELE-ONE-DOMINANCE: parameter setting determines whether allele one is dominant or recessive.

These settings also apply for alleles two, three, and four.

### EVOLUTION SETTINGS

POPULATION-SIZE: the current size of each population, which can be thought of as a fixed carrying capacity.

MUTATION-RATE: the rate at which the alleles at the color locus mutate to a random allele during reproduction. For example, a red allele could randomly mutate into a blue allele.

GENE-FLOW-BETWEEN-POPULATIONS: when ON, allows populations that are close enough to an ADJACENT POPULATION to share alleles during reproduction.

SELECTION-ON-PHENOTYPE: selects the phenotype color that natural selection acts upon during the simulation.

RATE-OF-SELECTION: for a phenotype that matches the currently set SELECTION-ON-PHENOTYPE this sets the average number of offspring that phenotype will produce during reproduction.

### MONITORS & PLOTS

GENERATION: the current generation of the populations in the simulation.

TOTAL POPULATION: the number of phenotypes from all populations in the simulation.

GENETIC VARIATION PER POPULATION: each bar of this histogram represents a population's index of variation for allele types, which is calculated usings Simpson's diversity.

PROPORTION OF ALLELES PER POPULATION: each bar of this histogram represents a population broken into sections of color to represent the proportion of each allele type.

PROPORTION OF ALLELES OVER GENERATIONS: shows the proportion of each allele type for each generation of the simulation.

## THINGS TO NOTICE

GENOTYPE & PHENOTYPE: Click between ON and OFF on the SHOW-ALLELES switch, which alternates the interface between showing the fish and its alleles. Each fish has two alleles that code for color, which together make up the fish's genotype for color. The physical expression of its genotype, which is called the fish's phenotype, is the color the fish actually displays. 

ALLELE DOMINANCE: Notice how the DOMINANCE (dominant or recessive) settings of the alleles affect what color(s) appear in each fish's phenotype. For example if a fish has a dominant and a recessive allele, only the dominant allele will be shown in its coloration. However, if both alleles are dominant, they can be considered co-dominant alleles and both colors are displayed in the fish's phenotype. Likewise, two recessive alleles are co-dominant with each other.

GENETIC VARIATION: This model focuses on how the mechanisms of evolution (mutation, gene flow, natural selection, and genetic drift) affect between- and within-population genetic variation. The index of variation numerically shows within-population variation in the GENETIC VARIATION PER POPULATION histogram; higher numbers show more within-population variation and lower numbers show less or no variation. We can also note within-population visually; populations with high within-population variation have multiple alleles represented and populations with low within-population variation have only one or two alleles present. Use the PROPORTION OF ALLELES PER POPULATION plot to note between-group variation by comparing the allele frequencies across populations; similar allele proportions indicate lower between-population variation and populations with noticeably different proportions or completely different allele types represented indicate high between-population variation.

MUTATION: How does the MUTATION-RATE setting affect the simulation? How does it change within-population and between-population genetic variation? Since mutation potentially adds novelle alleles to the population, we expect that setting a non-zero mutation rate will increase or maintain genetic variation both within a population and between populations.

GENE FLOW: How does the GENE-FLOW-BETWEEN-POPULATIONS setting affect the simulation? When this switch is turned ON, how does it change within-population and between-population genetic variation? Since gene flow allows adjacent populations to "share" their alleles, we expect that when gene flow is turned ON, the within-population genetic variation will increase or be maintained at a high level, and between-population genetic variation will decrease or be maintained at a low level.

NATURAL SELECTION: How do the SELECTION-ON-PHENOTYPE and RATE-OF-SELECTION settings affect the simulation? How do they change within-population and between-population genetic variation? If the selected color is present in the population, then we expect that a high rate ( > 1 ) of selection will increase the frequency of that allele and a low rate ( < 1 ) of selection will decrease the frequence of that allele in the population. Either scenario results in a decrease or low maintenance of within-population variation and an increase of high maintenance of between-population variation.

GENETIC DRIFT: Notice that there are no settings for genetic drift, the fourth mechanism of evolution. Unlike the other mechanisms, genetic drift can never be turned off! Since genetic drift causes a change in allele frequencies due to chance, we expect that within-population variation will decrease or be maintained, and between-population variation will increase or be maintained. This effect is strongest at lower population sizes and does not have as much of an effect on larger populations.

## THINGS TO TRY

Use this model to serve as an introduction to population genetics. Be sure to modify the EVOLUTION SETTINGS to simulate how different mechanisms of evolution can affect the allele frequencies and both within and between population variation.

1. Vary the POPULATION-SIZE to explore how genetic drift affects very large and very small populations.

2. Change very large populations to very small populations to explore bottleneck or founder's effects.

3. Increase the MUTATION-RATE to a non-zero number to see how novelle mutations can invade a population.

4. Turn on GENE-FLOW-BETWEEN-POPULATIONS and move populations within range of each other to see how populations can share alleles during reproduction.

5. Use SELECTION-ON-PHENOTYPE to choose a color that the environmental selective pressures are acting on. Move the slider RATE-OF-SELECTION to a value higher than 1.0 if the selective pressures favor this phenotype, and to a value lower than 1.0 if the selective pressures do not favor this phenotype. Observe how your choices affect the prevalance of that fish color over generations.

## POPULATION NAMES

The names of populations generated from clicking ADD POPULATION are taken from Huerta-Sánchez, Rohlfs and collegues' work on revealing the hidden female contributions to population genetics:

Dung, S. K., López, A., Barragan, E. L., Reyes, R. J., Thu, R., Castellanos, E., Catalan, F., Huerta-Sánchez, E. & Rohlfs, R. V. (2019). Illuminating Women’s Hidden Contribution to Historical Theoretical Population Genetics. Genetics, 211(2), 363-366.

## HOW TO CITE

Crouse, Kristin (2020). “Population Genetics” (Version 2.1.0). CoMSES Computational Model Library. Retrieved from: https://www.comses.net/codebases/6040/releases/2.1.0/

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

clown 0
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
Polygon -16777216 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -16777216 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -16777216 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

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

clown 9.9
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
Polygon -1 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

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
399
24
461
57
Up
NIL
NIL
1
T
OBSERVER
NIL
I

BUTTON
399
119
461
152
Down
NIL
NIL
1
T
OBSERVER
NIL
K

BUTTON
461
71
523
104
Right
NIL
NIL
1
T
OBSERVER
NIL
L

BUTTON
337
71
399
104
Left
NIL
NIL
1
T
OBSERVER
NIL
J

MONITOR
218
65
311
114
COORDINATES
NIL
3
1

MONITOR
14
10
176
59
YOU ARE POPULATION
NIL
3
1

MONITOR
14
65
212
114
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
120
311
169
ALLELE FREQUENCIES
NIL
3
1

MONITOR
14
175
536
224
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

MONITOR
181
10
311
59
HISTOGRAM POSITION
NIL
0
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
