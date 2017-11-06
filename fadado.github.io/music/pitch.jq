module {
    name: "music/pitch",
    description: "Pitch functions",
    namespace: "fadado.github.io",
    author: {
        name: "Joan Josep Ordinas Rosa",
        email: "jordinas@gmail.com"
    }
};

include "fadado.github.io/prelude";
import "fadado.github.io/math" as math;
import "fadado.github.io/string/regexp" as re;

########################################################################
# pitch: 0..127

# Produces a new pitch
def new: #:: <number^string>| => number
#   . as $x
    if type == "number" then
        if 0 <= . and . <= 127 # . is a pitch in the range 0..127
        then .
        else "Pitch out of range: \(.)" | error
        end
    elif type == "string" then
        if test("^[A-G][#sbf]?(?:[0-9]|10)$") # . is a note name with octave
        then
            match("^(?<n>[A-G])(?<a>[#sbf])?(?<o>[0-9]|10)$")
            | re::tomap as $m
            | {"C":0,"D":2,"E":4,"F":5,"G":7,"A":9,"B":11}[$m["n"]] as $n
            | $m["o"] | tonumber * 12
            + if $m["a"]=="#" or $m["a"]=="s"
              then $n+1     # sharp
              elif $m["a"]=="b" or $m["a"]=="f"
              then $n-1     # flat
              else $n
              end
        else
            "Malformed pitch: \(.)" | error
        end
    else type | "Type error: expected number or string, not \(.)" | error
    end
;
def new($x): #:: (<number^string>) => number
    $x | new
;

def format: #:: number| => string
#   . as $pitch
	["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"] as $names
    | math::div(.; 12) as $octave
    | math::mod(.; 12) as $note
    | "\($names[$note])\($octave)"

;

########################################################################
# Intervals

## Add a directed interval to the pitch
#def transpose($interval): #:: number|(number) => number
##   . as $pitch
#    . + $interval
#    | select(0 <= . and . <= 127) # . is a pitch in the range 0..127
#;

# Produces the pitch interval (-127..127) between two pitches
def interval($p): #:: number|(number) => number
#   . as $pitch
    $p - . | select(-127 <= . and . <= 127)
;

# Utility to make unordered pitch intervals
def abs: #:: number| => number
    length
;

# vim:ai:sw=4:ts=4:et:syntax=jq
