# $Id: PerForm.pm,v 1.5 2001/06/27 14:07:28 matt Exp $

package AxKit::XSP::PerForm;

$VERSION = "1.3_90";

use AxKit 1.4;
use Apache;
use Apache::AxKit::Language::XSP::TaglibHelper;
use AxKit::XSP::WebUtils;

$NS = 'http://axkit.org/NS/xsp/perform/v1';

@ISA = qw(Apache::AxKit::Language::XSP);

@EXPORT_TAGLIB = (
    'textfield($name;$default,$width,$maxlength)',
    'password($name;$default,$width,$maxlength)',
    'submit($name;$value,$image,$alt,$border,$align)',
    'cancel($name;$value,$image,$alt,$border,$align)',
    'checkbox($name;$value,$checked,$label)',
    'file_upload($name;$value,$accept)',
    'hidden($name;$value)',
    'textarea($name;$cols,$rows,$wrap)',
    'single_select($name):itemtag=option',
    'multi_select($name):itemtag=option',
);

use strict;

sub parse_char  { 
    Apache::AxKit::Language::XSP::TaglibHelper::parse_char(@_);
}

sub parse_start {
    my ($e, $tag, %attribs) = @_;
    
    if ($tag eq 'form') {
        $e->manage_text(0);
        
        my $form_el = {
            Name => "form",
            NamespaceURI => "",
            Attributes => [
                { Name => "name", Value => $attribs{name} },
                { Name => "action", Value => Apache->request->uri },
                { Name => "method", Value => "POST" },
            ],
        };
        
        $e->start_element($form_el);
        
        my $submitting = {
            Name => "hidden",
            NamespaceURI => "",
            Attributes => [
                { Name => "name", Value => "__submitting" },
                { Name => "value", Value => "1" },
            ],
        };
        $e->start_element($submitting);
        $e->end_element($submitting);
        
        return <<EOT
{        
use vars qw(\$_form_ctxt \@_submit_buttons \@_cancel_buttons);
local \$_form_ctxt = { Form => \$cgi->parms, Apache => \$r };
local \@_submit_buttons;
local \@_cancel_buttons;
start_form_$attribs{name}(\$_form_ctxt, \$cgi->param('__submitting'))
          if defined \&start_form_$attribs{name};
EOT
    }
    else {
        return Apache::AxKit::Language::XSP::TaglibHelper::parse_start(@_);
    }
}

sub end_element {
    my ($e, $element) = @_;
    
    if ($element->{Name} eq 'form') {
        my $form_el = {
            Name => "form",
            NamespaceURI => "",
            Attributes => [],
        };
        
        my $name;
        
        for my $attr (@{$element->{Attributes}}) {
            if ($attr->{Name} eq 'name') {
                $name = $attr->{Value};
            }
        }
        
        $e->end_element($form_el);
        return <<EOT;
end_form_${name}(\$_form_ctxt, \$cgi->param('__submitting'))
        if defined \&end_form_${name};

if (\$cgi->param('__submitting')) {
    foreach my \$cancel (\@_cancel_buttons) {
        if (\$cgi->param(\$cancel)) {
            no strict 'refs';
            my \$redirect;
            \$redirect = "cancel_\${cancel}"->(\$_form_ctxt)
                    if defined \&{"cancel_\${cancel}"};
            if (\$redirect) {
                AxKit::XSP::WebUtils::redirect(\$redirect);
            }
        }
    }
}

if (\$cgi->param('__submitting') && !\$_form_ctxt->{_Failed}) {
    foreach my \$submit (\@_submit_buttons) {
        if (\$cgi->param(\$submit)) {
            no strict 'refs';
            my \$redirect;
            \$redirect = "submit_\${submit}"->(\$_form_ctxt) 
                    if defined \&{"submit_\${submit}"};
            if (\$redirect) {
                AxKit::XSP::WebUtils::redirect(\$redirect);
            }
        }
    }
}

}
EOT
    }
    else {
        return Apache::AxKit::Language::XSP::TaglibHelper::parse_end($e, $element->{Name});
    }
}

