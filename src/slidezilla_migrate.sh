#!/bin/bash
#    slidezilla
#    Copyright (c) 2013 Biren Saini
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.
#

cores_filesuffix=`date +%m%d%y`
rm -rf ../runtime/*

mkdir -p ../runtime/code
mkdir -p ../runtime/tour
mkdir -p ../runtime/input

cp ./*.sh ../runtime/code
cp ./sample_property_files/atour*.properties ../runtime/tour
cp ./slidezilla*.properties ../runtime/code
cp ./xtra/cores ../runtime/code/.cores_${cores_filesuffix}
rm -rf ../runtime/code/slidezilla_migrate.sh

for mfile in `grep :media_path sample_property_files/atour-small.properties | awk -F'=' '{print $2}'`
do
fname=`basename $mfile`
cp ./xtra/input/${fname} ../runtime/input/
done

audiofile=`grep :audio_filename sample_property_files/atour-small.properties | awk -F'=' '{print $2}'`
fname=`basename $audiofile`
cp ./xtra/input/${fname} ../runtime/input/

echo 'echo `date`' >> ../runtime/run.sh
echo "bash code/slidezilla.sh $1 -cf tour/atour-small.properties 2>bg.log 1>fg.log" >> ../runtime/run.sh
echo 'echo `date`' >> ../runtime/run.sh