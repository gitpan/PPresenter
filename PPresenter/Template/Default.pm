# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Template::Default;

@INCLUDES  = qw(
    PPresenter::Template::Default::Empty
    PPresenter::Template::Default::FrontPage
    PPresenter::Template::Default::TitleMain
    PPresenter::Template::Default::TitleLeftRight
    PPresenter::Template::Default::BigLeftTitleRight
    PPresenter::Template::Default::BigRightTitleLeft
    PPresenter::Template::Default::TitleLeftMiddleRight
    PPresenter::Template::Default::Title
    PPresenter::Template::Default::Main
    PPresenter::Template::Default::SlideNotes
    );

use strict;
use PPresenter::Template;
use base 'PPresenter::Template';

sub make_HTML_Linear($)
{   my ($templ, $args);

    my @parts;
    push @parts, $templ->{-left}     if exists $templ->{-left};
    push @parts, $templ->{-right}    if exists $templ->{-right};
    push @parts, $templ->{-main}     if exists $templ->{-main};
    push @parts, @{$templ->{-place}} if exists $templ->{-place};

    join "\n<P>\n",
       map {$templ->toHTML($args, $templ->{-main})}
           @parts;
}

package PPresenter::Template::Default::BigLeftTitleRight;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant defaults =>
{ -name         => 'default big-left title right'
, -aliases      => [ 'dbltr', 'big-left title right', 'bltr',
                     'dtrbl', 'title right big-left', 'trbl' ]
, -left         => undef
, -right        => undef
};

sub prepareSlide($$)
{   my ($templ, $args) = @_;

    my $sep  = $templ->toPercentage($templ->{-areaSeparation});
    my $colw = (1-$sep)/2;
    my $tbh  = $templ->toPercentage($templ->{-titlebarHeight});
    my $t    = $tbh + $sep;

    my $view = $args->{view};
    unshift @{$templ->{-place}}
        , [ -$colw, 0,  $colw, $tbh, $view->formatter->titleFormat
                    ($view, $args->{slide}->getTitle) ]
        , [ 0, 0,       $colw, 1,    $templ->{-left}  ]
        , [ -$colw, $t, $colw, 1-$t, $templ->{-right} ];

    $templ->SUPER::prepareSlide($args);
}

sub make_HTML_table($$)
{   my ($templ, $args) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD VALIGN=top ROWSPAN=2>"
    . $templ->toHTML($args, $templ->{-left})
    . "</TD><TD ALIGN=center WIDTH=50%><H1>"
    . $templ->toHTML($args, $args->{slide}->getTitle)
    . "</H1></TD></TR>\n<TR><TD VALIGN=top WIDTH=50%>"
    . $templ->toHTML($args, $templ->{-right})
    . "</TD></TR>\n</TABLE>\n";
}


package PPresenter::Template::Default::BigRightTitleLeft;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant defaults =>
{ -name         => 'default big-right title left'
, -aliases      => [ 'dbrtl', 'big-right title left', 'brtl'
                   , 'dtlbr', 'title left big-right', 'tlbr' ]
, -left         => undef
, -right        => undef
};

sub prepareSlide($)
{   my ($templ, $args) = @_;

    my $sep  = $templ->toPercentage($templ->{-areaSeparation});
    my $colw = (1-$sep)/2;
    my $tbh  = $templ->toPercentage($templ->{-titlebarHeight});
    my $t    = $tbh + $sep;

    my $view = $args->{view};
    unshift @{$templ->{-place}}
        , [ 0, 0,      $colw, $tbh, $view->formatter->titleFormat
                   ($view, $args->{slide}->getTitle) ]
        , [ 0, $t,     $colw, 1-$t, $templ->{-left}  ]
        , [ -$colw, 0, $colw, 1,    $templ->{-right} ];

    $templ->SUPER::prepareSlide($args);
}

