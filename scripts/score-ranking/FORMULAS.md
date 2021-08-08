# Glossary

| Acronym | Definition | Variable name |
|:--------|:-----------|:--------------|
| NCF     | number of failed test cases that cover a statement            | failed |
| NUF     | number of failed test cases that do not cover a statement     | totalfailedsmall - failed |
| NCS     | number of successful test cases that cover a statement        | passed |
| NUS     | number of successful test cases that do not cover a statement | totalpassedsmall - passed |
| NC      | total number of test cases that cover a statement             | passed + failed |
| NU      | total number of test cases that do not cover a statement      | (totalpassedsmall - passed) + (totalfailedsmall - failed) |
| NS      | total number of successful test cases                         | totalpassedsmall |
| NF      | total number of failed test cases                             | totalfailedsmall |


# Formulas

## Naish1 (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis) also known as Opt1
```
-1,                          if (totalfailedsmall - failed) > 0
(totalpassedsmall - passed), otherwise
```

## Naish2 (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis) also known as Opt2
```
          passed
failed - (---                                )
          passed + (totalpassedsmall - passed) + 1
```

## GP13 (Yoo2012EHC, Yoo, 2012. Evolving Human Competitive Spectra-Based Fault Localisation Techniques)
```
              1
failed * (1 + ---                )
              2 * passed + failed
```

## GP02 (Yoo2012EHC, Yoo, 2012. Evolving Human Competitive Spectra-Based Fault Localisation Techniques)
```
2 * (failed + sqrt(totalpassedsmall - passed)) + sqrt(passed)
```

## GP03 (Yoo2012EHC, Yoo, 2012. Evolving Human Competitive Spectra-Based Fault Localisation Techniques)
```
sqrt(abs(pow(failed, 2) - sqrt(passed)))
```

## GP19 (Yoo2012EHC, Yoo, 2012. Evolving Human Competitive Spectra-Based Fault Localisation Techniques)
```
failed * sqrt(abs(passed - failed + (totalfailedsmall - failed) - (totalpassedsmall - passed)))
```

## Jaccard (738238, CHEN, 2002. Pinpoint: Problem determination in large, dynamic internet services)
```
failed
---
failed + (totalfailedsmall - failed) + passed
```

## Anderberg (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed
---
failed + 2 * ((totalfailedsmall - failed) + passed)
```

## Dice (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
2 * failed
---
failed + (totalfailedsmall - failed) + passed
```

## Sorensen-Dice (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
2 * failed
---
2 * failed + (totalfailedsmall - failed) + passed
```

## Goodman (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
2 * failed - (totalfailedsmall - failed) - passed
---
2 * failed + (totalfailedsmall - failed) + passed
```

## Tarantula (JonesHS2002, JONES, 2002. Visualization of test information to assist fault localization)
```
  failed
  ---
  failed + (totalfailedsmall - failed)
---
  failed                            passed
  --                              + ---
  failed + (totalfailedsmall - failed)   passed + (totalpassedsmall - passed)
```

## qe (Abreu2006ESC, Abreu, 2006. An Evaluation of Similarity Coefficients for Software Fault Localization)
```
failed
---
failed + passed
```

## CBI Inc. (Liblit2005SSB, LIBLIT, 2005. Scalable statistical bug isolation)
```
failed              failed + (totalfailedsmall - failed)
---              -  ---
failed + passed     failed + (totalfailedsmall - failed) + passed + (totalpassedsmall - passed)
```

## CBI Sqrt (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
2
---
1         sqrt(failed + (totalfailedsmall - failed))
---     + ---
CBI Inc   sqrt(failed)
```

## CBI Log (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
2
---
1         log(failed + (totalfailedsmall - failed))
---     + ---
CBI Inc   log(failed)
```

## Wong2 (Wong2007EFL, WONG, 2007. Effective fault localization using code coverage)
```
failed - passed
```

## Hamann (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed + (totalpassedsmall - passed) - (totalfailedsmall - failed) - passed
---
failed + (totalfailedsmall - failed) + passed + (totalpassedsmall - passed)
```

## Simple Matching (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed + (totalpassedsmall - passed)
---
failed + passed + (totalpassedsmall - passed) + (totalfailedsmall - failed)
```

