# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::SlideView;

use strict;
use PPresenter::Object;
use base 'PPresenter::Object';

use Tk qw(DONT_WAIT ALL_EVENTS DoOneEvent);

sub new($$$)
{   my ($class, $show, $slide, $style_flags, $viewport) = @_;

    # Collect the options from (sub-classes of) Slide.
    my $view = bless
    { -name          => "Slide $slide view $viewport"
    , show           => $show
    , slide          => $slide
    , viewport       => $viewport
    , screen         => $viewport->getScreen
    , canvas         => $viewport->getCanvas
    , style_elements => $viewport->getStyleElems($slide, $style_flags)
    }, $class;

    $view->getOptions($class)->InitObject;
}

sub setOptions($) {$_[0]->{options} = $_[1]}
sub decoration()  {$_[0]->{decoration}}
sub fontset()     {$_[0]->{fontset}   }
sub formatter()   {$_[0]->{formatter} }
sub template()    {$_[0]->{template}  }
sub dynamic()     {$_[0]->{dynamic}   }

sub getViewport() {$_[0]->{viewport}  }
sub showsOnViewport($) {"$_[0]->{viewport}" eq "$_[1]"}

sub getCanvas()   {$_[0]->{viewport}->getCanvas}
sub nextPhase()   {$_[0]->{program}->nextPhase}
sub image(@)      {shift->{show}->image(@_)}

#
# Just passing on...
#

sub hasBackdrop()
{   my $view = shift;
    $view->{decoration}->hasBackdrop($view->{viewport}->getDevice);
}

sub getColor(@)
{   my $view = shift;
    $view->{decoration}->getColor($view->{viewport}->getDevice, @_);
}

sub findFontSize($@)
{   my $view = shift;
    $view->{fontset}->findFontSize($view->{viewport}, @_);
}

sub getBounds() {$_[0]->{decoration}->getBounds}
sub getFont(@)  {shift->{fontset}->getFont(@_)}
sub getTitle()  {$_[0]->{template}->getTitle}
sub format(@)   {shift->{formatter}->format(@_)}

sub getNestImage($)
{   my ($view, $name) = @_;
    my ($geom, $img) = $view->{decoration}->getNestImageDef($name);

    $view->{show}->image
      ( (ref $img ? $img : (-file => $img))
      , (defined $geom
         ? (-sizeBase => $geom, -resize => 1)
         : (-resize => 0)
        )
      );
}

#
#
#

sub makeBackground()
{   my $view = shift;

    $view->{viewport}->setBackgroundId(
        $view->{decoration}->makeBackground
           ( $view->{viewport}->getBackgroundId
           , @$view{qw/show slide viewport/}
           ));
}

# Just before a slide is presented, the user-spec is merged with
# the style-element description.  When the slide is removed from
# display, the merge is removed again, because it consumes quite
# a lot of memory.

sub explode($$)
{   my ($view, $slide, $options) = @_;

    foreach (keys %{$view->{style_elements}})
    {   my $elem = $view->{style_elements}{$_}->copy;

        foreach (keys %$options)
        {   next unless exists $elem->{$_};
            $elem->{$_} = $options->{$_};
        }

        $view->{$_} = $elem;
    }
}

sub implode
{   my ($view, $slide) = @_;

    map {delete $slide->{$_}}
        keys %{$view->{style_elements}};
}

# This is a dirty trick: to collect all options of all style elements
# into one hash, I shape-shift the hash from elem to elem.  Blurk!

sub collectOptions($)
{   my ($view,$collection) = @_;
    foreach (keys %{$view->{style_elements}})
    {   my $class = ref $view->{style_elements}{$_};
        bless $collection, $class;
        $collection->getOptions($class);
    }
    $view;
}

my $unique_id = 0;

sub prepare($$)
{   my ($view, $slide) = @_;

    $view->explode($slide, $view->{options});

    my $displace_x = defined $view->{displace_x}
                   ? $view->{displace_x}
                   : ($view->{displace_x} = $view->{canvas}->width+10);

    my $show       = $view->{show};
    $view->{program} = $view->dynamic->makeProgram($show, $view, $displace_x);

    $view->template->prepareSlide(
       { show       => $show
       , slide      => $slide
       , view       => $view
       , viewport   => $view->{viewport}
       , canvas     => $view->{canvas}
       , screen     => $view->{screen}
       , program    => $view->{program}
       , displace_x => $displace_x
       , id         => ($view->{id} = "s".$unique_id++)
       } );

    $view->implode($slide);
}

sub show($)
{   my ($view,$slide) = @_;
    $view->{viewport}->setSlide($slide, $view->{id});
    $view->makeBackground;
}

#
# Program
#

sub addProgram(@)
{   my $view = shift;
    $view->{dynamic}->parse($view->{program}, $view->{slide}, @_);
}

sub startProgram()
{   my $view = shift;
    $view->{viewport}->startProgram($view->{program});
}

sub removeProgram()
{   delete shift->{program};
}

#
# Export
#

sub exportView($$@)
{   my ($view, $borders, $function) = splice @_, 0, 3;
    my ($viewport, $show) = @$view{ qw/viewport show/ };

    $viewport->raise;
    $viewport->sync;

    foreach (1..30)
    {   1 while DoOneEvent(DONT_WAIT|ALL_EVENTS);
        $viewport->after(100);
    }

    my %opts =
    ( window_id => ($borders ? $viewport->getScreenId : $viewport->getCanvasId)
    , borders   => $borders
    , viewport  => $viewport
    , display   => $viewport->getDisplay
    , view      => $view
    );

    map {$opts{$_} = $view->{$_}} qw/show slide canvas template formatter/;

    while(@_)                     # Extra user options.
    {   my ($key, $value) = (shift, shift);
        $opts{$key} = $value;
    }

    if(ref $function eq 'ARRAY')  # function = [ CODE, arg, ... ]
    {   @_ = @$function;
        $function = shift;
        $function->(@_, \%opts);
    }
    else
    {   $function->(\%opts);      # function = &f
    }

    $view;
}

1;
