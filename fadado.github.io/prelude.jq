module {
    name: "prelude",
    description: "Flow control services",
    namespace: "fadado.github.io",
    author: {
        name: "Joan Josep Ordinas Rosa",
        email: "jordinas@gmail.com"
    }
};

########################################################################
# Stolen from SNOBOL: ABORT and FENCE
########################################################################

## Breaks out the current filter
## For constructs like:
##   try (A | possible abortion | B)
#def abort: #:: a => !
#    error("~!~")
#;
#
## One way pass. Usage:
##   try (A | fence | B)
#def fence: #:: a => a!
#    (. , abort)
#;
#
## Catch helpers. Usage:
##   try (...) catch _abort_(result)
##   . as $_ | try (A | possible abortion | B) catch _abort_($_)
#def _abort_(result): #:: string|(*a) => *a!
#    if . == "~!~" then result else error(.) end
#;
##   try (...) catch _abort_
#def _abort_: #:: string| => @!
#    if . == "~!~" then empty else error(.) end
#;

########################################################################
# Variations on some JQ primitives
########################################################################

# Reverse of `isempty`
def nonempty(stream): #:: a|(a->*b) => boolean
#   (label $xit | stream | (true , break$xit)) // false
    first((stream|true) , false)
;

# all(stream; .)
def every(stream): #:: a|(a->*boolean) => boolean
    isempty(stream and empty)
;

# any(stream; .)
def some(stream): #:: a|(a->*boolean) => boolean
    nonempty(stream or empty)
;

# Enhanced `select`
def select(predicate; action): #:: a|(a->?boolean;a->*b) => *b
    if predicate then action else empty end
;

# Do `stream` produces?
def top(stream): #:: a|(a->*b) => ?a
#   if nonempty(stream) then . else empty end
    first(. as $t | stream | $t)
;

# Complement for `top`
def bot(stream): #:: a|(a->*b) => ?a
    if nonempty(stream) then empty end
;

# Complement of `select`
def reject(predicate): #:: a|(a->?boolean) => ?a
    if predicate then empty else . end
;
def reject(predicate; action): #:: a|(a->?boolean;a->*b) => *b
    if predicate then empty else action end
;

## Strong select
#def guard(predicate): #:: a|(a->?boolean) => a!
#    if predicate//null then . else abort end
#;

########################################################################
# Assertions
########################################################################

def assert(predicate; $location; $message): #:: a|(a->boolean;LOCATION;string) => a!
    if predicate//null then .
    else
        $location
        | error("Assertion failed: "+$message+", file \(.file), line \(.line)")
    end
;

def assert(predicate; $message): #:: a|(a->boolean;string) => a!
    if predicate//null then .
    else
        error("Assertion failed: "+$message)
    end
;

########################################################################
# Recursion schemata
########################################################################

# Additions to builtin recurse, while, until...

# Generate ℕ
def seq: #:: => *number
    0|recurse(.+1) # seq(1)
;
def seq($a): #:: (number) => *number
    $a|recurse(.+1) # seq($a)
;
def seq($a; $d): #:: (number;$number) => *number
    $a|recurse(.+$d) # seq($a; $d)
;

#
# Iteration
#

# f|recurse(f)
def chain(f): #:: a|(a->*a) => *a
    def r: ., (f|r);
    f|r
;

# g⁰ g¹ g² g³ g⁴ g⁵ g⁶ g⁷ g⁸ g⁹…
# Breadth-first search
def iterate(init; g): #:: a|(a->*b;b->*b) => *b
    def r:
         .[] , (map(g) | select(length > 0) | r)
    ;
    [init] | r
;
def iterate(g): #:: a|(a->*a) => +a
    iterate(.; g)
;

#
# Fold/unfold family of patterns
#

#def fold(f; $a; g): #:: x|([a,b]->a;a;x->*b) => a
#    reduce g as $b
#        ($a; [.,$b]|f)
#;

#def scan(f; g): #:: x|([a,b]->a;x->*b) => *a
#    foreach g as $b
#        (.; [.,$b]|f; .)
#;
#def scan(f; $a; g): #:: x|([a,b]->a;a;x->*b) => *a
#    $a|scan(f; g)
#;

# Fold _opposite_
def unfold(f): #:: a|(a->[b,a]) => *b
    def r: f as [$b,$a] | $b , ($a|r);
    r
;

########################################################################
# Better versions for builtins
########################################################################

# Renamed map_values
def mapval(f): #:: <a>|(a->*b) => <b>
    .[] |= f
;

# map and add in one pass (catenable: x+x)
def mapadd(f): #:: <a>|(a->*b) => ?b
    reduce (.[] | f) as $x
        (null; . + $x)
    // empty
;

# Split string, map characters (length one strings) and concat results
def mapstr(f): #:: string|(char->*char) => string
    reduce ((./"")[] | f) as $s
        (""; . + $s)
;

# Variation on `with_entries`
#
# PAIR: {"name":string, "value":value}
#
def mapobj(filter): #:: object|(PAIR->PAIR) => object
    reduce (keys_unsorted[] as $k
            | {name: $k, value: .[$k]}
            | filter
            | {(.name): .value})
        as $pair ({}; . + $pair)
;

#def range($init; $upto; $by):
#    select($by != 0)
#    | label $xit
#    | if $by > 0
#      then $init|recurse(.+$by) | if . >= $upto then break$xit end)
#      else $init|recurse(.+$by) | if . <= $upto then break$xit end)
#      end
#    end
#; 

# Generic swap
#def swap(p; q): p as $t | p=q | q=$t;

# vim:ai:sw=4:ts=4:et:syntax=jq