## Sokal (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
2 * (failed + (totalpassedsmall - passed))
---
2 * (failed + (totalpassedsmall - passed)) + (totalfailedsmall - failed) + passed
```

## Rogers & Tanimoto (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed + (totalpassedsmall - passed)
---
failed + (totalpassedsmall - passed) + 2 * ((totalfailedsmall - failed) + passed)
```

## Hamming (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed + (totalpassedsmall - passed)
```

## Euclid (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
sqrt( failed + (totalpassedsmall - passed) )
```

## Wong1 (Wong2007EFL, WONG, 2007. Effective fault localization using code coverage)
```
failed
```

## Russell & Rao (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed
---
failed + (totalfailedsmall - failed) + passed + (totalpassedsmall - passed)
```

## Binary (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
0, if failed  < totalfailedsmall
1, if failed == totalfailedsmall
```

## Scott (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
4 * (failed * (totalpassedsmall - passed)) - 4 * ((totalfailedsmall - failed) * passed) - pow((totalfailedsmall - failed) - passed, 2)
---
(2 * failed + (totalfailedsmall - failed) + passed) * (2 * (totalpassedsmall - passed) + (totalfailedsmall - failed) + passed)
```

## Rogot1 (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
        failed                                               (totalpassedsmall - passed)
0.5 * ( ---                                                + ---                 )
        2 * failed + (totalfailedsmall - failed) + passed   2 * (totalpassedsmall - passed) + (totalfailedsmall - failed) + passed
```

## Rogot2 (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
        failed            failed                                  (totalpassedsmall - passed)            (totalpassedsmall - passed)
0.25 * (---             + ---                                   + ---                                   + ---                  )
        failed + passed   failed + (totalfailedsmall - failed)   (totalpassedsmall - passed) + passed   (totalpassedsmall - passed) + (totalfailedsmall - failed)
```

## Kulczynski1 (lourencco2004binary, LOURENCO, 2004. Binary-based similarity measures for categorical data and their application in self-organizing maps)
```
failed
---
(totalfailedsmall - failed) + passed
```

## Kulczynski2 (lourencco2004binary, LOURENCO, 2004. Binary-based similarity measures for categorical data and their application in self-organizing maps)
```
       failed                                   failed
0.5 * (---                                   +  ---            )
       failed + (totalfailedsmall - failed)    failed + passed
```

## Ochiai (Abreu2006ESC, ABREU, 2006. An evaluation of similarity coefficients for software fault localization)
```
failed
---
sqrt( (failed + (totalfailedsmall - failed)) * (failed + passed) )
```

## Ochiai2 (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed * (totalpassedsmall - passed)
---
sqrt( (failed + passed) * ((totalpassedsmall - passed) + (totalfailedsmall - failed)) * (failed + (totalfailedsmall - failed)) * (passed + (totalpassedsmall - passed)) )
```

## M1 (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed + (totalpassedsmall - passed)
---
(totalfailedsmall - failed) + passed
```

## M2 (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed
---
failed + (totalpassedsmall - passed) + 2 * ((totalfailedsmall - failed) + passed)
```

## Ample (AMPLE, Dallmeier, 2005. Lightweight bug localization with ample)
```
     failed                                    passed
abs (---                                    -  ----                          )
     failed + (totalfailedsmall - failed)     passed + (totalpassedsmall - passed)
```

## Ample2 (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed                                   passed
---                                   -  ----
failed + (totalfailedsmall - failed)    passed + (totalpassedsmall - passed)
```

## Wong3 (Wong2007EFL, WONG, 2007. Effective fault localization using code coverage)
```
    passed, if passed <= 2
failed - h, where h = 2 + 0.1 * (passed - 2),      if 2 < passed <= 10
                      2.8 + 0.001 * (passed - 10), if passed > 10
```

## Arithmetic Mean (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
2 * failed * (totalpassedsmall - passed) - 2 * (totalfailedsmall - failed) * passed
---
(failed + passed) * ((totalpassedsmall - passed) + (totalfailedsmall - failed)) + (failed + (totalfailedsmall - failed)) * (passed + (totalpassedsmall - passed))
```

## Geometric Mean (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed * (totalpassedsmall - passed) - (totalfailedsmall - failed) * passed
---
sqrt((failed + passed) * (failed + (totalfailedsmall - failed)) * (passed + (totalpassedsmall - passed)) * ((totalfailedsmall - failed) + (totalpassedsmall - passed)))
```

## Harmonic Mean (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
(failed * (totalpassedsmall - passed) - (totalfailedsmall - failed) * passed) * ((failed + passed) * ((totalpassedsmall - passed) + (totalfailedsmall - failed)) + (failed + (totalfailedsmall - failed)) * (passed + (totalpassedsmall - passed)))
---
(failed + passed) * ((totalpassedsmall - passed) + (totalfailedsmall - failed)) * (failed + (totalfailedsmall - failed)) * (passed + (totalpassedsmall - passed))
```

