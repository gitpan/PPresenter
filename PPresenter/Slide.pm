# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Slide;

use strict;
use PPresenter::Object;
use base 'PPresenter::Object';

use PPresenter::SlideView;

use constant defaults =>
{ -name        => undef
, -aliases     => undef
, -title       => undef

, -reqtime     => '1m'     # expected time to use this slide.
, -active      => 1        # by default selected to be shown.
, -proceed     => 'STOP'   # STOP (for user), TIME (reqtime), NOW (go on)
, -tag         => undef    # may be used with one tag only.
, -tags        => undef    # after each slide initiation 'all' is added.
, -nextSlide   => undef    # next slide.
, -notes       => undef    # slide notes.

, show         => undef
};

my (@nested_options, $user_opts);

sub new($)
{   my $class = shift;

    # A slide has different kinds of options:
    #    - main info of the slide (%defaults list above)
    #    - style-element selections
    #    - viewport selections
    #    - style-element options.

    ## get nested option definitions
    @nested_options = ();
    unshift @nested_options, pop @_
        while ref $_[-1] eq 'HASH';
    $user_opts = { @_ };

    my $slide = bless {}, $class;
    $slide->getOptions($class)->InitObject;
}

sub InitObject()
{   my $slide = shift;

    # User-options which are about a slide, not a slide-view, are
    # copied in the slide structure. Do not mix the keys iterator with
    # a delete in the same hash!
    my @used_options;
    foreach (keys %$user_opts)
    {   next unless exists $slide->{$_};
        $slide->{$_} = delete $user_opts->{$_};
        push @used_options, $_;
    }
    delete @$user_opts{@used_options};

    my $show = $slide->{show};
    $slide->make_id($show);

    print Presenter::TRACE "Slide $slide->{number}: \"$slide\".\n";

    $slide->SUPER::InitObject;

    $slide->expand_views($show, $user_opts, \@nested_options);

    $slide->addTags( $slide->flatten(delete $slide->{-tags})
                   , $slide->flatten(delete $slide->{-tag})
                   , 'ALL');

    $slide->{-proceed} = 'STOP'
         unless $slide->validProceed($slide->{-proceed});

    $slide->{-reqtime} = $show->time2secs($slide->{-reqtime});

    $slide;
}

sub make_id($)
{   my ($slide,$show) = @_;

    $slide->{number}   = $show->getNumberSlides;   # count from 0

    my $title = $slide->{-title}
             || ($slide->{-title} = "Slide $slide->{number}");

    ($slide->{-name} = $title) =~ s/\s+/ /gs;
    $slide;
}

sub hasSlideNotes() {defined $_[0]->{-notes}}

sub expand_views($$$)
{   my ($slide, $show, $general, $nested_options) = @_;

    my @viewports = $show->getViewports;
    my ($other, @used_vps, @vp_options);
   
    # Look for the specified viewports.
    foreach my $options ($general, @$nested_options)
    {   $slide->resolveViewportOptions($options);

        foreach (@{$options->{viewports}})
        {   next if $_ eq 'NONE';

            if($_ eq 'OTHER')
            {   die "Slide $slide has more definitions for default viewports.\n"
                    if defined $other && $other != $general;
                $other = $options;
                next;
            }

            die "Viewport $_ used twice in slide $slide.\n"
                if PPresenter::Viewport->fromList(\@used_vps, $_);

            my $vp = PPresenter::Viewport->fromList(\@viewports, $_);
            die "Unknown viewport $_ for slide $slide.\n"
                unless $vp;

            push @used_vps, $vp;
            push @vp_options, $options;

        }
    }

    # find the unused viewports.
    foreach (@used_vps)
    {   for(my $i=0; $i<@viewports; $i++)
        {   if($viewports[$i] eq $_)
            {   splice @viewports, $i, 1;
                last;
            }
        }
    }

    # look where to display slide-notes
    my $notes = delete $general->{-notes};
    if(defined $notes)
    {   for(my $i=0; $i<@viewports; $i++)
        {   next unless $viewports[$i]->showSlideNotes;
            push @used_vps, $viewports[$i];
            push @vp_options, {-notes => $notes};
            splice @viewports, $i, 1;
        }
    }

    # fill-in the OTHER
    if(defined $other)
    {   foreach (@viewports)
        {   next if $_->showSlideNotes;
            push @used_vps, $_;
            push @vp_options, $other;
        }
    }

    # Allocate the views
    my %used_generals;

    foreach my $vp (@used_vps)
    {   my $options = shift @vp_options;

        # first find-out which style-elements are to be used.
        my %tmp_options = %$options;
        @tmp_options{keys %$general} = values %$general
            if $options != $general;  # include general in nested options.

        my $style_flags = PPresenter::Style::getStyleFlags($options);
        map {delete $options->{"-$_"}} keys %$style_flags;
        %tmp_options = ();

        # The view is created.
        my $view = PPresenter::SlideView->new($show,$slide,$style_flags,$vp);

        # Check if viewport-specific flags can have a place.
        my %collection;
        $view->collectOptions(\%collection);
        if($^W)
        {   foreach (sort keys %$options)
            {   next unless /^-/;
                next if exists $collection{$_};
                warn "Slide $slide, viewport $vp cannot show option $_.\n";
                delete $options->{$_};
            }
        }

        # now find-out which general options can be used in this view.
        foreach (keys %$general)
        {   next unless exists $collection{$_};
            $options->{$_} = $general->{$_} unless exists $options->{$_};
            $used_generals{$_}++;  #ok when a view would be able to use it.
        }
        $view->setOptions($options);
        push @{$slide->{views}}, $view;
    }

    if($^W)
    {   foreach (sort keys %$general)
        {   next unless /^-/;
            next if exists $used_generals{$_};
            warn "Slide $slide: no use for option $_.\n";
        }
    }
}

