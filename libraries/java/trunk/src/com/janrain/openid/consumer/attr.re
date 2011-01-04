# Must start with a sequence of word-characters, followed by an equals sign
(\w+)=

# Then either a quoted or unquoted attribute
(?:

 # Match everything that's between matching quote marks
 (["'])(.*?)\2
|

 # If the value is not quoted, match up to whitespace
 ((?:[^\s<>/]|/(?!>))+)
)

|

([<>])
