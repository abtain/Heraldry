# Starts with the tag name at a word boundary, where the tag name is
# not a namespace
<html\b(?!:)

# All of the stuff up to a ">", hopefully attributes.
([^>]*?)

(?: # Match a short tag
    />

|   # Match a full tag
    >

    # contents
    (.*?)

    # Closed by
    (?: # One of the specified close tags
        </?html\s*>

        # End of the string
    |   \Z

    )

)