sub resolveViewportOptions($)
{   my ($slide, $options) = @_;

    my @viewports;
    foreach ( qw/-screen -screens -viewport -viewports/ )
    {   next unless exists $options->{$_};
        push @viewports, $slide->flatten(delete $options->{$_});
    }

    @viewports = 'OTHER' unless @viewports;
    $options->{viewports} = \@viewports;
    $slide;
}

sub prepare()
{   my $slide = shift;
    map {$_->prepare($slide)} @{$slide->{views}};
}

sub show()
{   my $slide = shift;
    map {$_->show($slide)} @{$slide->{views}};
}

sub nextPhase()
{   my $slide = shift;
    map {$_->nextPhase} @{$slide->{views}};
    $slide->{phase_delay} = 0;
}

sub startProgram($)
{   my ($slide,$show) = @_;
    map {$_->startProgram($slide)} @{$slide->{views}};
}

sub suspended($)
{   my ($slide, $interval) = @_;
    $slide->{phase_delay} += $interval;
}

sub getPhaseDelay() {$_[0]->{phase_delay}}

#
# Tags
#

sub addTags(@)
{   my $slide = shift;
    push @{$slide->{-tags}}, @_;
    $slide;
}

sub hasTag($)
{   my ($slide, $tag) = @_;
    grep {$tag eq $_} @{$slide->{-tags}};
}

sub getTags()          {@{$_[0]->{-tags}}}
sub getNumber()        {$_[0]->{number} }
sub getTitle()         {$_[0]->{-title} }
sub isActive()         {$_[0]->{-active}}
sub getButton()        {$_[0]->{button} }
sub getRequiredTime()  {$_[0]->{-reqtime}}
sub getViews()         {@{$_[0]->{views}}}

sub getView($)
{   my ($slide, $name) = @_;
    PPresenter::SlideView->fromList($_[0]->{views}, $name);
}

sub setActive($)
{   my ($slide, $state) = @_;

    # Only update when required: otherwise Tk will update the button.
    $slide->{-active} = $state
      if !defined $slide->{-active} || $slide->{-active}!=$state;

    $slide;
}

sub statusButtons($$$$)
{   my ($slide, $show, $parent, $colorscale, $command) = @_;

    my $time_max = $parent->Checkbutton
        ( -text        => $show->minSecs($slide->{-reqtime})
        , -variable    => \$slide->{-active}
        , -command     => sub {$show->slideSelectionChanged}
        , -justify     => 'right'
        , -indicatoron => 0
        , -selectcolor => 'white'
        );

    my $name_button   = $parent->Radiobutton
        ( -text        => "$slide"
        , -value       => $slide->{number}
        , -variable    => \$show->{current_slide_number}
        , -command     => $command
        , -indicatoron => 0
        , -selectcolor => 'white'
        , -justify     => 'left'
        , -anchor      => 'w'
        );

    my $time_spent = $parent->TimerLabel
        ( -value      => 0
        , -maxValue   => $slide->getRequiredTime
        , -colorScale => $colorscale
        );
    $slide->{time_spent} = $time_spent;

    return ($time_max, $name_button, $time_spent);
}

#
# Proceed
#

sub validProceed($)
{   my $slide = shift;
    local $_  = uc shift;
    s/^\s+//; s/\s+$//;

    unless( /^STOP$/ or /^NOW$/ or /^TIME$/ or /^PHASE\s*\d+$/ )
    {    warn "Slide $slide: -proceed should be STOP, NOW, TIME, or PHASE.\n";
         return 0;
    }
}

sub wantNextSlide()
{   my $slide   = shift;
    my $proceed = uc $slide->{-proceed};

    return 0 if $proceed eq 'STOP';
    return 1 if $proceed eq 'NOW';

    return $slide->{time_spent}->cget('-value') == $slide->{-reqtime}
        if $proceed eq 'TIME';

    my $phase = $proceed =~ /PHASE\s*(\d+)/i;
    return $slide->{program}->getPhase >= $phase;
}

#
# Export
#

sub exportViews($$@)
{
   my ($slide, $show, $viewport, $borders, $function) = splice @_, 0, 5;

    $show->showSlide($slide);
    $show->flushPhases;

    foreach (@{$slide->{views}})
    {   next unless $_->showsOnViewport($viewport);
        return $_->exportView($borders, $function, @_);
    }

    return undef;
}

#
# Display slide
#

sub tree()
{   my $slide = shift;
    my $ret;

    local $" = "', '";

    foreach (sort keys %$slide)
    {   $ret .= !defined $slide->{$_}
              ? sprintf("%-20s => <undef>\n", $_)
              : (ref $slide->{$_} =~ /[a-z]/
                 && $slide->{$_}->isa('PPresenter::StyleElem'))
              ? (sprintf("%-20s =>\n", $_).$slide->{$_}->tree("   "))
              : ref $slide->{$_} eq 'ARRAY'
              ? sprintf("%-20s => [ '@{$slide->{$_}}' ]\n", $_)
              : sprintf("%-20s => $slide->{$_}\n",$_);
    }

    $ret;
}

1;
