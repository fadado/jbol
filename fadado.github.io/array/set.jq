module {
    name: "array/set",
    description: "Array as sets operations",
    namespace: "fadado.github.io",
    author: {
        name: "Joan Josep Ordinas Rosa",
        email: "jordinas@gmail.com"
    }
};

include "fadado.github.io/prelude";

########################################################################

# ∅         []
# |s|       length
# s ⊂ t     s|contains(t)
# s ⊃ t     s|inside(t)

# Add element to set
def insert($x): #:: [a]|(a) => [a]
    .[length] = $x
;

# Remove element from set
def remove($x): #:: [a]|(a) => [a]
    .[[$x]][0] as $i
    | when($i != null; del(.[$i]))
;

# x ∈ S (x is element of S)
def element($s): #:: a|([a]) => boolean
    $s[[.]] != []
;

# S ∋ x (S contains x as member)
def member($x): #:: a|([a]) => boolean
    .[[$x]] != []
;

# S ≡ T (S is equal to T)
def equal($t): #:: [a]|([a]) => boolean
    . as $s
    | ($s|inside($t)) and ($t|inside($s))
;

# S ∪ T
def union($t): #:: array|(array) => array
    . + ($t - .)
;

# S ∩ T
def intersection($t): #:: array|(array) => array
    . - (. - $t)
;

# S – T
def difference($t): #:: array|(array) => array
    . - $t
;

# (S – T) ∪ (T – S)
def sdifference($t): #:: array|(array) => array
    (. - $t) + ($t - .)
;

#  S ∩ T ≡ ∅
def disjoint($t): #:: array|(array) => boolean
    . - (. - $t) == []
;

# vim:ai:sw=4:ts=4:et:syntax=jq
