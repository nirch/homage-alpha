import homageapp

import os

for path, subdirs, files in os.walk(homageapp.SRC_ROOT, '.mm'):
   for filename in files:
     f = os.path.join(path, filename)
     print f