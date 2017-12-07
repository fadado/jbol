module {
    name: "music/interval-class-vector",
    description: "Interval-class count vector",
    namespace: "fadado.github.io",
    author: {
        name: "Joan Josep Ordinas Rosa",
        email: "jordinas@gmail.com"
    }
};

include "fadado.github.io/prelude";
import "fadado.github.io/math" as math;
import "fadado.github.io/music/pitch-class" as pc;
import "fadado.github.io/array" as array;

########################################################################
# Names used in type declarations
#
# PCLASS (pitch-class): 0..11
# PCSET (pitch-class set): [PCLASS]
# IC (interval-class): 0..6
# VECTOR: 6[number]; indices are IC-1
# TABLE: [[PCI]]
# PATTERN: [PCI]
#
# Useful primitives:
#   + add(.[] | math::tobase(16))  (to format vectors)
#   + map(tostring) | add  (to format vectors if count < 10)
#   + vector|array::uniform
#   + vector|array::different (deep scale property)

# Interval-class vector
def vector: #:: PCSET => VECTOR
    def _tally:
        . as $pcs
        | length as $n
        | range($n-1) as $i
        | range($i+1; $n) as $j
        | $pcs[$i]|pc::interval_class($pcs[$j])
    ;
    # interval class vector
    reduce _tally as $ic
        ([0,0,0,0,0,0]; .[$ic-1] += 1)
;

########################################################################
# pitch-class step/size table

# indices: generic intervals - 1
# values:  a list of specific intervals
def table: #:: PCSET => TABLE
    def _table:
        . as $pcs
        | length as $n
        | range($n-1) as $i
        | range($i+1; $n) as $j
        | ($j - $i) as $d
        | $pcs[$i]|pc::interval($pcs[$j]) as $c
        | ([$d,$c], [$n-$d,12-$c])
    ;
    [range(length-2)|[]] as $t
    | reduce _table as [$d,$c] ($t; .[$d-1] += [$c])
    | map(unique)
;

# TODO
#   define myhill, maximally_even

########################################################################
# Intervals succession pattern
# Known as directed-interval vector, interval succession,  interval string,
# etc.

def pattern: #:: PCSET => PATTERN
    . as $pcset
    | [range(length), 0] as $ndx
    | [range(length) as $i | $pcset[$ndx[$i]]|pc::interval($pcset[$ndx[$i+1]])]
#   | assert(add == 12)
;

# vim:ai:sw=4:ts=4:et:syntax=jq