sub make_HTML_table($$)
{   my ($templ, $args) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD ALIGN=center WIDTH=50%><H1>"
    . $templ->toHTML($args, $args->{slide}->getTitle)
    . "</H1></TD>\n<TD COLSPAN=2 VALIGN=top>"
    . $templ->toHTML($args, $templ->{-right})
    . "</TD></TR>\n<TR><TD VALIGN=top WIDTH=50%>"
    . $templ->toHTML($args, $templ->{-left})
    . "</TD></TR>\n</TABLE>\n";
}


package PPresenter::Template::Default::Empty;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant defaults =>
{ -name         => 'default empty'
, -aliases      => [ 'de', 'empty', 'e' ]
};


package PPresenter::Template::Default::FrontPage;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant defaults =>
{ -name         => 'default front page'
, -aliases      => [ 'dfp', 'front page', 'fp' ]
, -author       => undef
, -company      => undef
, -talk         => undef
, -date         => undef
};

sub prepareSlide($)
{   my ($templ, $args) = @_;

print "Not implemented yet.\n";

    $templ;
}


package PPresenter::Template::Default::Main;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant defaults =>
{ -name         => 'default main'
, -aliases      => [ 'dm', 'main', 'm' ]
, -main         => undef
};

sub prepareSlide($)
{   my ($templ, $args) = @_;

    my $tbh  = $templ->toPercentage($templ->{-titlebarHeight});
    my $t    = $tbh + $templ->toPercentage($templ->{-areaSeparation});

    unshift @{$templ->{-place}}, [ 0, 0, 1, 1, $templ->{-main} ];

    $templ->SUPER::prepareSlide($args);
}

sub make_HTML_table($$)
{   my ($templ, $args) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD VALIGN=top>"
    . $templ->toHTML($args, $templ->{-main})
    . "</TD></TR>\n</TABLE>\n";
}


package PPresenter::Template::Default::SlideNotes;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant defaults =>
{ -name         => 'default slidenotes'
, -aliases      => [ 'slidenotes', 'SlideNotes', 'sn' ]
};

sub prepareSlide($)
{   my ($templ, $args) = @_;

    my $tbh  = $templ->toPercentage($templ->{-titlebarHeight});
    my $t    = $tbh + $templ->toPercentage($templ->{-areaSeparation});

    unshift @{$templ->{-place}}, [ 0, 0, 1, 1, $templ->{-notes} ];

    $templ->SUPER::prepareSlide($args);
}

sub make_HTML_table($$)
{   my ($templ, $args) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD VALIGN=top>"
    . $templ->toHTML($args, $templ->{-notes})
    . "</TD></TR>\n</TABLE>\n";
}


package PPresenter::Template::Default::Title;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant defaults =>
{ -name         => 'default title'
, -aliases      => [ 'dt', 'title', 't' ]
};

sub prepareSlide($)
{   my ($templ, $args) = @_;
    my $view = $args->{view};

    unshift @{$templ->{-place}}
        , [ 0, 0,  1, $templ->toPercentage($templ->{-titlebarHeight})
            , $view->formatter->titleFormat($view, $args->{slide}->getTitle)
          ];

    $templ->SUPER::prepareSlide($args);
}

sub make_HTML_table($$)
{   my ($templ, $args) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD ALIGN=center><H1>"
    . $templ->toHTML($args, $args->{slide}->getTitle)
    . "</H1></TD></TR>\n</TABLE>\n";
}


package PPresenter::Template::Default::TitleLeftMiddleRight;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant defaults =>
{ -name         => 'default title left middle right'
, -aliases      => [ 'dtlmr', 'title left middle right', 'tlmr',
                     'dtrml', 'title right middle left', 'trml',
                     'default title right middle left' ]
, -left         => undef
, -middle       => undef
, -right        => undef
};

