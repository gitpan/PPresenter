#!/usr/local/bin/perl -w
# Copyright (C) 2000, Free Software Foundation FSF.

use ExtUtils::MakeMaker;

WriteMakefile
( NAME      => 'PPresenter'
, VERSION   => 'v1.10'
, AUTHOR    => 'Mark Overmeer'
, ABSTRACT  => 'Create presentations with Perl and Tk'
, PREREQ_PM => { "Tk"               => "800.012" }
);

