package OpenAir::Element::Arc;

use namespace::autoclean;
use Moose;

use OpenAir::Element::Point;

extends 'OpenAir::Element';

has 'radius' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::PositiveNum]',
    default => undef
    );

has 'angleStart' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::Angle]',
    default => undef
    );

has 'angleEnd' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::Angle]',
    default => undef
    );

has 'pointA' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::Element::Point]',
    default => undef
    );

has 'pointB' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::Element::Point]',
    default => undef
    );

__PACKAGE__->meta->make_immutable;
