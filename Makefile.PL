#!/usr/local/bin/perl -w
# Copyright (C) 1999, Free Software Foundation Inc.

use ExtUtils::MakeMaker;

WriteMakefile( 'PREREQ_PM'    => { "Tk"               => "800.012" }
             , 'NAME'         => 'PPresenter'
             , 'VERSION_FROM' => 'PPresenter.pm'
             );

