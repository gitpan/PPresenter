# Copyright (C) 1999, Free Software Foundation Inc.

# The plain format is only a far-going simplification on the
# markup formatter.  The whole text is put in <PRE>

package PPresenter::Formatter::Plain;

use strict;
use PPresenter::Formatter::Markup;
use base 'PPresenter::Formatter::Markup';

use Tk;

use constant defaults =>
{ -name    => 'plain'
, -aliases => undef
};

sub strip($$$)
{   my ($self, $show, $slide, $string) = @_;
    $string =~ s/<[^>]*>//g;
    return $string ;
}

sub format($$)
{   my ($self, $args, $contents) = @_;

    $self->SUPER::format($args, <<PREFORMAT);
<PRE>
$contents
<PRE>
PREFORMAT
}

sub titleFormat($$)
{   my ($self, $slide, $title) = @_;
    "<TITLE><TT>$title</TT>";
}

1;
