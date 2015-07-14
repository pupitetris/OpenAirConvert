package OpenAir::Distance;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;

my $UNITCONV = {
    FT => {
	M => 0.3048,
	NM => 0.000164579,
	KM => 0.0003048
    },
    M => {
	FT => 3.28048,
	NM => 0.000539957,
	KM => 0.0001
    },
    NM => {
	FT => 6076.12,
	M => 1852,
	KM => 1.852
    },
    KM => {
	FT => 3280.84,
	M => 1000,
	NM => 0.539957
    }
};

has 'value' => (
    is => 'rw',
    isa => 'Num',
    trigger => \&_valueSet,
    default => 0
    );

enum 'DistanceUnit', ['FT', 'M', 'NM', 'KM'];

has 'unit' => (
    is => 'rw',
    isa => 'DistanceUnit',
    trigger => \&_unitSet,
    default => 'FT'
    );

sub _valueSet {
}

sub _unitSet {
    my $self = shift;
    my $new = shift;
    my $old = shift;

    return if $self->value == 0;
    return if !defined $old;
    return if $new eq $old;
    
    my $mult = $UNITCONV->{$new}{$old};
    $self->value ($self->value * $mult);
}

__PACKAGE__->meta->make_immutable;

