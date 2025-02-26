# -*- coding: utf-8 -*-
"""
Created on Wed Feb 26 14:14:20 2025

@author: kramerlab
"""
import os



path = "/usr/local/freesurfer/7.4.1/subjects/fsaverage"

if os.path.exists(path):
    print(f"✅ Path exists: {path}")
else:
    print(f"❌ Path does NOT exist: {path}")