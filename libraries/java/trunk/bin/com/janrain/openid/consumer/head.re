# Starts with the tag name at a word boundary, where the tag name is
# not a namespace
<head\b(?!:)

# All of the stuff up to a ">", hopefully attributes.
([^>]*?)

(?: # Match a short tag
    />

|   # Match a full tag
    >

    # match the contents of the full tag
    (.*?)

    # Closed by
    (?: # One of the specified close tags
        </?(?:head|body)\s*>

        # End of the string
    |   \Z

    )

)