## Cohen (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
2 * (failed * (totalpassedsmall - passed) - (totalfailedsmall - failed) * passed)
---
(failed + passed) * ((totalpassedsmall - passed) + passed) + (failed + (totalfailedsmall - failed)) * ((totalfailedsmall - failed) + (totalpassedsmall - passed))
```

## Fleiss (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
4 * (failed * (totalpassedsmall - passed) - (totalfailedsmall - failed) * passed) - pow((totalfailedsmall - failed) - passed, 2)
---
(2 * failed + (totalfailedsmall - failed) + passed) + (2 * (totalpassedsmall - passed) + (totalfailedsmall - failed) + passed)
```

## Braun-Banquet (FLSurvey2016, Wong, 2016. A Survey on Software Fault Localization)
```
failed
---
max( failed + passed, failed + (totalfailedsmall - failed) )
```

## Dennis (Dennis2009, Dennis, 2009. Dynamic state alteration techniques for automatically locating software errors)
```
(failed * (totalpassedsmall - passed)) - (passed * (totalfailedsmall - failed))
---
sqrt( n * (failed + passed) * (failed + (totalfailedsmall - failed)) )
```

## Mountford (FLSurvey2016, Wong, 2016. A Survey on Software Fault Localization)
```
failed
---
0.5 * ((failed * passed) + (failed * (totalfailedsmall - failed))) + (passed * (totalfailedsmall - failed))
```

## Fossum (FLSurvey2016, Wong, 2016. A Survey on Software Fault Localization)
```
TODO
n * pow(failed - 0.5, 2)
---
(failed + passed) + (failed + (totalfailedsmall - failed))
```

## Pearson (FLSurvey2016, Wong, 2016. A Survey on Software Fault Localization)
```
n * pow( (failed * (totalpassedsmall - passed)) - (passed * (totalfailedsmall - failed)), 2)
---
(passed + failed) * ((totalpassedsmall - passed) + (totalfailedsmall - failed)) * totalpassedsmall * totalfailedsmall
```

## Gower (FLSurvey2016, Wong, 2016. A Survey on Software Fault Localization)
```
failed + (totalpassedsmall - passed)
---
sqrt(totalfailedsmall * (passed + failed) * ((totalpassedsmall - passed) + (totalfailedsmall - failed)) * totalpassedsmall)
```

## Michael (FLSurvey2016, Wong, 2016. A Survey on Software Fault Localization)
```
4 * ( (failed * (totalpassedsmall - passed)) - (passed * (totalfailedsmall - failed)) )
---
pow(failed + (totalpassedsmall - passed), 2) + pow(passed + (totalfailedsmall - failed), 2)
```

## Pierce (FLSurvey2016, Wong, 2016. A Survey on Software Fault Localization)
```
(failed * (totalfailedsmall - failed)) + ((totalfailedsmall - failed) * passed)
---
(failed * (totalfailedsmall - failed)) + (2 * ((totalfailedsmall - failed) * (totalpassedsmall - passed))) + (passed * (totalpassedsmall - passed))
```

## Baroni-Urbani & Buser (FLSurvey2016, Wong, 2016. A Survey on Software Fault Localization)
```
sqrt( failed * (totalpassedsmall - passed) ) + failed
---
sqrt( failed * (totalpassedsmall - passed) ) + failed + passed + (totalfailedsmall - failed)
```

## Tarwid (FLSurvey2016, Wong, 2016. A Survey on Software Fault Localization)
```
(n * failed) - (totalfailedsmall * (passed + failed))
---
(n * failed) + (totalfailedsmall * (passed + failed))
```

## Zoltar (FLSurvey2016, Wong, 2016. A Survey on Software Fault Localization)
```
failed
---
                                                 1000 * (totalfailedsmall - failed) * passed
failed + (totalfailedsmall - failed) + passed + ---
                                                 failed
```

## Overlap (naish2011model, NAISH, 2011. A model for spectra-based software diagnosis)
```
failed
---
min(failed, (totalfailedsmall - failed), passed)
```
