# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Formatter;

use strict;
use PPresenter::StyleElem;
use base 'PPresenter::StyleElem';

use constant defaults =>
{ type         => 'formatter'
, -nestIndents => [ [ '+0', '10%'  ]
                  , [ '+0', '17%'  ]
                  , [ '-1', '23%'  ]
                  , [ '+0', '28%'  ] ]
 
, -lineSkip    => 0.4    # an empty line.
, -listSkip    => 0.3    # above each list-item.
, -imageHSpace => '10%'
, -imageVSpace => '10%'
};

#
# strip
#    Remove all formatting info from the string.
#

sub strip($$$)
{   my ($former, $show, $slide, $string) = @_;

    warn "WARNING: formatter ", ref $former, " does not implement strip.\n";
    return $string;
}

#
# format
#    Format a string into a PPresenter::Text-widget.
#

sub format($)
{   my ($former, $args) = @_;
    print STDERR "WARNING: formatter does not implement format().\n";

}

#
# Information about nesting of lists.
#

sub getNestInfo($$)
{   my ($former, $view, $nest) = @_;
    my $nr_nests = @{$former->{-nestIndents}};
    my $takenest = $nest > $nr_nests ? $nr_nests : $nest;

    (@{$former->{-nestIndents}[$takenest]}, $view->getNestImage($nest));
}

1;
