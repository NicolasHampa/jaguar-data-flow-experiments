#!/usr/bin/python

import math

def sqrt(value):
  return value**0.5

def tarantula(passed, failed, totalpassed, totalfailed):
  if totalfailed == 0 or failed == 0:
    return 0
  if totalpassed == 0:
    assert passed == 0
    return 1 if failed > 0 else 0
  return (failed/totalfailed)/(failed/totalfailed + passed/totalpassed)

def ochiai(passed, failed, totalpassed, totalfailed):
  if totalfailed == 0 or (passed+failed == 0):
    return 0
  return failed/(totalfailed*(failed+passed))**0.5


FORMULAS = {
  'tarantula': tarantula,
  'ochiai': ochiai
}
