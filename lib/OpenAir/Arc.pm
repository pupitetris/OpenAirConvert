package OpenAir::Arc;

use namespace::autoclean;
use Moose;

use OpenAir::Point;

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
    isa => 'Maybe[OpenAir::Point]',
    default => undef
    );

has 'pointB' => (
    is => 'rw',
    isa => 'Maybe[OpenAir::Point]',
    default => undef
    );

__PACKAGE__->meta->make_immutable;
