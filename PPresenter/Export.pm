# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Export;

use strict;
use PPresenter::Object;
use base 'PPresenter::Object';

use vars qw(@EXPORT @papersizes);
@EXPORT = qw/@papersizes/;

use constant defaults =>
{ -viewports      => 'ALL'      # NOTES, SLIDES, ALL or name or [ names ]
, -exportSlide    => 'ACTIVE'   # ACTIVE, CURRENT, or ALL
, -includeBorders => 0

, -imageFormat    => 'gif'
, -imageWidth     => undef
, -imageQuality   => 80
};

# sizes at 72dpi.
@papersizes =
( [ 'no scaling' => 0,0 ]
, [ 'own size:' => undef, undef ]
, [ Letter => 612,792 ], [ Legal => 612,1008 ], [ Executive => 537,720 ]
, [ A3 => 842,1190 ], [ A4 => 595,842 ], [ A5 => 421,595]
, [ B4 => 709,1002 ], [ B5 => 501,709 ]
);

sub getPaperSize($)
{   my ($export, $name) = @_;
    foreach (@papersizes)
    {   return @$_[1,2] if $_->[0] eq $name;
    }
    die "Unknown paper size $name.\n";
}

sub makeSlideExports($$$$@)
{   my ($export, $show, $slide, $viewports, $function) = splice @_, 0, 5;

    # viewports are entered in has-order, but shall be produced in
    # the order of creation.  Limited number of viewports, so don't
    # bother about complexity.

    my @viewports;
    foreach ($show->getViewports)
    {   my $name = "$_";
        push @viewports, $_
            if grep {$name eq $_} @$viewports;
    }

    return map {$slide->exportViews($show, $_,
        $export->{-includeBorders}, $function, export => $export, @_)}
            @viewports;
}

my $imgs_read = 0;

sub getWindowImage($$$)
{   my ($export, $show, $opts) = @_;
    my ($display, $window, $borders)
        = @$opts{ qw/display window_id borders/ };

    my $img = $show->runsOnX
            ? $export->get_x11_image($display, $window, $borders)
            : $export->get_windows_image($display, $window, $borders);

    $imgs_read++;
    $img;
}

sub get_x11_image($$$)
{   my ($export, $display, $window, $borders) = @_;
    my $tmp   = "/tmp/gpp$$-$imgs_read.xwd";

    my $cmd   = "xwd >$tmp -display $display -id $window -silent";
    $cmd     .= " -nobdrs" unless $borders;

    system($cmd)==0 or die "Cannot start $cmd.\n";

    my $image = $export->readImage($tmp);
    unlink $tmp;

    $image;
}

sub get_windows_image($$$)
{   my ($export, $display, $window, $borders) = @_;
    die "Can't get dumps of window screens yet.";
}

sub readImage($)             # You shall override this.
{   my ($export, $file) = @_;
    die "You shall implement readImage for file $file";
}

sub polishImage($)           # You may override this.
{   my ($export, $img) = @_;
    $img;
}

sub tkImageSettings($$)
{   my ($export, $show, $parent) = @_;

    my $im = $parent->LabFrame
    ( -label     => 'images'
    , -labelside => 'acrosstop'
    );

    $im->Label
    ( -text     => 'Format'
    , -anchor   => 'e'
    )->grid($im->Entry(-textvariable => \$export->{-imageFormat})
           , -sticky => 'ew');

    $im->Label
    ( -text     => 'Width'
    , -anchor   => 'e'
    )->grid($im->Entry(-textvariable => \$export->{-imageWidth})
           , -sticky => 'ew');

    $im->Label
    ( -text     => 'Quality'
    , -anchor   => 'e'
    )->grid($im->Entry(-textvariable => \$export->{-imageQuality})
           , -sticky => 'ew');

    $im->Checkbutton
    ( -text     => 'Show window borders'
    , -relief   => 'flat'
    , -anchor   => 'w'
    , -variable => \$export->{-includeBorders}
    )->grid(-columnspan => 2, -sticky => 'ew');

    $im;
}

sub tkViewportSettings($$)
{   my ($export, $show, $parent) = @_;
    my @viewports = $show->getViewports;

    if(@viewports==1)
    {   $export->{vp}{"$viewports[0]"} = 1;
        return undef;
    }

    my $vp = $parent->LabFrame
    ( -label     => 'viewports'
    , -labelside => 'acrosstop'
    );

    foreach (@viewports)
    {   my ($notes, $name) = ($_->showSlideNotes, "$_");
        $export->{vp}{$name} =
              ref $export->{-viewports} eq 'ARRAY'
            ? grep {$name eq $_} @{$export->{-viewports}}
            : $export->{-viewports} eq 'ALL'    ? 1
            : $export->{-viewports} eq 'SLIDES' ? ! $_->showSlideNotes
            : $export->{-viewports} eq 'NOTES'  ? $_->showSlideNotes
            : $export->{-viewports} eq $name;     # single name specified.

        $vp->Checkbutton
        ( -text     => ($notes ? "$name (notes)" : $name)
        , -relief   => 'flat'
        , -anchor   => 'w'
        , -variable => \$export->{vp}{$name}
        )->grid(-sticky => 'nsew');
    }

    $vp;
}

sub selectedViewports()
{   my $export = shift;
    map {$export->{vp}{$_} ? ("$_") : ()}
        keys %{$export->{vp}};
}

sub tkSlideSelector($)
{   my ($export, $parent) = @_;

    $parent->Optionmenu
    ( -options  => [ 'selected slides', 'current slide', 'all slides' ]
    , -command  => sub { $export->setSelectedSlide(shift) }
    );
}

sub setSelectedSlide($)
{   my ($export, $option) = @_;
    $export->{-exportSlide} = $option eq 'current slide'   ? 'CURRENT'
                            : $option eq 'selected slides' ? 'ACTIVE'
                            : $option eq 'all slides'      ? 'ALL'
      : die "Unknown export option `$option'.\n";
}

sub selectedSlides($)
{   my ($export, $show) = @_;

    my $slides = $export->{-exportSlide};
    return $show->{current_slide}               if $slides eq 'CURRENT';
    return grep {$_->isActive} $show->getSlides if $slides eq 'ACTIVE';
    return $show->getSlides                     if $slides eq 'ALL';

    die "-exportSlide shall contain CURRENT, ACTIVE, or ALL, not $slides.\n";
}

sub createDirectory($$)
{   my ($export, $parent, $directory) = @_;
    return 1 if -d $directory || mkdir $directory, 0755;

    $parent->Dialog
    ( -title   => 'Export images'
    , -text    =>
      "Directory $directory does not exist, and it can not be created either."
    , -buttons => [ 'Bummer' ]
    , -bitmap  => 'error'
    )->Show('-global');

    return 0;
}

sub optionlist($$@)
{   my ($export, $parent, $flag) = splice @_, 0, 3;

    my $default = $export->{$flag};
    die "Cannot find default $default for flag $flag.\n"
        unless grep {$default eq $_} @_;

    $parent->Optionmenu
    ( -options => [ $default, grep {$_ ne $default} @_ ]
    , -variable => \$export->{$flag}
    );
}

sub popup($$)
{   my ($export, $show, $screen) = @_;
    my $popup = $export->getPopup($show, $screen)
                       ->Popup(-popover => 'cursor');
}

1;
