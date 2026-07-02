# Capibara ESP — Spanish overrides for the engine's grammar functions.
# THE()/SUBJECT()/OBJECT()/POSS-ADJ()/CONJUGATE-*()/etc. resolve these zzzz-*
# messages from the ACTIVE culture (see RobustToolbox
# Robust.Shared/Localization/LocalizationManager.Functions.cs and the en-US
# baseline in RobustToolbox/Resources/Locale/en-US/_engine_lib.ftl). Without
# these keys the en-US fallback renders "his"/"him"/"the"/"is" inside Spanish
# sentences. Purely additive — no upstream file is touched.
#
# Gender notes:
# - male/female come from GrammarComponent or the entity's .gender loc attribute.
# - epicene = they/them characters -> inclusive "elle" (singular verbs).
# - neuter = objects/most creatures; articles need the NOUN's gender, which the
#   engine can't know, so neuter falls back to the bare name / masculine forms.
#   Per-entity fixes: give the es-ES entity override a .gender attribute.

# Used internally by the THE() function.
zzzz-the = { PROPER($ent) ->
     [true] { $ent }
    *[false] { GENDER($ent) ->
        [male] el { $ent }
        [female] la { $ent }
       *[neuter] { $ent }
       }
    }

# Used internally by the SUBJECT() function.
zzzz-subject-pronoun = { GENDER($ent) ->
    [male] él
    [female] ella
    [epicene] elle
   *[neuter] él
   }

# Used internally by the OBJECT() function.
zzzz-object-pronoun = { GENDER($ent) ->
    [male] él
    [female] ella
    [epicene] elle
   *[neuter] él
   }

# Used internally by the DAT-OBJ() function ("to him" / "for her").
zzzz-dat-object = { GENDER($ent) ->
    [male] le
    [female] le
    [epicene] le
   *[neuter] le
   }

# Used internally by the GENITIVE() function.
zzzz-genitive = { GENDER($ent) ->
    [male] de él
    [female] de ella
    [epicene] de elle
   *[neuter] de él
   }

# Used internally by the POSS-PRONOUN() function. Spanish possessive pronouns
# agree with the POSSESSED noun (unknowable here), so use the generic form.
zzzz-possessive-pronoun = suyo

# Used internally by the POSS-ADJ() function. "su" is invariable in Spanish.
zzzz-possessive-adjective = su

# Used internally by the REFLEXIVE() function.
zzzz-reflexive-pronoun = { GENDER($ent) ->
    [male] sí mismo
    [female] sí misma
    [epicene] sí misme
   *[neuter] sí mismo
   }

# Used internally by the CONJUGATE-BE() function.
# Epicene "elle" takes singular verbs in Spanish, so this is invariable.
zzzz-conjugate-be = es

# Used internally by the CONJUGATE-HAVE() function.
zzzz-conjugate-have = tiene

# Used internally by the CONJUGATE-BASIC() function.
zzzz-conjugate-basic = { GENDER($ent) ->
    [epicene] { $first }
   *[other] { $second }
   }

# Used by the Capibara es-ES INDEFINITE() override in ContentLocalizationManager
# (the engine version hardcodes English "a/an").
zzzz-indefinite = { GENDER($ent) ->
    [female] una
   *[other] un
   }
