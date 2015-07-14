package OpenAir::Altitude;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;

extends 'OpenAir::Distance';

enum 'AltitudeType', ['STD', 'MSL', 'AGL'];

has 'type' => (
    is => 'rw',
    isa => 'AltitudeType',
    trigger => \&_typeSet,
    default => 'MSL'
    );

enum 'AltitudeFlag', ['UNLIM', 'SFC'];

has 'flag' => (
    is => 'rw',
    isa => 'Maybe[AltitudeFlag]',
    trigger => \&_flagSet,
    clearer => 'clearFlag',
    default => undef
    );

sub _valueSet {
    my $self = shift;
    my $new = shift;
    my $old = shift;
    
    return if defined $old && $new eq $old;

    if ($new <= 0 && $self->type eq 'AGL') {
	$self->flag ('SFC');
    } elsif ($new > 0 && defined $self->flag && $self->flag eq 'SFC') {
	$self->clearFlag ();
    } elsif ($self->flag eq 'UNLIM') {
	$self->clearFlag ();
    }
}

sub _typeSet {
    my $self = shift;
    my $new = shift;
    my $old = shift;

    return if defined $old && $new eq $old;

    if ($self->value <= 0 && $new eq 'AGL') {
	$self->flag ('SFC');
    } elsif ($self->value > 0 && defined $self->flag && $self->flag eq 'SFC') {
	$self->clearFlag ();
    }
}

sub _flagSet {
    my $self = shift;
    my $new = shift;
    my $old = shift;

    return if defined $old && $new eq $old;

    if ($new eq 'SFC') {
	$self->type ('AGL');
	$self->value (0);
    } elsif ($new eq 'UNLIM') { 
	$self->type ('MSL');
	$self->unit ('FT');
	$self->value (50000); 
    }
}

__PACKAGE__->meta->make_immutable;

