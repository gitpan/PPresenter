# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Export::Website;

use strict;
use vars '@ISA';

use PPresenter::Export;
use base 'PPresenter::Export';


# Produce web-pages for the slides.
# The module contains a lot of small routines to simplify extention
# and adaptation to personal needs.

use constant defaults =>
{ -name         => 'Website producer'
, -aliases      => undef

, -slideAs      => 'IMAGE'        # IMAGE, TABLE, LINEAR, or SKIP
, -notesAs      => 'SKIP'         #     same

, -outputDir    => 'html'
, -indexFile    => 'index.html'
};

sub makeSlides($$)
{   my ($export, $show, $parent) = @_;

    return if 'Cancel' eq $parent->Dialog
    (   -title    => 'Starting Export'
    ,   -text     => <<TEXT
Starting the export of you presentation into a website.

Each of the slides will be shown, and then has its picture taken.

Do not touch your mouse while the processing is going on.
TEXT
    ,   -bitmap   => 'info'
    ,   -buttons  => [ 'OK', 'Cancel' ]
    )->Show;

    my $dir    = $export->{-outputDir};
    -d $dir || mkdir $dir, 0755
        or die "Cannot create directory $dir: $^E.\n";
 
    my @slides    = $export->selectedSlides($show);
    my @viewports = $export->selectedViewports($show);

    for(my $s=0; $s<@slides; $s++)
    {   my $slide    = $slides[$s];
        my $previous = ($s==0        ? undef : $slides[$s-1]);
        my $next     = ($s==$#slides ? undef : $slides[$s+1]);
        $export->makeSlide($show, $slide, \@viewports
             , $export->slide2place($slide), $previous, $next);
    }

    $export->makeMainPage($show, $export->slide2place(undef));

    $parent->Dialog
    (   -title    => 'Ready'
    ,   -text     => 'The website is ready.'
    ,   -bitmap   => 'info'
    ,   -buttons  => [ 'OK' ]
    )->Show;

    $export;
}

my @views;
sub makeSlide($$$)
{   my ($export, $show, $slide, $vps, $file, $previous, $next) = @_;

    print Presenter::TRACE "Working on slide $slide, file $file.\n";

    my ($slidename, $showname) = ("$slide", "$show");
    my $title  = $export->Title($show, $slide);
    my $chapter= $export->Chapter($show, $slide);

    my $logo   = $export->PageLogo($show, $slide);
    my $vindex = $export->VerticalIndex($show, $slide, $previous, $next);
    my $commer = $export->Commercial($show, $slide);
    my $header = $export->Header( $show, $slide, $logo, $title, $chapter
                                , $commer, $vindex);

    @views     = ();
    $export->makeSlideExports($show, $slide, $vps, \&makeSlideView);

    my $extra  = $export->ExtraText($show, $slide);
    my $hindex = $export->HorizontalIndex($show, $slide, $previous, $next);
    my $sig    = $export->Signature($show, $slide);
    my $footer = $export->Footer($show, $slide, $hindex, $sig);

    local $"   = "<P>";
    open HTML, ">$file" or die "Cannot write to file $file.\n";
    print HTML "$header\n@views\n$extra\n$footer\n";
    close HTML;

    $export;
}

sub makeMainPage($)
{   my ($export, $show, $file) = @_;

    my $first  = $show->find(slide => 'FIRST');

    my $logo   = $export->PageLogo($show, undef);
    my $commer = $export->Commercial($show, undef);
    my $vindex = $export->VerticalIndex($show, undef, undef, $first);
    my $header = $export->Header( $show, undef, $logo, "$show"
                                , "$show", $commer, $vindex);

    my $intro  = $export->ExtraText($show, undef);
    my $mindex = $export->MainPageIndex($show);

    my $hindex = $export->HorizontalIndex($show, '', '', $first);
    my $sig    = $export->Signature($show, undef);
    my $footer = $export->Footer($show, undef, $hindex, $sig);

    open HTML, ">$file" or die "Cannot write to file $file.\n";
    print HTML "$header\n$intro\n<P>$mindex\n<P>\n$footer\n";
    close HTML;

    $export;
}

sub makeSlideView($)
{   my ($opts) = @_;
    my ($export, $viewport, $template, $slide, $show)
                      = @$opts{qw/export viewport template slide show/};

    my $show_as = $export->{$viewport->showSlideNotes ? '-notesAs':'-slideAs'};

    return undef if $show_as eq 'SKIP';

    if($show_as eq 'TABLE')
    {    my $part  = $template->makeHTMLTable($opts);
         push @views, $export->SlideTable($opts, $part)  if $part;
    }
    elsif($show_as eq 'LINEAR')
    {    my $part  = $template->makeHTMLLinear($opts);
         push @views, $export->SlideLinear($opts, $part) if $part;
    }
    elsif($show_as eq 'IMAGE')
    {    my $image = $export->view2image($show, $opts);
         push @views, $export->SlideImage($image, $slide,$opts) if $image;
    }
}

#
# Extend the routines below.
#

sub slideDir($)
{   my ($export, $slide) = @_;
    my $slidedir = "$export->{-outputDir}/" . $slide->getNumber;

    -d $slidedir || mkdir $slidedir, 0755
        or die "Couldn't create directory $slidedir.\n";

    $slidedir;
}

sub slide2place($)
{   my ($export, $slide) = @_;
    my $dir = $slide ? $export->slideDir($slide) : $export->{-outputDir};
    "$dir/$export->{-indexFile}";
}

sub slide2main()
{   my $export = shift;
    "../$export->{-indexFile}";
}

sub main2slide($)
{   my ($export, $slide) = @_;
    $slide->getNumber . "/$export->{-indexFile}";
}

sub slide2slide($)
{   my ($export, $slide) = @_;
    "../" . $slide->getNumber . "/$export->{-indexFile}";
}

sub Title($$)
{   my ($export, $show, $slide) = @_;
    my ($slidename, $showname) = ("$slide", "$show");
    $showname eq $slidename ? $showname : "$showname, $slidename";
}

sub Chapter($$)
{   my ($export, $show, $slide) = @_;
    my ($slidename, $showname) = ("$slide", "$show");

    $showname eq $slidename
    ? $slidename
    : "<FONT SIZE=-1>$showname</FONT><BR> $slidename";
}

sub Header($$$$$$$)
{   my ( $export, $show, $slide, $logo, $title
       , $chapter, $commercial, $index) = @_;

    <<header;
<HTML>
<HEAD><TITLE>$title</TITLE></HEAD>
<BODY BGCOLOR=#ffffff TEXT=#000000>
$commercial
<TABLE WIDTH=100%>
<TR><TD>$logo</TD>
    <TD ALIGN=center><H1>$chapter</H1></TD></TR>
<TR><TD VALIGN=top>
$index
    </TD><TD VALIGN=top>
header
}

sub Footer($$$$)
{   my ($export, $show, $slide, $index, $signature) = @_;

    <<footer;
    </TD></TR>
<TR><TD>&nbsp;</TD>
    <TD VALIGN=top>
$index
    <HR NOSHADE>
$signature
    </TD></TR>
</TABLE>
</HTML>
footer
}

sub Commercial($$)
{   my ($export, $show, $slide) = @_;

    my $date = localtime time;

    <<commercial;
<!-- Produced by Portable Presenter on $date
     PPresenter:  http://www.dhp.nl/~gpp/
  -->
commercial
}

sub PageLogo($$)
{   my ($export, $show, $slide) = @_;
    '';
}

sub ExtraText($$)
{   my ($export, $show, $slide) = @_;
    '';
}

sub VerticalIndex($$$$)
{   my ($export, $show, $slide, $previous, $next) = @_;

    return '' unless $slide;

    my $index = "<A HREF=".$export->slide2main.">Main</A><BR>\n";

    $index   .= "back: <A HREF=".$export->slide2slide($previous)
                . ">$previous</A><BR>\n" if $previous;

    $index   .= "next: <A HREF=".$export->slide2slide($next)
                . ">$next</A><BR>\n" if $next;

    $index;
}

sub HorizontalIndex($$$$)
{   my ($export, $show, $slide, $previous, $next) = @_;

    my $main = "<A HREF=".$export->slide2main.">Main</A><BR>\n";

    $previous = $previous
       ? "&lt;&nbsp;<A HREF=".$export->slide2slide($previous).">$previous</A>"
       : $slide
       ? $main
       : '';

    $next     = ($next && $slide)
       ? "<A HREF=".$export->slide2slide($next).">$next</A>&nbsp;&gt;\n"
       : $next
       ? "<A HREF=".$export->main2slide($next).">$next</A>&nbsp;&gt;\n"
       : $main;

    <<index;
<CENTER>
<TABLE WIDTH=80% BORDER=0 CELLSPACING=5>
<TR><TD ALIGN=left  VALIGN=top>$previous</TD>
    <TD ALIGN=right VALIGN=top>$next</TD></TR>
</TABLE>
</CENTER>
index
}

sub MainPageIndex($)
{   my ($export, $show) = @_;

    my ($table, @right);
    foreach ($show->getSlides)
    {   my $number = $_->getNumber;
        my $name   = "$_";
        my $url    = $export->main2slide($_);

        push @right, <<line
<TD ALIGN=right VALIGN=top><A HREF="$url">$number</A></TD>
<TD ALIGN=left  VALIGN=top>$name</TD>
line
    }
    push @right, "<TD COLSPAN=2>&nbsp;</TD>" if @right%2==1;

    my @left = splice @right, 0, @right/2;

    $table  .= "<TR>".shift(@left).shift(@right)."</TR>\n"
        while @left;

    <<index;
<CENTER>
<TABLE WIDTH=80%>
<TR><TH COLSPAN=2 ALIGN=left>Slides:</TH></TR>
$table
</TABLE>
</CENTER>
index

}

sub Signature($$)
{   my ($export, $show, $slide) = @_;
    my $date      = localtime;
    my $slidename = $slide ? "$slide" : '';
    my $showname  = "$show";

    my $title     = $slidename eq ''        ? $showname
                  : $slidename eq $showname ? $slidename
                  : "$showname, $slidename";

    <<signature;
<I>$title.<BR>
   Generated by <A HREF="http://www.dhp.nl/~gpp/">gpp</A>
   on $date.</I><BR>
signature
}

sub SlideTable($$)
{   my ($export, $opts, $html) = @_;

    <<include;
<!-- start viewport $opts->{viewport}, table -->
<CENTER>
<TABLE CELLPADDING=20 BGCOLOR=#eeeeee BORDER=1>
<TR><TD>$html</TD></TR>
</TABLE>
</CENTER>
<P>
<!-- end viewport $opts->{viewport} -->
include

}

sub SlideLinear($$)
{   my ($export, $opts, $html) = @_;

    <<include;
<!-- start viewport $opts->{viewport}, linear -->
$html
<P>
<!-- end viewport $opts->{viewport} -->
include

}

sub SlideImage($$$)
{   my ($export, $image, $slide, $opts) = @_;

    my $viewport = $opts->{viewport};

    $viewport    =~ s/\W/_/g;
    my $format   = lc $export->{-imageFormat};
    my $file     = $viewport . "." . lc($export->{-imageFormat});

    $export->writeImage($image, $export->slideDir($slide) . "/". $file);
    my ($width, $height) = $export->getDimensions($image);

    <<include;
<IMG SRC=$file WIDTH=$width HEIGHT=$height
 BORDER=0 HSPACE=15 VSPACE=15 ALIGN=center><P>
include
}

#
# The user interface to this module.
#

sub getPopup($$)
{   my ($export, $show, $screen) = @_;
    return $export->{popup}
        if exists $export->{popup};

    if($show->hasImageMagick)
    {   require PPresenter::Export::IM_Images;
        unshift @ISA, 'PPresenter::Export::IM_Images';
    }
    else
    {   require PPresenter::Export::Tk_Images;
        unshift @ISA, 'PPresenter::Export::Tk_Images';
    }

    $export->{popup} = my $popup = MainWindow->new(-screen => $screen
    , -title => 'Create a Website'
    );
    $popup->withdraw;

    my $vp  = $export->tkViewportSettings($show, $popup);
    my $fmt = $export->tkImageSettings($show,$popup);

    my $options = $popup->LabFrame
        ( -label     => "Don't know"
        , -labelside => 'acrosstop'
        );

    $options->Label
    ( -text     => 'export'
    , -anchor   => 'e'
    )->grid( $export->tkSlideSelector($popup)
           , -sticky => 'ew');

    $options->Label
    ( -text     => 'output directory'
    , -anchor   => 'e'
    )->grid( $options->Entry(-textvariable => \$export->{-outputDir})
           , -sticky => 'ew');

    $options->Label
    ( -text     => 'index file'
    , -anchor   => 'e'
    )->grid( $options->Entry(-textvariable => \$export->{-indexFile})
           , -sticky => 'ew');

    $options->Label
    ( -text     => 'slides as'
    , -anchor   => 'e'
    )->grid( $export->tkSlideFormatting($options, $show, 'slideAs')
           , -sticky => 'ew');

    if($show->containsSlideNotes)
    {   $options->Label
        ( -text     => 'notes as'
        , -anchor   => 'e'
        )->grid( $export->tkSlideFormatting($options, $show, 'notesAs')
               , -sticky => 'ew');
    }

    my $commands = $popup->Frame;
    $commands->Button
    ( -text      => 'Export'
    , -relief    => 'ridge'
    , -command   => sub { $popup->withdraw;
                          $export->makeSlides($show, $popup);
                        }
    )->grid($commands->Button
       ( -text      => 'Cancel'
       , -relief    => 'sunken'
       , -command   => sub {$popup->withdraw}
       )
       , -padx => 10, -pady => 10
    );

    $vp->pack(-fill => 'x') if $vp;
    $options->pack(-fill => 'x');
    $fmt->pack(-fill => 'x');
    $commands->pack(-fill => 'x');

    $popup;
}

sub tkSlideFormatting($$$)
{   my ($export, $parent, $show, $label) = @_;

    my @options;
    # first slide used as standard for show, which is incorrect... but it
    # is hard to decide differently.  I do not expect many people will
    # change to incompatible formatters or templates within the show.

    my $view    = $show->find(slide => 'FIRST')->getView('FIRST');
    my $linear  = $view->formatter->can('makeHTMLLinear');
    my $table   = $view->template->can('makeHTMLTable');

    push @options, 'image'     if $export->can('view2image');
    push @options, 'table'     if $table && $view->formatter->can('toHTML');
    push @options, 'flat text' if $linear;
    push @options, 'skip';

    $parent->Optionmenu
    ( -options  => \@options
    , -variable => \$export->{$label}
    , -command  => sub { $export->setSlideFormatting($label, shift) }
    );
}

sub setSlideFormatting($$$)
{   my ($export, $label, $option) = @_;
    $export->{"-$label"}
        = $option eq 'table'     ? 'TABLE'
        : $option eq 'flat text' ? 'LINEAR'
        : $option eq 'image'     ? 'IMAGE'
        : $option eq 'skip'      ? 'SKIP'
        : die "Unknown export option `$option'.\n";
}

sub getSlideFormatting($$)
{   my ($export, $value) = @_;
      $value eq 'TABLE'  ? 'table'
    : $value eq 'LINEAR' ? 'flat text'
    : $value eq 'IMAGE'  ? 'image'
    : $value eq 'SKIP'   ? 'skip'
    : undef
}

1;
