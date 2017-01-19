module {
    name: "regular expressions",
    description: "Pattern matching using regular expressions",
    namespace: "fadado.github.io",
    author: {
        name: "Joan Josep Ordinas Rosa",
        email: "jordinas@gmail.com"
    }
};

include "fadado.github.io/prelude";
include "fadado.github.io/types";

import "fadado.github.io/string" as str;

########################################################################
# Module based on builtin `match(regex; flags)`
#
# `match` outputs an object for each match it finds. Matches have the following
# fields:
#
# offset   - offset in UTF-8 codepoints from the beginning of the input
# length   - length in UTF-8 codepoints of the match
# string   - the string that it matched
# captures - an array of objects representing capturing groups.
#
# Capturing group objects have the following fields:
#
# offset - offset in UTF-8 codepoints from the beginning of the input
# length - length in UTF-8 codepoints of this capturing group
# string - the string that was captured
# name   - the name of the capturing group (or null if it was unnamed)
#
# Capturing groups that did not match anything return an offset of -1.
########################################################################

########################################################################
# Simulating scanf
#
# scanf() Token     Regular Expression
# %c                "."
# %5c               ".{5}"
# %d                "[-+]?\\d+"
# %e, %E, %f, %g    "[-+]?(\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?"
# %i                "[-+]?(0[xX][\\dA-Fa-f]+|0[0-7]*|\\d+)"
# %o                "[-+]?[0-7]+"
# %s                "\\S+"
# %u                "\\d+"
# %x, %X            "[-+]?(0[xX])?[\\dA-Fa-f]+"
########################################################################

########################################################################
# Synonim for `test`
#
# Only to provide all pattern matching services in this module.
#
def like($regex): #:: string|(string) -> boolean
    # . as $subject
    test($regex)
;
def like($regex; $flags): #:: string|(string;string) -> boolean
    # . as $subject
    test($regex; $flags)
;

########################################################################
# Enhanced match
#
# Call `match` and add to the match object some strings for context (like
# Perl $`, $& and $').
#
def search($regex; $flags): #:: string|(string;string) -> <MATCH>
    . as $subject
    | match($regex; $flags)
    | . + { "&": .string,
            "`": $subject[:.offset],
            "'": $subject[.offset+.length:] }
;

def search($regex): #:: string|(string) -> <MATCH>
    search($regex; "")
;

########################################################################
# Some filters to use instead of `capture` and `scan`. Typical usage:
#   match(re; m)  | tomap as $d ...
#   match(re; m)  | tolist as $a ...
#   [match(re; m) | tostr] as $a ...

# Extract named groups from a MATCH object as a map (object)
#
def tomap: #:: MATCH -> object
    reduce (.captures[]
            | select(.name!=null)
            | {(.name):.string}) as $pair
        (if ."&"==null then {} else {"&":."&", "`":."`", "'":."'"} end;
         . + $pair)
;

# Extract matched string and all groups from a MATCH object as a list (array)
#
def tolist: #:: MATCH -> [string]
    [.string, (.captures[]|.string)]
;

# Extract matched string or first non null group from a MATCH object
#
def tostr: #:: MATCH -> string
    (.captures|length) as $len
    | if $len == 0
      then .string//""
      else (
        label $nonnull
        | range($len) as $i
        | if .captures[$i].string | isnull
          then empty # next
          else (.captures[$i].string , break $nonnull)
          end
        )//""
      end
;

########################################################################
# Enhanced substitutes for `split` and `splits` builtins
#
#   * Emit 1..$limit items
#   * Include matched groups if present

def split($regex; $flags; $limit): #:: string|(string;string;number) -> <string>
    def segment:
        if length <= 3
        then .
        else .[0:3], (.[3:]|segment)
        end
    ;
    if $limit < 0
    then empty
    elif $limit == 0 or $regex == ""
    then .
    else
        . as $subject
        | [ 0, # first index
            (label $loop
                | foreach match($regex; $flags+"g") as $m
                    # init
                    ($limit;
                    # update
                    .-1;
                    # yield if conditions are ok
                    if . < 0
                    then break $loop
                    else $m.offset, $m.captures, $m.offset+$m.length
                    end)),
            ($subject|length), # last index
            [] # empty captures for last segment
        ]
        | segment as [$i, $j, $groups]
        | $subject[$i:$j], ($groups[]|.string)
    end
;

# Fully compatible with `splits/2`, and replaces `split/2` in a non compatible
# way (use [pm::split(r;f)] for compatible behavior)
# 
def split($regex; $x): #:: string|(string;number+string) -> <string>
    # . as $subject
    if $x|isnumber
    then split($regex; ""; $x)     # $x = limit
    elif $x|isstring
    then split($regex; $x; infinite) # $x = flags
    else error($x|type|"Type error: expected number or string, not \(.)")
    end
;

# Fully compatible with `splits/1`, and replaces `split/1` in a non compatible
# way (use "s"/"d" instead for full compatibility)
#
def split($regex): #:: string|(string) -> <string>
    # . as $subject
    split($regex; "g"; infinite)
;

# Splits its input on white space breaks, trimming space around
#
def split: #:: string| -> <string>
    # . as $subject
    str::trim | split("\\s+"; ""; infinite)
;

# Fast join, only for string arrays
#
def fuse($x): #:: [string]|(string) -> string
    def sep:
        if .==null
        then ""
        else .+$x
        end
    ;
    reduce .[] as $s
        (null; sep + $s)
    // ""
;

########################################################################
# Compatible substitutes for `sub` and `gsub` builtins

def sub($regex; template; $flags): #:: string|(string;string;string) -> string
    def sub1($flags; $gs):
        def _sub1:
            . as $subject
            | [search($regex; $flags)] # only one match (or empty)
            | if length == 0
              then $subject
              else
                .[0] as $m
                | reduce ($m.captures[]
                          | select(.name != null)
                          | {(.name):.string})
                    as $pair
                    ({"&":$m."&", "`":$m."`", "'":$m."'"}; .+$pair)
                | template as $replacement # expands template with \(...)
                | $subject[0:$m.offset]
                    + $replacement
                    + ($subject[$m.offset+$m.length:]
                       | if $gs and length > 0 then _sub1 else . end)
              end
        ;
        _sub1
    ;
    ($flags|contains("g")) as $gs
    | ($flags 
       | if $gs
         then [explode[]|select(.!=103)] | implode  # ord("g") == 103
         else . end) as $fs
    | sub1($fs; $gs)
;

def sub($regex; template): #:: string|(string;string) -> string
    sub($regex; template; "")
;

def gsub($regex; template; $flags): #:: string|(string;string;string) -> string
    sub($regex; template; $flags+"g")
;

def gsub($regex; template): #:: string|(string;string) -> string
    sub($regex; template; "g")
;


# vim:ai:sw=4:ts=4:et:syntax=jq