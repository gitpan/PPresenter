# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Dynamic;

use strict;
use PPresenter::StyleElem;
use base 'PPresenter::StyleElem';

use PPresenter::Program;

#
# Used while initializing.
#

use constant defaults =>
{ type            => 'dynamic'
, -name           => undef
, -aliases        => undef
, -startPhase     => 0
};

sub makeProgram($$$)
{   my ($dynamic, $show, $view, $displace_x) = @_;

    my $program = PPresenter::Program->new
    ( startPhase   => $dynamic->{-startPhase}
    , show         => $show
    , view         => $view
    , viewport     => $view->getViewport
    , canvas       => $view->getCanvas
    , dx           => $displace_x
    );

    $program;
}

1;