sub textfield ($;$$$) {
    my ($name, $default, $width, $maxlength) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    
    my $error;
    
    # validate
    if ($params->{'__submitting'}) {
        if (defined &{"${package}::validate_${name}"}) {
            eval {
                "${package}::validate_${name}"->($ctxt, $params->{$name});
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/ at .*? line \d+\.$//;
        }
    }
    
    # load
    if (defined &{"${package}::load_${name}"}) {
        $params->{$name} = "${package}::load_${name}"->($ctxt, $default, $params->{$name});
    }
    elsif (!$params->{'__submitting'}) {
        $params->{$name} = $default;
    }
    
    return {
        textfield => { 
            width => $width,
            maxlength => $maxlength,
            name => $name,
            value => $params->{$name},
            ($error ? (error => $error) : ()),
            }
        };
}

sub submit ($;$$$$$) {
    my ($name, $value, $image, $alt, $border, $align) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    my $params = $ctxt->{Form};
    
    push @{"${package}::_submit_buttons"}, $name;
    
    # save
    if ($image) {
        return {
            image_button => {
                name => $name,
                value => $value,
                src => $image,
                alt => $alt,
                border => $border || 0,
                align => $align || "bottom",
            }
        };
    }
    else {
        return {
            submit_button => {
                name => $name,
                value => $value,
            }
        };
    }
}

sub cancel ($;$$$$$) {
    my ($name, $value, $image, $alt, $border, $align) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    my $params = $ctxt->{Form};
    
    push @{"${package}::_cancel_buttons"}, $name;
    
    # save
    if ($image) {
        return {
            image_button => {
                name => $name,
                value => $value,
                src => $image,
                alt => $alt,
                border => $border || 0,
                align => $align || "bottom",
            }
        };
    }
    else {
        return {
            submit_button => {
                name => $name,
                value => $value,
            }
        };
    }
}

sub button ($;$) {
    my ($name, $value) = @_;
    
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    my $params = $ctxt->{Form};
    
    # TODO: What do we want buttons to do?
}

sub checkbox ($;$$$) {
    my ($name, $value, $checked, $label) = @_;
    my ($package) = caller;
    
    if ($checked && $checked eq 'yes') {
        $checked = 1;
    }
    elsif ($checked && $checked eq 'no') {
        $checked = 0;
    }
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    
    my $error;
    
    # validate
    if ($params->{'__submitting'}) {
        if (defined &{"${package}::validate_${name}"}) {
            eval {
                "${package}::validate_${name}"->($ctxt, $params->{$name});
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/ at .*? line \d+\.$//;
        }
    }
    
    # load
    if (defined &{"${package}::load_${name}"}) {
        $checked = "${package}::load_${name}"->($ctxt, $params->{$name});
    }
    elsif ($params->{'__submitting'}) {
        $checked = $params->{$name};
    }
    
    return {
        checkbox => {
            name => $name,
            value => $value,
            ( $checked ? (checked => "checked") : () ),
            label => $label,
            ( $error ? (error => $error) : () ),
        }
    };
}

sub file_upload ($;$$) {
    my ($name, $value, $accept) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    
    my $error;
    
    # validate
    if ($params->{'__submitting'}) {
        if (defined &{"${package}::validate_${name}"}) {
            my $upload = Apache::Request->instance(Apache->request)->upload($name);
            
            my $filename;
            if ($upload) {
                $filename = $upload->filename;
                $filename =~ s/.*[\\\/]//; # strip to just a filename
                $filename =~ s/[^\w\.-]//g; # strip non-word chars
            }
    
            eval {
               "${package}::validate_${name}"->($ctxt, 
                       ($upload ? 
                            (   $filename,
                                $upload->fh, 
                                $upload->size, 
                                $upload->type, 
                                $upload->info
                            ) : 
                            ()
                       )
                   );
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/ at .*? line \d+\.$//;
        }
    }
    
    # load
    if (defined &{"${package}::load_${name}"}) {
        $params->{$name} = "${package}::load_${name}"->($ctxt, $value, $params->{$name});
    }
    elsif (!$params->{'__submitting'}) {
        $params->{$name} = $value;
    }
    
    return {
        file_upload => {
            name => $name,
            value => $params->{$name},
            accept => $accept,
            ($error ? (error => $error) : ()),
        }
    };
}

sub hidden ($;$) {
    my ($name, $value) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    
    if (!defined($value) && defined &{"${package}::load_${name}"}) {
        # load value if not defined
        $value = "${package}::load_${name}"->($ctxt);
    }
    
    if ($params->{'__submitting'} && ($value ne $params->{$name})) {
        die "Someone tried to change your hidden form value!";
    }
    
    return {
        hidden => {
            name => $name,
            value => $value,
        }
    };
}

sub multi_select ($) {
    my ($name) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    
    my $error;
    
    # validate
    if ($params->{'__submitting'}) {
        if (defined &{"${package}::validate_${name}"}) {
            eval {
                "${package}::validate_${name}"->($ctxt, $params->{$name});
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/ at .*? line \d+\.$//;
        }
    }
    
    # load
    my ($selected, @options);
    if (defined &{"${package}::load_${name}"}) {
        ($selected, @options) = "${package}::load_${name}"->($ctxt, $params->get($name));
    }
    
    my %selected = map { $_ => 1 } @$selected;
    
    my (@keys, @vals);
    while (@options) {
        my ($val, $key) = splice(@options, 0, 2);
        push @keys, $key;
        push @vals, $val;
    }
    
    return {
        multi_select => {
            name => $name,
            ($error ? ( error => $error ) : ()),
            options => [
                map {
                  { 
                    ( ( $selected{$_} ) ? (selected => "selected") : () ),
                    value => $_,
                    text => shift(@vals),
                  }
                } @keys,
            ],
        }
    };
}

sub password ($;$$$) {
    my ($name, $default, $width, $maxlength) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    
    my $error;
    
    # validate
    if ($params->{'__submitting'}) {
        if (defined &{"${package}::validate_${name}"}) {
            eval {
                "${package}::validate_${name}"->($ctxt, $params->{$name});
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/ at .*? line \d+\.$//;
        }
    }
    
    # load
    if (defined &{"${package}::load_${name}"}) {
        $params->{$name} = "${package}::load_${name}"->($ctxt, $default, $params->{$name});
    }
    elsif (!$params->{'__submitting'}) {
        $params->{$name} = $default;
    }
    
    return {
        password => { 
            width => $width,
            maxlength => $maxlength,
            name => $name,
            value => $params->{$name},
            ($error ? (error => $error) : ()),
            }
        };
}

sub radio {
}

sub reset ($;$) {
    my ($name, $value) = @_;
    
    return {
        reset => {
            name => $name,
            ( $value ? (value => $value) : () ),
        }
    };
}

sub single_select ($) {
    my ($name) = @_;
    my ($package) = caller;
    
    no strict 'refs';
    
    my $ctxt = ${"${package}::_form_ctxt"};
    
    my $params = $ctxt->{Form};
    
    my $error;
    
    # validate
    if ($params->{'__submitting'}) {
        if (defined &{"${package}::validate_${name}"}) {
            eval {
                "${package}::validate_${name}"->($ctxt, $params->{$name});
            };
            $error = $@;
            $ctxt->{_Failed}++ if $error;
            $error =~ s/ at .*? line \d+\.$//;
        }
    }
    
    # load
    my ($selected, @options);
    if (defined &{"${package}::load_${name}"}) {
        ($selected, @options) = "${package}::load_${name}"->($ctxt, $params->{$name});
    }
    
    my (@keys, @vals);
    while (@options) {
        my ($val, $key) = splice(@options, 0, 2);
        push @keys, $key;
        push @vals, $val;
    }
    
    return {
        single_select => {
            name => $name,
            ($error ? ( error => $error ) : ()),
            options => [
                map {
                  { 
                    ( ($selected eq $_) ? (selected => "selected") : () ),
                    value => $_,
                    text => shift(@vals),
                  }
                } @keys,
            ],
        }
    };
}

sub textarea {
}

1;
__END__

=head1 NAME

AxKit::XSP::PerForm - Perl extension for blah blah blah

=head1 SYNOPSIS

  use AxKit::XSP::PerForm;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for AxKit::XSP::PerForm was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