sub prepareSlide($$$)
{   my ($templ, $args) = @_;

    my $sep  = $templ->toPercentage($templ->{-areaSeparation});
    my $colw = (1-2*$sep)/3;
    my $tbh  = $templ->toPercentage($templ->{-titlebarHeight});
    my $t    = $tbh + $sep;
    my $view = $args->{view};

    unshift @{$templ->{-place}}
        , [ 0, 0,        1, $tbh, $view->formatter->titleFormat
                         ($view, $args->{slide}->getTitle) ]
        , [ 0, $t,          $colw, 1-$t, $templ->{-left}   ]
        , [ $colw+$sep, $t, $colw, 1-$t, $templ->{-middle} ]
        , [ 1-$colw, $t,    $colw, 1-$t, $templ->{-right}  ];

    $templ->SUPER::prepareSlide($args);
}

sub make_HTML_table($$)
{   my ($templ, $args) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD VALIGN=top ALIGN=center COLSPAN=2><H1>"
    . $templ->toHTML($args, $args->{slide}->getTitle)
    . "</H1></TD></TR>\n<TR><TD VALIGN=top WIDTH=33%>"
    . $templ->toHTML($args, $templ->{-left})
    . "</TD><TD VALIGN=top WIDTH=33%>"
    . $templ->toHTML($args, $templ->{-middle})
    . "</TD><TD VALIGN=top WIDTH=33%>"
    . $templ->toHTML($args, $templ->{-right})
    . "</TD></TR>\n</TABLE>\n";
}



package PPresenter::Template::Default::TitleLeftRight;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant defaults =>
{ -name         => 'default title left right'
, -aliases      => [ 'dtlr', 'title left right', 'tlr',
                     'dtrl', 'title right left', 'trl',
                     'default title right left' ]
, -left         => undef
, -right        => undef
};

sub prepareSlide($$$)
{   my ($templ, $args) = @_;

    my $sep  = $templ->toPercentage($templ->{-areaSeparation});
    my $colw = (1-$sep)/2;
    my $tbh  = $templ->toPercentage($templ->{-titlebarHeight});
    my $t    = $tbh + $sep;
    my $view = $args->{view};

    unshift @{$templ->{-place}}
        , [ 0, 0,        1, $tbh, $view->formatter->titleFormat
                      ($view, $args->{slide}->getTitle) ]
        , [ 0, $t,       $colw, 1-$t, $templ->{-left}   ]
        , [ 1-$colw, $t, $colw, 1-$t, $templ->{-right}  ];

    $templ->SUPER::prepareSlide($args);
}

sub make_HTML_table($$)
{   my ($templ, $args) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD VALIGN=top COLSPAN=2><H1>"
    . $templ->toHTML($args, $args->{slide}->getTitle)
    . "</H1></TD></TR>\n<TR><TD VALIGN=top WIDTH=50%>"
    . $templ->toHTML($args, $templ->{-left})
    . "</TD><TD ALIGN=center WIDTH=50%>"
    . $templ->toHTML($args, $templ->{-right})
    . "</TD></TR>\n</TABLE>\n";
}



package PPresenter::Template::Default::TitleMain;

use strict;
use PPresenter::Template::Default;
use base 'PPresenter::Template::Default';

use constant defaults =>
{ -name         => 'default title main'
, -aliases      => [ 'dtm', 'title main', 'tm', 'default' ]
, -main         => undef
};

sub prepareSlide($)
{   my ($templ, $args) = @_;

    my $tbh  = $templ->toPercentage($templ->{-titlebarHeight});
    my $t    = $tbh + $templ->toPercentage($templ->{-areaSeparation});
    my $view = $args->{view};

    unshift @{$templ->{-place}}
        , [ 0, 0,       1, $tbh, $view->formatter->titleFormat
                    ($view, $args->{slide}->getTitle) ]
        , [ 0, $t,      1, 1-$t,    $templ->{-main}   ];

    $templ->SUPER::prepareSlide($args);
}

sub make_HTML_table($$)
{   my ($templ, $args) = @_;

    "<TABLE WIDTH=100%>\n<TR><TD ALIGN=center><H1>"
    . $templ->toHTML($args, $args->{slide}->getTitle)
    . "</H1></TD></TR>\n<TR><TD VALIGN=top>"
    . $templ->toHTML($args, $templ->{-main})
    . "</TD></TR>\n</TABLE>\n";
}

1;
