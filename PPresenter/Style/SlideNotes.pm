# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Style::SlideNotes;

use strict;
use PPresenter::Style;
use base 'PPresenter::Style';

use constant defaults =>
{ -name       => 'SlideNotes'
, -aliases    => [ 'slidenotes', 'slide notes', 'Slide Notes', 'slideNotes' ]
};

sub InitObject(;)
{   my $style = shift;

    $style->SUPER::InitObject;

    $style->select(template   => 'slidenotes');
    $style->select(fontset    => 'default'   );
    $style->select(decoration => 'default'   );
    $style->select(formatter  => 'simple'    );

    $style;
}

1;
